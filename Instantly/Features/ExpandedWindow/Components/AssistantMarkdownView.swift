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
            let attributed = MarkdownAttributedStringBuilder.build(
                from: [.markdown(text)],
                baseFont: .systemFont(ofSize: 14),
                textColor: .labelColor,
                lineSpacing: 4
            )
            SelectableTextBlock(attributedString: attributed)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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
