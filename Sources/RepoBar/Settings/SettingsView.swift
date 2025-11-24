import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var session: Session
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
            AccountSettingsView()
                .tabItem { Label("Accounts", systemImage: "person.crop.circle") }
            AdvancedSettingsView()
                .tabItem { Label("Advanced", systemImage: "wrench.and.screwdriver") }
        }
        .frame(width: 520, height: 360)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var session: Session
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Toggle("Show contribution header", isOn: self.$session.settings.showContributionHeader)
                .onChange(of: self.session.settings.showContributionHeader) { _, _ in self.appState.persistSettings() }
            Toggle("Show heatmap", isOn: self.$session.settings.showHeatmap)
                .onChange(of: self.session.settings.showHeatmap) { _, _ in self.appState.persistSettings() }
            Picker("Repositories shown", selection: self.$session.settings.repoDisplayLimit) {
                ForEach([3, 5, 8, 12], id: \.self) { Text("\($0)").tag($0) }
            }
            .onChange(of: self.session.settings.repoDisplayLimit) { _, _ in self.appState.persistSettings() }
            Picker("Refresh interval", selection: self.$session.settings.refreshInterval) {
                ForEach(RefreshInterval.allCases, id: \.self) { interval in
                    Text(self.intervalLabel(interval)).tag(interval)
                }
            }
            .onChange(of: self.session.settings.refreshInterval) { _, newValue in
                LaunchAtLoginHelper.set(enabled: self.session.settings.launchAtLogin)
                self.appState.persistSettings()
                Task { @MainActor in
                    self.appState.refreshScheduler.configure(interval: newValue.seconds) { [weak appState] in
                        Task { await appState?.refresh() }
                    }
                }
            }
            Toggle("Launch at login", isOn: self.$session.settings.launchAtLogin)
                .onChange(of: self.session.settings.launchAtLogin) { _, value in
                    LaunchAtLoginHelper.set(enabled: value)
                    self.appState.persistSettings()
                }
        }
        .padding()
    }

    private func intervalLabel(_ interval: RefreshInterval) -> String {
        switch interval {
        case .oneMinute: "1 minute"
        case .twoMinutes: "2 minutes"
        case .fiveMinutes: "5 minutes"
        case .fifteenMinutes: "15 minutes"
        }
    }
}

struct AccountSettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var session: Session
    @State private var clientID = "Iv23liGm2arUyotWSjwJ"
    @State private var clientSecret = ""
    @State private var pemPath = ""
    @State private var enterpriseHost = ""
    @State private var port: Int = 53682

    var body: some View {
        Form {
            Section("GitHub.com") {
                TextField("Client ID", text: self.$clientID)
                SecureField("Client Secret", text: self.$clientSecret)
                TextField("Private key path", text: self.$pemPath)
                Button("Browse…") { self.browsePem() }
                Button("Sign in") { self.login() }
                if case let .loggedIn(user) = session.account {
                    Text("Signed in as \(user.username) on \(user.host.host ?? "github.com")")
                        .font(.caption)
                    Button("Log out") {
                        Task {
                            await self.appState.auth.logout()
                            self.session.account = .loggedOut
                        }
                    }
                }
            }

            Section("Enterprise (optional)") {
                TextField("Base URL (https://host)", text: self.$enterpriseHost)
                Text("Trusted TLS only; leave blank if unused")
                    .font(.caption)
            }

            Section("Callback") {
                Stepper(value: self.$port, in: 1025 ... 65535) {
                    Text("Loopback port: \(self.port)")
                }
            }
        }
        .padding()
        .onAppear {
            self.port = self.session.settings.loopbackPort
        }
    }

    private func browsePem() {
        let panel = NSOpenPanel()
        if let pemType = UTType(filenameExtension: "pem") {
            panel.allowedContentTypes = [pemType]
        }
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            self.pemPath = url.path
        }
    }

    private func login() {
        Task { @MainActor in
            self.session.account = .loggingIn
            self.session.settings.loopbackPort = self.port
            let enterpriseURL = self.normalizedEnterpriseHost()

            if let enterpriseURL {
                self.session.settings.enterpriseHost = enterpriseURL
                await self.appState.github.setAPIHost(enterpriseURL.appending(path: "/api/v3"))
                self.session.settings.githubHost = enterpriseURL
            } else {
                await self.appState.github.setAPIHost(URL(string: "https://api.github.com")!)
                self.session.settings.githubHost = URL(string: "https://github.com")!
                self.session.settings.enterpriseHost = nil
            }
            do {
                try await self.appState.auth.login(
                    clientID: self.clientID,
                    clientSecret: self.clientSecret,
                    pemPath: self.pemPath,
                    host: self.session.settings.enterpriseHost ?? self.session.settings.githubHost,
                    loopbackPort: self.port
                )
                if let user = try? await appState.github.currentUser() {
                    self.session.account = .loggedIn(user)
                    self.session.lastError = nil
                }
            } catch {
                self.session.account = .loggedOut
                self.session.lastError = error.userFacingMessage
            }
        }
    }

    private func normalizedEnterpriseHost() -> URL? {
        guard !self.enterpriseHost.isEmpty else { return nil }
        guard var components = URLComponents(string: enterpriseHost) else { return nil }
        if components.scheme == nil { components.scheme = "https" }
        guard components.scheme?.lowercased() == "https", components.host != nil else { return nil }
        components.path = ""
        components.query = nil
        components.fragment = nil
        return components.url
    }
}

struct AdvancedSettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var session: Session

    var body: some View {
        Form {
            Button("Clear cache") {
                Task { await self.appState.github.clearCache() }
            }
            Button("Force refresh") {
                self.appState.refreshScheduler.forceRefresh()
            }
            Section("Diagnostics") {
                LabeledContent("API host") {
                    Text(self.appState.session.settings.githubHost.absoluteString)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if let reset = session.rateLimitReset {
                    LabeledContent("Rate limit resets") {
                        Text(RelativeFormatter.string(from: reset, relativeTo: Date()))
                    }
                }
                if let error = session.lastError {
                    LabeledContent("Last error") { Text(error).foregroundStyle(.red) }
                }
            }
        }
        .padding()
    }
}
