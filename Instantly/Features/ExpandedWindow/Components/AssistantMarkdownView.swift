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
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func markdownBlock(_ text: String) -> some View {
        let blocks = AssistantMarkdownParser.parseMarkdownBlocks(from: text)

        if blocks.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { entry in
                    renderBlock(entry.element)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func renderBlock(_ block: AssistantMarkdownBlock) -> some View {
        switch block {
        case let .heading(level, text):
            Text(inlineAttributedText(from: text) ?? AttributedString(text))
                .font(.system(size: headingFontSize(for: level), weight: .semibold))
                .foregroundStyle(.white.opacity(0.98))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, level <= 2 ? 2 : 0)
        case let .paragraph(text):
            paragraphBlock(text)
        case .divider:
            Rectangle()
                .fill(Color.white.opacity(0.16))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        case let .table(headers, rows):
            tableBlock(headers: headers, rows: rows)
        }
    }

    @ViewBuilder
    private func paragraphBlock(_ text: String) -> some View {
        if let parsed = markdownAttributedText(from: text) {
            Text(parsed)
                .foregroundStyle(.white.opacity(0.95))
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.95))
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func codeBlock(language: String?, code: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let language, !language.isEmpty {
                Text(language.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code.trimmingCharacters(in: .newlines))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineSpacing(3)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.22))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tableBlock(headers: [String], rows: [[String]]) -> some View {
        let columns = max(headers.count, rows.map(\.count).max() ?? 0)

        return VStack(spacing: 0) {
            tableRow(headers, columns: columns, isHeader: true)
            Rectangle().fill(Color.white.opacity(0.18)).frame(height: 1)

            ForEach(Array(rows.enumerated()), id: \.offset) { entry in
                tableRow(entry.element, columns: columns, isHeader: false)
                if entry.offset < rows.count - 1 {
                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                }
            }
        }
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func tableRow(_ cells: [String], columns: Int, isHeader: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(0 ..< columns, id: \.self) { index in
                let value = index < cells.count ? cells[index] : ""
                Text(inlineAttributedText(from: value) ?? AttributedString(value))
                    .font(.system(size: 13, weight: isHeader ? .semibold : .regular))
                    .foregroundStyle(.white.opacity(isHeader ? 0.95 : 0.88))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)

                if index < columns - 1 {
                    Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1)
                }
            }
        }
    }

    private func markdownAttributedText(from text: String) -> AttributedString? {
        let fullOptions = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .full,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        if let parsed = try? AttributedString(markdown: text, options: fullOptions) {
            return parsed
        }

        let inlineOptions = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        return try? AttributedString(markdown: text, options: inlineOptions)
    }

    private func inlineAttributedText(from text: String) -> AttributedString? {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        return try? AttributedString(markdown: text, options: options)
    }

    private func headingFontSize(for level: Int) -> CGFloat {
        switch level {
        case 1: 20
        case 2: 18
        case 3: 16
        default: 15
        }
    }
}
