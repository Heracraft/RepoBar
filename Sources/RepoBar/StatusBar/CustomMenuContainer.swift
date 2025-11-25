import SwiftUI

struct CustomMenuContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
            self.content()
                .padding(.horizontal, 0)
                .padding(.vertical, 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .frame(minWidth: 360, maxWidth: 460)
        .shadow(color: .black.opacity(0.10), radius: 12, y: 8)
    }
}
