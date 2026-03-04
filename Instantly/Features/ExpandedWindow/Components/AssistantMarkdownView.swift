import Foundation
import SwiftUI

struct AssistantMarkdownView: View {
    let content: String

    private var segments: [AssistantMarkdownSegment] {
        AssistantMarkdownParser.parseFencedSegments(from: content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(segments.enumerated()), id: \.offset) { entry in
                switch entry.element {
                case let .markdown(text):
                    markdownBlock(text)
                case let .fencedCode(language, code):
                    codeBlock(language: language, code: code)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tint(.cyan.opacity(0.9))
    }

    @ViewBuilder
    private func markdownBlock(_ text: String) -> some View {
        let blocks = AssistantMarkdownParser.parseMarkdownBlocks(from: text)
        if blocks.isEmpty {
            EmptyView()
        } else {
            // Split blocks into groups: consecutive non-table blocks are combined,
            // table blocks are rendered individually with a border.
            let groups = groupBlocks(blocks)
            ForEach(Array(groups.enumerated()), id: \.offset) { entry in
                switch entry.element {
                case let .text(textBlocks):
                    let attributed = buildAttributedString(for: textBlocks)
                    SelectableTextBlock(attributedString: attributed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case let .table(headers, rows):
                    tableBlockView(headers: headers, rows: rows)
                }
            }
        }
    }

    // MARK: - Table grid view

    private func tableBlockView(headers: [String], rows: [[String]]) -> some View {
        let columns = max(headers.count, rows.map(\.count).max() ?? 0)
        let allHeaders = (0 ..< columns).map { $0 < headers.count ? headers[$0] : "" }
        let allRows = rows.map { row in
            (0 ..< columns).map { $0 < row.count ? row[$0] : "" }
        }
        let borderColor = Color.primary.opacity(0.12)

        return VStack(spacing: 0) {
            // Header row
            tableRowView(cells: allHeaders, isHeader: true, borderColor: borderColor)

            // Separator between header and body
            borderColor.frame(height: 1)

            // Data rows
            ForEach(Array(allRows.enumerated()), id: \.offset) { rowIndex, row in
                if rowIndex > 0 {
                    borderColor.frame(height: 1)
                }
                tableRowView(cells: row, isHeader: false, borderColor: borderColor)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tableRowView(cells: [String], isHeader: Bool, borderColor: Color) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                if index > 0 {
                    borderColor.frame(width: 1)
                }
                tableCellView(text: cell, isHeader: isHeader)
            }
        }
    }

    private func tableCellView(text: String, isHeader: Bool) -> some View {
        let font: Font = isHeader
            ? .system(size: 13, weight: .semibold)
            : .system(size: 13)

        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )

        let content = if let parsed = try? AttributedString(markdown: text, options: options) {
            Text(parsed)
        } else {
            Text(text)
        }

        return content
            .font(font)
            .foregroundStyle(.primary.opacity(isHeader ? 0.95 : 0.88))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
    }

    /// Groups consecutive non-table blocks together; tables become their own group.
    private func groupBlocks(_ blocks: [AssistantMarkdownBlock]) -> [MarkdownBlockGroup] {
        var groups: [MarkdownBlockGroup] = []
        var pending: [AssistantMarkdownBlock] = []

        for block in blocks {
            if case let .table(headers, rows) = block {
                if !pending.isEmpty {
                    groups.append(.text(pending))
                    pending.removeAll()
                }
                groups.append(.table(headers: headers, rows: rows))
            } else {
                pending.append(block)
            }
        }
        if !pending.isEmpty {
            groups.append(.text(pending))
        }
        return groups
    }

    /// Builds a single NSAttributedString from a group of non-table blocks.
    private func buildAttributedString(for blocks: [AssistantMarkdownBlock]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for (i, block) in blocks.enumerated() {
            if i > 0 {
                result.append(NSAttributedString(string: "\n", attributes: [.font: NSFont.systemFont(ofSize: 8)]))
            }
            result.append(
                MarkdownAttributedStringBuilder.buildBlock(
                    block,
                    baseFont: .systemFont(ofSize: 14),
                    textColor: .labelColor,
                    lineSpacing: 4
                )
            )
        }
        return result
    }

    private func codeBlock(language: String?, code: String) -> some View {
        let attributed = MarkdownAttributedStringBuilder.build(
            from: [.fencedCode(language: language, code: code)],
            baseFont: .monospacedSystemFont(ofSize: 13, weight: .regular),
            textColor: .labelColor,
            lineSpacing: 3
        )

        return SelectableTextBlock(attributedString: attributed)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum MarkdownBlockGroup {
    case text([AssistantMarkdownBlock])
    case table(headers: [String], rows: [[String]])
}
