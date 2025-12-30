import Foundation

enum RepoRecentMenuKind: Hashable {
    case issues
    case pullRequests
    case releases
    case ciRuns
    case discussions
    case tags
    case branches
    case contributors
}

struct RepoRecentMenuContext: Hashable {
    let fullName: String
    let kind: RepoRecentMenuKind
}
