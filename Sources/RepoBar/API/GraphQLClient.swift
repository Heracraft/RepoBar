import Foundation

/// Minimal GraphQL helper (no codegen) to enrich repo data. Uses the same OAuth token as REST.
actor GraphQLClient {
    private var endpoint: URL = .init(string: "https://api.github.com/graphql")!
    private var tokenProvider: (@Sendable () async throws -> String)?
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func setEndpoint(apiHost: URL) {
        // For GitHub.com apiHost is https://api.github.com
        // For GHE apiHost is https://host/api/v3 -> GraphQL lives at /api/graphql
        var components = URLComponents(url: apiHost, resolvingAgainstBaseURL: false)
        if apiHost.path.contains("/api/v3") {
            components?.path = "/api/graphql"
        } else {
            components?.path = "/graphql"
        }
        self.endpoint = components?.url ?? self.endpoint
    }

    func setTokenProvider(_ provider: @Sendable @escaping () async throws -> String) {
        self.tokenProvider = provider
    }

    func fetchRepoSnapshot(owner: String, name: String) async throws -> GraphRepoSnapshot {
        let token = try await tokenProvider?() ?? { throw URLError(.userAuthenticationRequired) }()

        let body = GraphQLRequest(
            query: """
            query RepoSnapshot($owner: String!, $name: String!) {
              repository(owner: $owner, name: $name) {
                name
                releases(last: 1, orderBy: {field: CREATED_AT, direction: DESC}) {
                  nodes { name tagName publishedAt url }
                }
                issues(states: OPEN) { totalCount }
                pullRequests(states: OPEN) { totalCount }
                timelineItems(last: 1, itemTypes: [ISSUE_COMMENT, PULL_REQUEST_COMMIT, PULL_REQUEST_REVIEW]) {
                  nodes {
                    ... on IssueComment { bodyText updatedAt url author { login } }
                    ... on PullRequestReview { bodyText updatedAt url author { login } }
                  }
                }
              }
            }
            """,
            variables: ["owner": owner, "name": name]
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard http.statusCode == 200 else { throw URLError(.badServerResponse) }

        let decoded = try decoder.decode(GraphQLResponse<RepoSnapshotData>.self, from: data)
        guard let repo = decoded.data.repository else {
            throw URLError(.cannotParseResponse)
        }

        let release: Release? = repo.releases.nodes?.first.flatMap {
            Release(name: $0.name ?? $0.tagName, tag: $0.tagName, publishedAt: $0.publishedAt, url: $0.url)
        }

        let activity: ActivityEvent? = repo.timelineItems.nodes?.first.flatMap { node in
            if let text = node.bodyText, let date = node.updatedAt, let url = node.url {
                let actor = node.author?.login ?? "someone"
                return ActivityEvent(
                    title: text.prefix(80) + (text.count > 80 ? "…" : ""),
                    actor: actor,
                    date: date,
                    url: url
                )
            }
            return nil
        }

        return GraphRepoSnapshot(
            release: release,
            openIssues: repo.issues.totalCount,
            openPulls: repo.pullRequests.totalCount,
            activity: activity
        )
    }
}

struct GraphRepoSnapshot {
    let release: Release?
    let openIssues: Int?
    let openPulls: Int?
    let activity: ActivityEvent?
}

// MARK: - Wire models

private struct GraphQLRequest: Encodable {
    let query: String
    let variables: [String: String]
}

private struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T
}

private struct RepoSnapshotData: Decodable {
    let repository: RepositoryNode?
}

private struct RepositoryNode: Decodable {
    let name: String
    let releases: ReleaseConnection
    let issues: CountContainer
    let pullRequests: CountContainer
    let timelineItems: TimelineConnection
}

private struct ReleaseConnection: Decodable {
    let nodes: [ReleaseNode]?
}

private struct ReleaseNode: Decodable {
    let name: String?
    let tagName: String
    let publishedAt: Date
    let url: URL
}

private struct CountContainer: Decodable {
    let totalCount: Int
}

private struct TimelineConnection: Decodable {
    let nodes: [TimelineNode]?
}

private struct TimelineNode: Decodable {
    let bodyText: String?
    let updatedAt: Date?
    let url: URL?
    let author: AuthorNode?
}

private struct AuthorNode: Decodable {
    let login: String
}
