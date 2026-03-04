import AppKit
import SwiftUI

/// An NSViewRepresentable wrapper around NSTextView that enables native
/// multi-line text selection for read-only content on macOS.
/// The view expands to fit all content — no internal scrolling.
struct SelectableText: NSViewRepresentable {
    let attributedString: NSAttributedString

    @Binding var dynamicHeight: CGFloat

    init(attributedString: NSAttributedString, dynamicHeight: Binding<CGFloat>? = nil) {
        self.attributedString = attributedString
        self._dynamicHeight = dynamicHeight ?? .constant(0)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.isRichText = true
        textView.usesAdaptiveColorMappingForDarkAppearance = true
        textView.textContainerInset = .zero
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )

        textView.linkTextAttributes = [
            .foregroundColor: NSColor(Color.cyan.opacity(0.9)),
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]

        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        context.coordinator.textView = textView
        return textView
    }

    func updateNSView(_ textView: NSTextView, context: Context) {
        let storage = textView.textStorage!
        storage.beginEditing()
        storage.setAttributedString(attributedString)
        storage.endEditing()

        // Recalculate height after content update
        DispatchQueue.main.async {
            context.coordinator.recalculateHeight()
        }
    }

    class Coordinator {
        var parent: SelectableText
        weak var textView: NSTextView?

        init(_ parent: SelectableText) {
            self.parent = parent
        }

        func recalculateHeight() {
            guard let textView,
                  let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer
            else { return }

            layoutManager.ensureLayout(for: textContainer)
            let usedRect = layoutManager.usedRect(for: textContainer)
            let newHeight = ceil(usedRect.height) + 2 // +2 for minor padding

            if abs(parent.dynamicHeight - newHeight) > 1 {
                parent.dynamicHeight = max(newHeight, 18)
            }
        }
    }
}

// MARK: - Self-sizing wrapper

/// A convenience wrapper that manages its own height state.
struct SelectableTextBlock: View {
    let attributedString: NSAttributedString

    @State private var height: CGFloat = 18

    var body: some View {
        SelectableText(
            attributedString: attributedString,
            dynamicHeight: $height
        )
        .frame(height: height)
    }
}

// MARK: - Markdown to NSAttributedString conversion

enum MarkdownAttributedStringBuilder {
    /// Build an NSAttributedString from the parsed markdown segments for assistant messages.
    /// This combines all text into one attributable string enabling full text selection.
    static func build(
        from segments: [AssistantMarkdownSegment],
        baseFont: NSFont = .systemFont(ofSize: 14),
        textColor: NSColor = .labelColor,
        lineSpacing: CGFloat = 4
    )
        -> NSAttributedString
    {
        let result = NSMutableAttributedString()

        for (index, segment) in segments.enumerated() {
            if index > 0 {
                result.append(newline())
            }

            switch segment {
            case let .markdown(text):
                let blocks = AssistantMarkdownParser.parseMarkdownBlocks(from: text)
                for (blockIndex, block) in blocks.enumerated() {
                    if blockIndex > 0 {
                        result.append(newline())
                    }
                    result.append(
                        buildBlock(
                            block,
                            baseFont: baseFont,
                            textColor: textColor,
                            lineSpacing: lineSpacing
                        )
                    )
                }

            case let .fencedCode(language, code):
                if let language, !language.isEmpty {
                    let langAttrs: [NSAttributedString.Key: Any] = [
                        .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .semibold),
                        .foregroundColor: textColor.withAlphaComponent(0.45),
                    ]
                    result.append(NSAttributedString(string: language.uppercased() + "\n", attributes: langAttrs))
                }

                let codeAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                    .foregroundColor: textColor.withAlphaComponent(0.92),
                    .paragraphStyle: codeBlockParagraphStyle(),
                    .backgroundColor: textColor.withAlphaComponent(0.06),
                ]
                let trimmedCode = code.trimmingCharacters(in: .newlines)
                result.append(NSAttributedString(string: trimmedCode, attributes: codeAttrs))
            }
        }

        return result
    }

    /// Build an NSAttributedString for a simple plain text (user messages).
    static func buildPlainText(
        _ text: String,
        font: NSFont = .systemFont(ofSize: 14),
        textColor: NSColor = .labelColor
    )
        -> NSAttributedString
    {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]
        return NSAttributedString(string: text, attributes: attrs)
    }

    // MARK: - Block builders

    private static func buildBlock(
        _ block: AssistantMarkdownBlock,
        baseFont: NSFont,
        textColor: NSColor,
        lineSpacing: CGFloat
    )
        -> NSAttributedString
    {
        switch block {
        case let .heading(level, text):
            buildHeading(level: level, text: text, textColor: textColor)
        case let .paragraph(text):
            buildParagraph(text: text, baseFont: baseFont, textColor: textColor, lineSpacing: lineSpacing)
        case .divider:
            buildDivider()
        case let .table(headers, rows):
            buildTable(headers: headers, rows: rows, textColor: textColor)
        }
    }

    private static func buildHeading(level: Int, text: String, textColor: NSColor) -> NSAttributedString {
        let size: CGFloat = switch level {
        case 1: 20
        case 2: 18
        case 3: 16
        default: 15
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        paragraphStyle.paragraphSpacingBefore = level <= 2 ? 4 : 0

        let result = parseInlineMarkdown(
            text,
            baseFont: .systemFont(ofSize: size, weight: .semibold),
            baseColor: textColor.withAlphaComponent(0.98)
        )

        let mutable = NSMutableAttributedString(attributedString: result)
        mutable.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: mutable.length)
        )
        return mutable
    }

    private static func buildParagraph(
        text: String,
        baseFont: NSFont,
        textColor: NSColor,
        lineSpacing: CGFloat
    )
        -> NSAttributedString
    {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing

        let result = parseInlineMarkdown(
            text,
            baseFont: baseFont,
            baseColor: textColor.withAlphaComponent(0.95)
        )

        let mutable = NSMutableAttributedString(attributedString: result)
        mutable.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: mutable.length)
        )
        return mutable
    }

    private static func buildDivider() -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacingBefore = 4
        paragraphStyle.paragraphSpacing = 4
        return NSAttributedString(
            string: "——————————————————————\n",
            attributes: [
                .font: NSFont.systemFont(ofSize: 6),
                .foregroundColor: NSColor.labelColor.withAlphaComponent(0.16),
                .paragraphStyle: paragraphStyle,
            ]
        )
    }

    private static func buildTable(
        headers: [String],
        rows: [[String]],
        textColor: NSColor
    )
        -> NSAttributedString
    {
        let result = NSMutableAttributedString()
        let columns = max(headers.count, rows.map(\.count).max() ?? 0)

        // Header row
        let headerText = headers.joined(separator: "  |  ")
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: textColor.withAlphaComponent(0.95),
        ]
        result.append(NSAttributedString(string: headerText + "\n", attributes: headerAttrs))

        // Separator
        let separator = String(repeating: "─", count: columns * 12)
        result.append(NSAttributedString(
            string: separator + "\n",
            attributes: [
                .font: NSFont.systemFont(ofSize: 8),
                .foregroundColor: textColor.withAlphaComponent(0.18),
            ]
        ))

        // Data rows
        for (rowIndex, row) in rows.enumerated() {
            let padded = (0 ..< columns).map { index in
                index < row.count ? row[index] : ""
            }
            let rowText = padded.joined(separator: "  |  ")
            let rowAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: textColor.withAlphaComponent(0.88),
            ]
            let suffix = rowIndex < rows.count - 1 ? "\n" : ""
            result.append(NSAttributedString(string: rowText + suffix, attributes: rowAttrs))
        }

        return result
    }

    // MARK: - Inline markdown parsing

    private static func parseInlineMarkdown(
        _ text: String,
        baseFont: NSFont,
        baseColor: NSColor
    )
        -> NSAttributedString
    {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )

        if let parsed = try? AttributedString(markdown: text, options: options) {
            let nsAttr = NSMutableAttributedString(parsed)
            let fullRange = NSRange(location: 0, length: nsAttr.length)
            nsAttr.addAttribute(.foregroundColor, value: baseColor, range: fullRange)

            nsAttr.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
                if value == nil {
                    nsAttr.addAttribute(.font, value: baseFont, range: range)
                }
            }

            // Style inline code
            nsAttr.enumerateAttribute(.inlinePresentationIntent, in: fullRange, options: []) { value, range, _ in
                if let intent = value as? InlinePresentationIntent, intent.contains(.code) {
                    nsAttr.addAttribute(
                        .font,
                        value: NSFont.monospacedSystemFont(ofSize: baseFont.pointSize - 1, weight: .regular),
                        range: range
                    )
                    nsAttr.addAttribute(.backgroundColor, value: baseColor.withAlphaComponent(0.08), range: range)
                }
            }

            return nsAttr
        }

        return NSAttributedString(
            string: text,
            attributes: [
                .font: baseFont,
                .foregroundColor: baseColor,
            ]
        )
    }

    // MARK: - Helpers

    private static func newline() -> NSAttributedString {
        NSAttributedString(string: "\n", attributes: [.font: NSFont.systemFont(ofSize: 8)])
    }

    private static func codeBlockParagraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        return style
    }
}
