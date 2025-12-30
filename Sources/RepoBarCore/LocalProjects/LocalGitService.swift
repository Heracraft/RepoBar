import Foundation

public struct LocalGitBranch: Equatable, Sendable {
    public let name: String
    public let isCurrent: Bool
}

public struct LocalGitWorktree: Equatable, Sendable {
    public let path: URL
    public let branch: String?
    public let isCurrent: Bool
}

public struct LocalGitSyncResult: Equatable, Sendable {
    public let didFetch: Bool
    public let didPull: Bool
    public let didPush: Bool
}

public enum LocalGitError: LocalizedError {
    case dirtyWorkingTree
    case missingUpstream
    case detachedHead

    public var errorDescription: String? {
        switch self {
        case .dirtyWorkingTree:
            "Working tree has uncommitted changes."
        case .missingUpstream:
            "No upstream branch configured."
        case .detachedHead:
            "Repository is in detached HEAD state."
        }
    }
}

public struct LocalGitService {
    public init() {}

    public func smartSync(at repoURL: URL) throws -> LocalGitSyncResult {
        let git = LocalGitRunner()
        guard isClean(at: repoURL, git: git) else { throw LocalGitError.dirtyWorkingTree }
        guard currentBranch(at: repoURL, git: git) != "detached" else { throw LocalGitError.detachedHead }
        guard upstreamBranch(at: repoURL, git: git) != nil else { throw LocalGitError.missingUpstream }

        let didFetch = fetchPrune(at: repoURL, git: git)
        var (ahead, behind) = aheadBehind(at: repoURL, git: git)
        var didPull = false
        if (behind ?? 0) > 0 {
            _ = try git.run(["pull", "--rebase", "--autostash"], in: repoURL)
            didPull = true
            (ahead, behind) = aheadBehind(at: repoURL, git: git)
        }

        var didPush = false
        if (ahead ?? 0) > 0 {
            _ = try git.run(["push"], in: repoURL)
            didPush = true
        }

        return LocalGitSyncResult(didFetch: didFetch, didPull: didPull, didPush: didPush)
    }

    public func rebaseOntoUpstream(at repoURL: URL) throws {
        let git = LocalGitRunner()
        guard isClean(at: repoURL, git: git) else { throw LocalGitError.dirtyWorkingTree }
        guard upstreamBranch(at: repoURL, git: git) != nil else { throw LocalGitError.missingUpstream }
        _ = fetchPrune(at: repoURL, git: git)
        _ = try git.run(["rebase", "--autostash", "@{u}"], in: repoURL)
    }

    public func hardResetToUpstream(at repoURL: URL) throws {
        let git = LocalGitRunner()
        guard upstreamBranch(at: repoURL, git: git) != nil else { throw LocalGitError.missingUpstream }
        _ = fetchPrune(at: repoURL, git: git)
        _ = try git.run(["reset", "--hard", "@{u}"], in: repoURL)
    }

    public func branches(at repoURL: URL) throws -> [LocalGitBranch] {
        let git = LocalGitRunner()
        let current = currentBranch(at: repoURL, git: git)
        let raw = try git.run(["branch", "--format=%(refname:short)"], in: repoURL)
        let names = raw.split(whereSeparator: \.isNewline).map { String($0) }
        return names.map { name in
            LocalGitBranch(name: name, isCurrent: name == current)
        }
    }

    public func worktrees(at repoURL: URL) throws -> [LocalGitWorktree] {
        let git = LocalGitRunner()
        let raw = try git.run(["worktree", "list", "--porcelain"], in: repoURL)
        let lines = raw.split(whereSeparator: \.isNewline).map(String.init)
        var entries: [LocalGitWorktree] = []
        var currentPath: URL?
        var currentBranch: String?
        var currentIsDetached = false

        func commitEntry() {
            guard let path = currentPath else { return }
            let branch = currentIsDetached ? nil : currentBranch
            let isCurrent = path.standardizedFileURL == repoURL.standardizedFileURL
            entries.append(LocalGitWorktree(path: path, branch: branch, isCurrent: isCurrent))
            currentPath = nil
            currentBranch = nil
            currentIsDetached = false
        }

        for line in lines {
            if line.hasPrefix("worktree ") {
                commitEntry()
                let pathValue = line.replacingOccurrences(of: "worktree ", with: "")
                currentPath = URL(fileURLWithPath: pathValue, isDirectory: true)
                continue
            }
            if line.hasPrefix("branch ") {
                let branchValue = line.replacingOccurrences(of: "branch ", with: "")
                currentBranch = branchValue.replacingOccurrences(of: "refs/heads/", with: "")
                continue
            }
            if line == "detached" {
                currentIsDetached = true
            }
        }
        commitEntry()
        return entries
    }

    public func switchBranch(at repoURL: URL, branch: String) throws {
        let git = LocalGitRunner()
        _ = try git.run(["switch", branch], in: repoURL)
    }

    public func createBranch(at repoURL: URL, name: String) throws {
        let git = LocalGitRunner()
        _ = try git.run(["switch", "-c", name], in: repoURL)
    }

    public func createWorktree(at repoURL: URL, path: URL, branch: String) throws {
        let git = LocalGitRunner()
        _ = try git.run(["worktree", "add", path.path, "-b", branch], in: repoURL)
    }
}

private struct LocalGitRunner: Sendable {
    func run(_ arguments: [String], in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = GitExecutableLocator.shared.url
        process.arguments = arguments
        process.currentDirectoryURL = directory

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        if process.terminationStatus != 0 {
            let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw LocalGitRunnerError.commandFailed(output: output, error: error)
        }
        return output
    }
}

private enum LocalGitRunnerError: LocalizedError {
    case commandFailed(output: String, error: String)

    var errorDescription: String? {
        switch self {
        case let .commandFailed(output, error):
            let message = error.trimmingCharacters(in: .whitespacesAndNewlines)
            if message.isEmpty == false { return message }
            let fallback = output.trimmingCharacters(in: .whitespacesAndNewlines)
            return fallback.isEmpty ? "Git command failed." : fallback
        }
    }
}

private func fetchPrune(at repoURL: URL, git: LocalGitRunner) -> Bool {
    (try? git.run(["fetch", "--prune"], in: repoURL)) != nil
}

private func isClean(at repoURL: URL, git: LocalGitRunner) -> Bool {
    let output = try? git.run(["status", "--porcelain"], in: repoURL)
    return output?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false
}

private func currentBranch(at repoURL: URL, git: LocalGitRunner) -> String {
    guard let raw = try? git.run(["rev-parse", "--abbrev-ref", "HEAD"], in: repoURL) else {
        return "unknown"
    }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed == "HEAD" ? "detached" : trimmed
}

private func upstreamBranch(at repoURL: URL, git: LocalGitRunner) -> String? {
    guard let raw = try? git.run(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"], in: repoURL) else {
        return nil
    }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}

private func aheadBehind(at repoURL: URL, git: LocalGitRunner) -> (ahead: Int?, behind: Int?) {
    guard let output = try? git.run(["rev-list", "--left-right", "--count", "@{u}...HEAD"], in: repoURL) else {
        return (nil, nil)
    }
    let parts = output.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
    guard parts.count >= 2,
          let behind = Int(parts[0]),
          let ahead = Int(parts[1])
    else { return (nil, nil) }
    return (ahead, behind)
}
