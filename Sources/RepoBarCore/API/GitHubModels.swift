import Foundation

struct SearchResponse: Decodable {
    let items: [RepoItem]
}

struct RepoItem: Decodable {
    let id: Int
    let name: String
    let fullName: String
    let fork: Bool
    let archived: Bool
    let openIssuesCount: Int
    let stargazersCount: Int
    let forksCount: Int
    let pushedAt: Date?
    let owner: Owner

    struct Owner: Decodable { let login: String }

    enum CodingKeys: String, CodingKey {
        case id, name
        case fullName = "full_name"
        case fork
        case archived
        case openIssuesCount = "open_issues_count"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case pushedAt = "pushed_at"
        case owner
    }
}

struct CurrentUser: Decodable {
    let login: String
    let htmlUrl: String

    enum CodingKeys: String, CodingKey {
        case login
        case htmlUrl = "html_url"
    }
}

struct OrgMembership: Decodable {
    let organization: Organization
    let role: String
    let state: String?

    struct Organization: Decodable {
        let login: String
    }
}

struct SearchIssuesResponse: Decodable {
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
    }
}

struct ReleaseResponse: Decodable {
    let name: String?
    let tagName: String
    let publishedAt: Date?
    let createdAt: Date?
    let draft: Bool?
    let prerelease: Bool?
    let htmlUrl: URL

    enum CodingKeys: String, CodingKey {
        case name
        case tagName = "tag_name"
        case publishedAt = "published_at"
        case createdAt = "created_at"
        case draft
        case prerelease
        case htmlUrl = "html_url"
    }
}

struct ActionsRunsResponse: Decodable {
    let totalCount: Int?
    let workflowRuns: [WorkflowRun]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case workflowRuns = "workflow_runs"
    }

    struct WorkflowRun: Decodable {
        let status: String?
        let conclusion: String?
    }
}

struct CommentResponse: Decodable {
    let body: String
    let user: CommentUser
    let htmlUrl: URL
    let createdAt: Date

    var bodyPreview: String {
        let trimmed = self.body.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = String(trimmed.prefix(80))
        return prefix + (trimmed.count > 80 ? "…" : "")
    }

    enum CodingKeys: String, CodingKey {
        case body
        case user
        case htmlUrl = "html_url"
        case createdAt = "created_at"
    }

    struct CommentUser: Decodable {
        let login: String
    }
}

struct TrafficResponse: Decodable {
    let uniques: Int
}

struct CommitActivityWeek: Decodable {
    let total: Int
    let weekStart: Int
    let days: [Int]

    enum CodingKeys: String, CodingKey {
        case total
        case weekStart = "week"
        case days
    }
}

struct PullRequestListItem: Decodable {
    let id: Int
}

struct RepoEvent: Decodable {
    let type: String
    let actor: EventActor
    let payload: EventPayload
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case type, actor, payload
        case createdAt = "created_at"
    }
}

struct EventActor: Decodable {
    let login: String
}

struct EventPayload: Decodable {
    let action: String?
    let comment: EventComment?
    let issue: EventIssue?
    let pullRequest: EventPullRequest?
    let release: EventRelease?
    let forkee: EventForkee?
    let ref: String?
    let head: String?
    let commits: [EventCommit]?

    enum CodingKeys: String, CodingKey {
        case action, comment, issue, release, forkee, ref, head, commits
        case pullRequest = "pull_request"
    }

    init(
        action: String?,
        comment: EventComment?,
        issue: EventIssue?,
        pullRequest: EventPullRequest?,
        release: EventRelease? = nil,
        forkee: EventForkee? = nil,
        ref: String? = nil,
        head: String? = nil,
        commits: [EventCommit]? = nil
    ) {
        self.action = action
        self.comment = comment
        self.issue = issue
        self.pullRequest = pullRequest
        self.release = release
        self.forkee = forkee
        self.ref = ref
        self.head = head
        self.commits = commits
    }
}

struct EventComment: Decodable {
    let body: String?
    let htmlUrl: URL?

    enum CodingKeys: String, CodingKey {
        case body
        case htmlUrl = "html_url"
    }

    var bodyPreview: String {
        let trimmed = (body ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = String(trimmed.prefix(80))
        return prefix + (trimmed.count > 80 ? "…" : "")
    }
}

struct EventIssue: Decodable {
    let title: String?
    let htmlUrl: URL?

    enum CodingKeys: String, CodingKey {
        case title
        case htmlUrl = "html_url"
    }
}

struct EventPullRequest: Decodable {
    let title: String?
    let htmlUrl: URL?

    enum CodingKeys: String, CodingKey {
        case title
        case htmlUrl = "html_url"
    }
}

struct EventRelease: Decodable {
    let htmlUrl: URL?

    enum CodingKeys: String, CodingKey {
        case htmlUrl = "html_url"
    }
}

struct EventForkee: Decodable {
    let htmlUrl: URL?

    enum CodingKeys: String, CodingKey {
        case htmlUrl = "html_url"
    }
}

struct EventCommit: Decodable {
    let sha: String
}

extension RepoEvent {
    var displayTitle: String {
        let base = Self.displayName(for: self.type)
        guard let action = self.payload.action, action.isEmpty == false else { return base }
        let actionLabel = action.replacingOccurrences(of: "_", with: " ")
        return "\(base) \(actionLabel)"
    }

    var hasRichPayload: Bool {
        self.payload.comment != nil
            || self.payload.issue != nil
            || self.payload.pullRequest != nil
            || self.payload.release != nil
            || self.payload.forkee != nil
            || self.payload.head != nil
            || (self.payload.commits?.isEmpty == false)
    }

    func activityEvent(owner: String, name: String) -> ActivityEvent {
        let preview = self.payload.comment?.bodyPreview
            ?? self.payload.issue?.title
            ?? self.payload.pullRequest?.title
            ?? self.displayTitle
        let repoURL = URL(string: "https://github.com/\(owner)/\(name)")!
        let starURL = repoURL.appending(path: "stargazers")
        let fallbackURL = (self.type == "WatchEvent") ? starURL : repoURL
        let commitSHA = self.payload.head ?? self.payload.commits?.first?.sha
        let commitURL = commitSHA.map { repoURL.appending(path: "commit").appending(path: $0) }
        let url = self.payload.comment?.htmlUrl
            ?? self.payload.issue?.htmlUrl
            ?? self.payload.pullRequest?.htmlUrl
            ?? self.payload.release?.htmlUrl
            ?? self.payload.forkee?.htmlUrl
            ?? commitURL
            ?? fallbackURL
        let trimmed = preview.trimmingCharacters(in: .whitespacesAndNewlines)
        return ActivityEvent(
            title: trimmed.isEmpty ? self.displayTitle : trimmed,
            actor: self.actor.login,
            date: self.createdAt,
            url: url,
            eventType: self.type
        )
    }

    static func displayName(for type: String) -> String {
        return switch type {
        case "PullRequestEvent": "Pull Request"
        case "PullRequestReviewEvent": "Pull Request Review"
        case "PullRequestReviewCommentEvent": "Pull Request Review Comment"
        case "PullRequestReviewThreadEvent": "Pull Request Review Thread"
        case "IssueCommentEvent": "Issue Comment"
        case "IssuesEvent": "Issue"
        case "PushEvent": "Push"
        case "ReleaseEvent": "Release"
        case "WatchEvent": "Star"
        case "ForkEvent": "Fork"
        case "CreateEvent": "Create"
        case "DeleteEvent": "Delete"
        case "MemberEvent": "Member"
        case "PublicEvent": "Public"
        case "GollumEvent": "Wiki"
        case "CommitCommentEvent": "Commit Comment"
        case "DiscussionEvent": "Discussion"
        case "SponsorshipEvent": "Sponsorship"
        default: Self.prettyName(for: type)
        }
    }

    private static func prettyName(for raw: String) -> String {
        let trimmed = raw.hasSuffix("Event") ? String(raw.dropLast(5)) : raw
        var result = ""
        for scalar in trimmed.unicodeScalars {
            let char = Character(scalar)
            if char.isUppercase, result.isEmpty == false, result.last != " " {
                result.append(" ")
            }
            result.append(char)
        }
        return result
    }
}
