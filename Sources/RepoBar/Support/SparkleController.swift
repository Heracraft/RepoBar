import Security

@MainActor
protocol UpdaterProviding: AnyObject {
    var automaticallyChecksForUpdates: Bool { get set }
    var isAvailable: Bool { get }
    func checkForUpdates(_ sender: Any?)
}

/// No-op updater used for unsigned/dev or non-app builds so Sparkle dialogs don’t appear in development/test runs.
final class DisabledUpdaterController: UpdaterProviding {
    var automaticallyChecksForUpdates: Bool = false
    let isAvailable: Bool = false
    func checkForUpdates(_: Any?) {}
}

#if canImport(Sparkle)
import Sparkle

extension SPUStandardUpdaterController: UpdaterProviding {
    var automaticallyChecksForUpdates: Bool {
        get { self.updater.automaticallyChecksForUpdates }
        set { self.updater.automaticallyChecksForUpdates = newValue }
    }

    var isAvailable: Bool { true }
}
#endif

/// Simple Sparkle wrapper so we can call from menus without passing around the updater.
@MainActor
final class SparkleController {
    static let shared = SparkleController()
    private let updater: UpdaterProviding
    private let defaultsKey = "autoUpdateEnabled"

    private init() {
        #if canImport(Sparkle)
            let bundleURL = Bundle.main.bundleURL
            let isBundledApp = bundleURL.pathExtension == "app"
            let isSigned = SparkleController.isDeveloperIDSigned(bundleURL: bundleURL)
            if isBundledApp, isSigned {
                let saved = (UserDefaults.standard.object(forKey: defaultsKey) as? Bool) ?? true
                let controller = SPUStandardUpdaterController(
                    startingUpdater: false,
                    updaterDelegate: nil,
                    userDriverDelegate: nil
                )
                controller.automaticallyChecksForUpdates = saved
                controller.startUpdater()
                self.updater = controller
            } else {
                self.updater = DisabledUpdaterController()
            }
        #else
            self.updater = DisabledUpdaterController()
        #endif
    }

    var canCheckForUpdates: Bool {
        self.updater.isAvailable
    }

    var automaticallyChecksForUpdates: Bool {
        get { self.updater.automaticallyChecksForUpdates }
        set {
            self.updater.automaticallyChecksForUpdates = newValue
            UserDefaults.standard.set(newValue, forKey: self.defaultsKey)
        }
    }

    func checkForUpdates() {
        guard self.canCheckForUpdates else { return }
        self.updater.checkForUpdates(nil)
    }

    private static func isDeveloperIDSigned(bundleURL: URL) -> Bool {
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(bundleURL as CFURL, SecCSFlags(), &staticCode) == errSecSuccess,
              let code = staticCode else { return false }

        var infoCF: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &infoCF) == errSecSuccess,
              let info = infoCF as? [String: Any],
              let certs = info[kSecCodeInfoCertificates as String] as? [SecCertificate],
              let leaf = certs.first else { return false }

        if let summary = SecCertificateCopySubjectSummary(leaf) as String? {
            return summary.hasPrefix("Developer ID Application:")
        }
        return false
    }
}
