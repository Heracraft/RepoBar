import Foundation

enum RepoRecentMenuKind: Hashable {
    case issues
    case pullRequests
    case releases
}

struct RepoRecentMenuContext: Hashable {
    let fullName: String
    let kind: RepoRecentMenuKind
}
