import SwiftUI

struct AddRepoView: View {
    @Binding var isPresented: Bool
    var onSelect: (Repository) -> Void
    @State private var query = ""
    @State private var results: [Repository] = []

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pin a repository")
                .font(.headline)
            TextField("owner/name", text: self.$query)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    Task { await self.search() }
                }
            List(self.results) { repo in
                Button {
                    self.onSelect(repo)
                    self.isPresented = false
                } label: {
                    VStack(alignment: .leading) {
                        Text(repo.fullName).bold()
                        if let release = repo.latestRelease {
                            Text("Latest: \(release.name)").font(.caption)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            HStack {
                Spacer()
                Button("Cancel") { self.isPresented = false }
            }
        }
        .padding(16)
        .frame(width: 380, height: 420)
        .onAppear { Task { await self.searchDefault() } }
    }

    private func searchDefault() async { await self.search() }

    private func search() async {
        guard !self.query.isEmpty else { return }
        do {
            let repos = try await appState.github.searchRepositories(matching: self.query)
            await MainActor.run { self.results = repos }
        } catch {
            // Ignored; UI stays empty
        }
    }
}
