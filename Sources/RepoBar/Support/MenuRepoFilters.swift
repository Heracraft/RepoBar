enum MenuRepoScope: String, CaseIterable, Hashable {
    case all
    case pinned

    var label: String {
        switch self {
        case .all: "All"
        case .pinned: "Pinned"
        }
    }
}

enum MenuRepoFilter: String, CaseIterable, Hashable {
    case all
    case work
    case issues
    case prs

    var label: String {
        switch self {
        case .all: "All"
        case .work: "Work"
        case .issues: "Issues"
        case .prs: "PRs"
        }
    }

    var onlyWith: RepositoryOnlyWith {
        switch self {
        case .all:
            return .none
        case .work:
            return RepositoryOnlyWith(requireIssues: true, requirePRs: true)
        case .issues:
            return RepositoryOnlyWith(requireIssues: true)
        case .prs:
            return RepositoryOnlyWith(requirePRs: true)
        }
    }
}
