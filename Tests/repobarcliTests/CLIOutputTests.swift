import Foundation
@testable import repobarcli
import RepoBarCore
import Testing

struct CLIOutputTests {
    @Test
    func repoLabelUsesNameWhenURLDisabled() {
        let url = URL(string: "https://github.com/steipete/RepoBar")!
        let label = formatRepoLabel(
            repoName: "steipete/RepoBar",
            repoURL: url,
            includeURL: false,
            linkEnabled: false
        )
        #expect(label == "steipete/RepoBar")
    }

    @Test
    func repoLabelUsesURLWhenEnabled() {
        let url = URL(string: "https://github.com/steipete/RepoBar")!
        let label = formatRepoLabel(
            repoName: "steipete/RepoBar",
            repoURL: url,
            includeURL: true,
            linkEnabled: false
        )
        #expect(label == url.absoluteString)
    }

    @Test
    func eventLabelUsesTextWithoutURL() {
        let label = formatEventLabel(
            text: "push",
            url: nil,
            includeURL: true,
            linkEnabled: false
        )
        #expect(label == "push")
    }

    @Test
    func eventLabelUsesURLWhenEnabled() {
        let url = URL(string: "https://github.com/steipete/RepoBar/pull/1")!
        let label = formatEventLabel(
            text: "PullRequestEvent",
            url: url,
            includeURL: true,
            linkEnabled: false
        )
        #expect(label == url.absoluteString)
    }

    @Test
    func releaseDateFormattingIsStable() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2025, month: 12, day: 26, hour: 23, minute: 59))!
        #expect(formatDateYYYYMMDD(date) == "2025-12-26")
    }

    @Test
    func renderTableIncludesReleaseColumnsWhenEnabled() throws {
        let baseHost = URL(string: "https://github.com")!
        let releaseDate = Date(timeIntervalSinceReferenceDate: 12345)
        let repo = Repository(
            id: "1",
            name: "RepoBar",
            owner: "steipete",
            sortOrder: nil,
            error: nil,
            rateLimitedUntil: nil,
            ciStatus: .unknown,
            ciRunCount: nil,
            openIssues: 1,
            openPulls: 2,
            stars: 3,
            pushedAt: nil,
            latestRelease: Release(name: "v1.0.0", tag: "v1.0.0", publishedAt: releaseDate, url: baseHost),
            latestActivity: nil,
            traffic: nil,
            heatmap: []
        )
        let row = RepoRow(repo: repo, activityDate: nil, activityLabel: "-", activityLine: "push")

        let withRelease = tableLines([row], useColor: false, includeURL: false, includeRelease: true, includeEvent: false, baseHost: baseHost)
            .joined(separator: "\n")
        #expect(withRelease.contains("REL"))
        #expect(withRelease.contains("RELEASED"))
        #expect(withRelease.contains("v1.0.0"))
        #expect(withRelease.contains(formatDateYYYYMMDD(releaseDate)))

        let withoutRelease = tableLines([row], useColor: false, includeURL: false, includeRelease: false, includeEvent: false, baseHost: baseHost)
            .joined(separator: "\n")
        #expect(withoutRelease.contains("REL") == false)
        #expect(withoutRelease.contains("RELEASED") == false)
        #expect(withoutRelease.contains("v1.0.0") == false)
    }

    @Test
    func renderJSONIncludesLatestRelease() throws {
        let baseHost = URL(string: "https://github.com")!
        let releaseDate = Date(timeIntervalSinceReferenceDate: 777)
        let repo = Repository(
            id: "1",
            name: "RepoBar",
            owner: "steipete",
            sortOrder: nil,
            error: nil,
            rateLimitedUntil: nil,
            ciStatus: .unknown,
            ciRunCount: nil,
            openIssues: 0,
            openPulls: 0,
            stars: 0,
            pushedAt: nil,
            latestRelease: Release(name: "v0.1.0", tag: "v0.1.0", publishedAt: releaseDate, url: baseHost),
            latestActivity: nil,
            traffic: nil,
            heatmap: []
        )
        let row = RepoRow(repo: repo, activityDate: nil, activityLabel: "-", activityLine: "push")

        let data = try renderJSONData([row], baseHost: baseHost)
        let decoded = try JSONDecoder().decode([RepoOutput].self, from: data)

        #expect(decoded.count == 1)
        #expect(decoded[0].latestRelease?.tag == "v0.1.0")
        #expect(decoded[0].latestRelease?.publishedAt == releaseDate)
    }

    @Test
    func tableHidesEventColumnByDefault() throws {
        let baseHost = URL(string: "https://github.com")!
        let repo = Repository(
            id: "1",
            name: "RepoBar",
            owner: "steipete",
            sortOrder: nil,
            error: nil,
            rateLimitedUntil: nil,
            ciStatus: .unknown,
            ciRunCount: nil,
            openIssues: 0,
            openPulls: 0,
            stars: 0,
            pushedAt: nil,
            latestRelease: nil,
            latestActivity: nil,
            traffic: nil,
            heatmap: []
        )
        let row = RepoRow(repo: repo, activityDate: nil, activityLabel: "-", activityLine: "EVENTLINE-123")

        let output = tableLines([row], useColor: false, includeURL: false, includeRelease: false, includeEvent: false, baseHost: baseHost)
            .joined(separator: "\n")
        #expect(output.contains("EVENT") == false)
        #expect(output.contains("EVENTLINE-123") == false)
    }

    @Test
    func tableShowsEventColumnWhenEnabled() throws {
        let baseHost = URL(string: "https://github.com")!
        let repo = Repository(
            id: "1",
            name: "RepoBar",
            owner: "steipete",
            sortOrder: nil,
            error: nil,
            rateLimitedUntil: nil,
            ciStatus: .unknown,
            ciRunCount: nil,
            openIssues: 0,
            openPulls: 0,
            stars: 0,
            pushedAt: nil,
            latestRelease: nil,
            latestActivity: nil,
            traffic: nil,
            heatmap: []
        )
        let row = RepoRow(repo: repo, activityDate: nil, activityLabel: "-", activityLine: "EVENTLINE-123")

        let output = tableLines([row], useColor: false, includeURL: false, includeRelease: false, includeEvent: true, baseHost: baseHost)
            .joined(separator: "\n")
        #expect(output.contains("EVENT"))
        #expect(output.contains("EVENTLINE-123"))
    }
}
