import SwiftUI

struct ChangelogMenuView: View {
    let content: ChangelogContent

    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: MenuStyle.submenuIconSpacing) {
                SubmenuIconColumnView {
                    Image(systemName: "doc.text")
                        .symbolRenderingMode(.hierarchical)
                        .font(.caption)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                }

                Text(self.content.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                    .lineLimit(1)

                Text(self.content.source.label)
                    .font(.caption2)
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }

            ScrollView(.vertical) {
                MarkdownTextView(
                    markdown: self.content.markdown,
                    isHighlighted: self.isHighlighted
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: MenuStyle.changelogPreviewHeight)

            if self.content.isTruncated {
                Text("Preview truncated")
                    .font(.caption2)
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
            }
        }
        .padding(.horizontal, MenuStyle.cardHorizontalPadding)
        .padding(.vertical, MenuStyle.cardVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MarkdownTextView: View {
    let markdown: String
    let isHighlighted: Bool

    var body: some View {
        Text(self.attributedText)
            .font(.caption)
            .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var attributedText: AttributedString {
        let source = self.markdownWithHardBreaks
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .full
        options.failurePolicy = .returnPartiallyParsedIfPossible
        if let parsed = try? AttributedString(markdown: source, options: options) {
            return parsed
        }
        return AttributedString(source)
    }

    private var markdownWithHardBreaks: String {
        let normalized = self.markdown.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        var inCodeBlock = false
        let processed = lines.map { rawLine -> String in
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                inCodeBlock.toggle()
                return line
            }
            if inCodeBlock || trimmed.isEmpty {
                return line
            }
            return "\(line)  "
        }
        return processed.joined(separator: "\n")
    }
}
