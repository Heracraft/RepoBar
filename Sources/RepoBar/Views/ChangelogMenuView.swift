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
                        .offset(y: -1)
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
                .padding(.top, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: MenuStyle.changelogPreviewHeight)
            .clipped()

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
        let blocks = ChangelogMarkdownPreviewParser.parse(markdown: self.markdown)

        VStack(alignment: .leading, spacing: 4) {
            ForEach(blocks.indices, id: \.self) { index in
                ChangelogMarkdownBlockView(
                    block: blocks[index],
                    isHighlighted: self.isHighlighted
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum ChangelogMarkdownBlock: Equatable {
    case heading(level: Int, text: String)
    case listItem(marker: String, text: String, indentLevel: Int)
    case paragraphLine(text: String)
    case codeBlock(text: String)
    case blankLine
}

private enum ChangelogMarkdownPreviewParser {
    static func parse(markdown: String) -> [ChangelogMarkdownBlock] {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)

        var blocks: [ChangelogMarkdownBlock] = []
        var inCodeBlock = false
        var codeLines: [String] = []

        func flushCodeBlockIfNeeded() {
            guard codeLines.isEmpty == false else { return }
            blocks.append(.codeBlock(text: codeLines.joined(separator: "\n")))
            codeLines.removeAll()
        }

        for raw in lines {
            let line = String(raw)
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    inCodeBlock = false
                    flushCodeBlockIfNeeded()
                } else {
                    inCodeBlock = true
                    codeLines.removeAll()
                }
                continue
            }

            if inCodeBlock {
                codeLines.append(line)
                continue
            }

            if trimmed.isEmpty {
                blocks.append(.blankLine)
                continue
            }

            if let (level, title) = self.heading(from: trimmed) {
                blocks.append(.heading(level: level, text: title))
                continue
            }

            if let list = self.listItem(from: line) {
                blocks.append(.listItem(marker: list.marker, text: list.text, indentLevel: list.indentLevel))
                continue
            }

            if case .listItem(let marker, let text, let indentLevel)? = blocks.last,
               self.leadingIndentWidth(line) >= (indentLevel + 1) * 2 {
                blocks[blocks.count - 1] = .listItem(
                    marker: marker,
                    text: text + "\n" + trimmed,
                    indentLevel: indentLevel
                )
                continue
            }

            blocks.append(.paragraphLine(text: line))
        }

        if inCodeBlock {
            flushCodeBlockIfNeeded()
        }

        return blocks
    }

    private static func heading(from trimmed: String) -> (Int, String)? {
        guard trimmed.hasPrefix("#") else { return nil }
        let hashes = trimmed.prefix { $0 == "#" }
        let level = hashes.count
        guard level >= 1, level <= 3 else { return nil }
        let remainder = trimmed.dropFirst(level)
        guard remainder.first == " " else { return nil }
        let title = remainder.dropFirst().trimmingCharacters(in: .whitespaces)
        return title.isEmpty ? nil : (level, title)
    }

    private static func listItem(from line: String) -> (marker: String, text: String, indentLevel: Int)? {
        let indentWidth = self.leadingIndentWidth(line)
        let indentLevel = max(0, indentWidth / 2)
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
            return ("•", String(trimmed.dropFirst(2)), indentLevel)
        }

        var index = trimmed.startIndex
        var digits = ""
        while index < trimmed.endIndex, trimmed[index].isNumber {
            digits.append(trimmed[index])
            index = trimmed.index(after: index)
        }
        if digits.isEmpty == false,
           index < trimmed.endIndex,
           trimmed[index] == "."
        {
            let afterDot = trimmed.index(after: index)
            if afterDot < trimmed.endIndex, trimmed[afterDot] == " " {
                let textStart = trimmed.index(after: afterDot)
                return ("\(digits).", String(trimmed[textStart...]), indentLevel)
            }
        }

        return nil
    }

    private static func leadingIndentWidth(_ line: String) -> Int {
        var width = 0
        for ch in line {
            if ch == " " {
                width += 1
                continue
            }
            if ch == "\t" {
                width += 4
                continue
            }
            break
        }
        return width
    }
}

private struct ChangelogMarkdownBlockView: View {
    let block: ChangelogMarkdownBlock
    let isHighlighted: Bool

    var body: some View {
        switch self.block {
        case .blankLine:
            Color.clear.frame(height: 4)
        case let .heading(level, text):
            Text(self.inlineAttributed(text, baseFont: self.headingFont(level)))
                .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, level == 1 ? 6 : 4)
        case let .listItem(marker, text, indentLevel):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(marker)
                    .font(.caption)
                    .frame(width: self.markerWidth(for: marker), alignment: .leading)

                Text(self.inlineAttributed(text, baseFont: .caption))
            }
            .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.leading, CGFloat(indentLevel) * 12)
        case let .paragraphLine(text):
            Text(self.inlineAttributed(text, baseFont: .caption))
                .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        case let .codeBlock(text):
            Text(text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(.quaternary.opacity(self.isHighlighted ? 0.35 : 0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1:
            return .system(size: 12, weight: .semibold)
        case 2:
            return .system(size: 11, weight: .semibold)
        default:
            return .caption.weight(.semibold)
        }
    }

    private func markerWidth(for marker: String) -> CGFloat {
        marker.count >= 2 ? 18 : 12
    }

    private func inlineAttributed(_ text: String, baseFont: Font) -> AttributedString {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        options.failurePolicy = .returnPartiallyParsedIfPossible
        let parsed = (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
        return self.applyBaseFont(to: parsed, baseFont: baseFont)
    }

    private func applyBaseFont(to text: AttributedString, baseFont: Font) -> AttributedString {
        var output = text
        for run in output.runs {
            if run.font == nil {
                output[run.range].font = baseFont
            }
        }
        return output
    }
}
