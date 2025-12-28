import AppKit
@testable import RepoBar
import RepoBarCore
import Testing

struct StatusBarIconControllerTests {
    @Test
    @MainActor
    func updateAlwaysSetsImageForKnownSymbols() {
        let controller = StatusBarIconController()

        let loggedOut = Session()
        loggedOut.account = .loggedOut

        let loggedIn = Session()
        loggedIn.account = .loggedIn(UserIdentity(username: "tester", host: URL(string: "https://github.com")!))

        let button1 = NSStatusBarButton()
        controller.update(button: button1, session: loggedOut)
        #expect(button1.image != nil)

        let button2 = NSStatusBarButton()
        controller.update(button: button2, session: loggedIn)
        #expect(button2.image != nil)
    }
}
