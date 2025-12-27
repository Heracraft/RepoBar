import Foundation

public enum RepositoryFilter {
    public static func apply(
        _ repos: [Repository],
        includeForks: Bool,
        includeArchived: Bool,
        pinned: Set<String> = []
    ) -> [Repository] {
        guard includeForks == false || includeArchived == false else { return repos }

        if pinned.isEmpty {
            return repos.filter { repo in
                (includeForks || repo.isFork == false) && (includeArchived || repo.isArchived == false)
            }
        }

        return repos.filter { repo in
            let isPinned = pinned.contains(repo.fullName)
            let forkOK = includeForks || repo.isFork == false || isPinned
            let archivedOK = includeArchived || repo.isArchived == false || isPinned
            return forkOK && archivedOK
        }
    }
}
