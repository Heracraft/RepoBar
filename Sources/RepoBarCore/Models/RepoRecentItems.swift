import Foundation

public struct RepoIssueLabel: Sendable, Hashable {
    public let name: String
    public let colorHex: String

    public init(name: String, colorHex: String) {
        self.name = name
        self.colorHex = colorHex
    }
}

public struct RepoIssueSummary: Sendable, Hashable {
    public let number: Int
    public let title: String
    public let url: URL
    public let updatedAt: Date
    public let authorLogin: String?
    public let authorAvatarURL: URL?
    public let commentCount: Int
    public let labels: [RepoIssueLabel]

    public init(
        number: Int,
        title: String,
        url: URL,
        updatedAt: Date,
        authorLogin: String?,
        authorAvatarURL: URL?,
        commentCount: Int,
        labels: [RepoIssueLabel]
    ) {
        self.number = number
        self.title = title
        self.url = url
        self.updatedAt = updatedAt
        self.authorLogin = authorLogin
        self.authorAvatarURL = authorAvatarURL
        self.commentCount = commentCount
        self.labels = labels
    }
}

public struct RepoPullRequestSummary: Sendable, Hashable {
    public let number: Int
    public let title: String
    public let url: URL
    public let updatedAt: Date
    public let authorLogin: String?
    public let authorAvatarURL: URL?
    public let isDraft: Bool
    public let commentCount: Int
    public let reviewCommentCount: Int
    public let labels: [RepoIssueLabel]
    public let headRefName: String?
    public let baseRefName: String?

    public init(
        number: Int,
        title: String,
        url: URL,
        updatedAt: Date,
        authorLogin: String?,
        authorAvatarURL: URL?,
        isDraft: Bool,
        commentCount: Int,
        reviewCommentCount: Int,
        labels: [RepoIssueLabel],
        headRefName: String?,
        baseRefName: String?
    ) {
        self.number = number
        self.title = title
        self.url = url
        self.updatedAt = updatedAt
        self.authorLogin = authorLogin
        self.authorAvatarURL = authorAvatarURL
        self.isDraft = isDraft
        self.commentCount = commentCount
        self.reviewCommentCount = reviewCommentCount
        self.labels = labels
        self.headRefName = headRefName
        self.baseRefName = baseRefName
    }
}
