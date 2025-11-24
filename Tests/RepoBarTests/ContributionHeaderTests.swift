import SwiftUI
import Testing
@testable import RepoBar

@MainActor
struct ContributionHeaderTests {
    @Test
    func emptyUsernameShowsNothing() {
        let view = ContributionHeaderView(username: nil)
        // When username is nil the body should render EmptyView (no AsyncImage)
        let mirror = Mirror(reflecting: view.body)
        #expect(mirror.displayStyle == .tuple || mirror.children.isEmpty)
    }
}
