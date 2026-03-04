import Foundation

enum AssistantMarkdownSegment {
    case markdown(String)
    case fencedCode(language: String?, code: String)
}

struct ListItem {
    let indent: Int
    let text: String
    /// nil = normal list item, true = checked task, false = unchecked task
    let isChecked: Bool?
}

enum AssistantMarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(String)
    case divider
    case table(headers: [String], rows: [[String]])
    case unorderedList(items: [ListItem])
    case orderedList(items: [ListItem])
    case blockquote(text: String)
}

enum AssistantMarkdownParser {
    static func parseFencedSegments(from text: String) -> [AssistantMarkdownSegment] {
        let pattern = #"```([^\n`]*)\n([\s\S]*?)```"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [.markdown(text)]
        }

        let nsRange = NSRange(text.startIndex ..< text.endIndex, in: text)
        let matches = regex.matches(in: text, range: nsRange)
        guard !matches.isEmpty else { return [.markdown(text)] }

        var output: [AssistantMarkdownSegment] = []
        var cursor = text.startIndex

        for match in matches {
            guard let fullRange = Range(match.range(at: 0), in: text) else { continue }

            if cursor < fullRange.lowerBound {
                let markdownChunk = String(text[cursor ..< fullRange.lowerBound])
                if !markdownChunk.isEmpty {
                    output.append(.markdown(markdownChunk))
                }
            }

            let language: String? = {
                guard let languageRange = Range(match.range(at: 1), in: text) else { return nil }
                let value = text[languageRange].trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? nil : value
            }()

            let code: String = {
                guard let codeRange = Range(match.range(at: 2), in: text) else { return "" }
                return String(text[codeRange])
            }()

            output.append(.fencedCode(language: language, code: code))
            cursor = fullRange.upperBound
        }

        if cursor < text.endIndex {
            output.append(.markdown(String(text[cursor...])))
        }

        return output
    }

    static func parseMarkdownBlocks(from text: String) -> [AssistantMarkdownBlock] {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [AssistantMarkdownBlock] = []
        var paragraph: [String] = []
        var index = 0

        func flushParagraph() {
            let joined = paragraph.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty { blocks.append(.paragraph(joined)) }
            paragraph.removeAll()
        }

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                flushParagraph()
                index += 1
                continue
            }

            // Divider must be checked before unordered list because `---` / `***` could look like a bullet
            if isDividerLine(trimmed) {
                flushParagraph()
                blocks.append(.divider)
                index += 1
                continue
            }

            if let heading = parseHeading(from: trimmed) {
                flushParagraph()
                blocks.append(heading)
                index += 1
                continue
            }

            if let table = parseTable(lines: lines, startAt: index) {
                flushParagraph()
                blocks.append(.table(headers: table.headers, rows: table.rows))
                index = table.nextIndex
                continue
            }

            // Blockquote: lines starting with >
            if trimmed.hasPrefix(">") {
                flushParagraph()
                var quoteLines: [String] = []
                while index < lines.count {
                    let qLine = lines[index].trimmingCharacters(in: .whitespaces)
                    guard qLine.hasPrefix(">") else { break }
                    var content = String(qLine.dropFirst()) // drop the >
                    if content.hasPrefix(" ") { content = String(content.dropFirst()) } // drop optional space
                    quoteLines.append(content)
                    index += 1
                }
                blocks.append(.blockquote(text: quoteLines.joined(separator: "\n")))
                continue
            }

            // Unordered list: lines starting with - , * , + (with optional leading spaces)
            if isUnorderedListLine(line) {
                flushParagraph()
                var items: [ListItem] = []
                while index < lines.count, isUnorderedListLine(lines[index]) {
                    items.append(parseUnorderedListItem(lines[index]))
                    index += 1
                }
                blocks.append(.unorderedList(items: items))
                continue
            }

            // Ordered list: lines starting with digits followed by .
            if isOrderedListLine(line) {
                flushParagraph()
                var items: [ListItem] = []
                while index < lines.count, isOrderedListLine(lines[index]) {
                    items.append(parseOrderedListItem(lines[index]))
                    index += 1
                }
                blocks.append(.orderedList(items: items))
                continue
            }

            paragraph.append(line)
            index += 1
        }

        flushParagraph()
        return blocks
    }

    private static func parseHeading(from line: String) -> AssistantMarkdownBlock? {
        let level = line.prefix { $0 == "#" }.count
        guard (1 ... 6).contains(level), line.count > level, line.dropFirst(level).first == " " else { return nil }
        return .heading(level: level, text: String(line.dropFirst(level + 1)))
    }

    private static func isDividerLine(_ line: String) -> Bool {
        let value = line.replacingOccurrences(of: " ", with: "")
        let repeated = Set(["---", "***", "___"])
        return repeated.contains(value)
            || value.range(of: #"^([-*_])\1{2,}$"#, options: .regularExpression) != nil
    }

    private static func parseTable(lines: [String], startAt start: Int) -> ParsedTable? {
        guard start + 1 < lines.count else { return nil }
        let headerLine = lines[start].trimmingCharacters(in: .whitespaces)
        let separatorLine = lines[start + 1].trimmingCharacters(in: .whitespaces)
        guard headerLine.contains("|"), isTableSeparatorLine(separatorLine) else { return nil }

        let headers = splitTableRow(headerLine)
        guard !headers.isEmpty else { return nil }

        var rows: [[String]] = []
        var index = start + 2
        while index < lines.count {
            let line = lines[index].trimmingCharacters(in: .whitespaces)
            if line.isEmpty || !line.contains("|") || isTableSeparatorLine(line) { break }
            rows.append(splitTableRow(line))
            index += 1
        }

        return ParsedTable(headers: headers, rows: rows, nextIndex: index)
    }

    private static func isTableSeparatorLine(_ line: String) -> Bool {
        let cells = splitTableRow(line)
        guard !cells.isEmpty else { return false }
        return cells.allSatisfy { cell in
            let trimmed = cell.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty
                && trimmed.contains("-")
                && trimmed.allSatisfy { $0 == "-" || $0 == ":" }
        }
    }

    private static func splitTableRow(_ line: String) -> [String] {
        var value = line.trimmingCharacters(in: .whitespaces)
        if value.first == "|" { value.removeFirst() }
        if value.last == "|" { value.removeLast() }
        return value.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: - List helpers

    private static func isUnorderedListLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        // Must be "- ", "* ", "+ " but not a divider like "---" or "***"
        guard trimmed.count >= 2 else { return false }
        let first = trimmed.first!
        guard ["-", "*", "+"].contains(String(first)) else { return false }
        let second = trimmed[trimmed.index(after: trimmed.startIndex)]
        // "- text" or "- [ ] text" or "- [x] text"
        return second == " "
    }

    private static func isOrderedListLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        // Match "1. ", "2. ", "10. " etc.
        guard let dotIndex = trimmed.firstIndex(of: ".") else { return false }
        let prefix = trimmed[trimmed.startIndex ..< dotIndex]
        guard !prefix.isEmpty, prefix.allSatisfy(\.isNumber) else { return false }
        let afterDot = trimmed.index(after: dotIndex)
        return afterDot < trimmed.endIndex && trimmed[afterDot] == " "
    }

    private static func parseUnorderedListItem(_ line: String) -> ListItem {
        let leadingSpaces = line.prefix { $0 == " " || $0 == "\t" }.count
        let indent = leadingSpaces / 2 // every 2 spaces = 1 indent level
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        // Drop the bullet character and the space after it
        var content = String(trimmed.dropFirst(2))

        // Check for task list: [ ] or [x] or [X]
        var isChecked: Bool? = nil
        if content.hasPrefix("[ ] ") {
            isChecked = false
            content = String(content.dropFirst(4))
        } else if content.hasPrefix("[x] ") || content.hasPrefix("[X] ") {
            isChecked = true
            content = String(content.dropFirst(4))
        }

        return ListItem(indent: indent, text: content, isChecked: isChecked)
    }

    private static func parseOrderedListItem(_ line: String) -> ListItem {
        let leadingSpaces = line.prefix { $0 == " " || $0 == "\t" }.count
        let indent = leadingSpaces / 2
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        // Find the ". " and take everything after
        guard let dotIndex = trimmed.firstIndex(of: ".") else {
            return ListItem(indent: indent, text: trimmed, isChecked: nil)
        }
        let afterDot = trimmed.index(dotIndex, offsetBy: 2, limitedBy: trimmed.endIndex) ?? trimmed.endIndex
        let content = String(trimmed[afterDot...])
        return ListItem(indent: indent, text: content, isChecked: nil)
    }
}

private struct ParsedTable {
    let headers: [String]
    let rows: [[String]]
    let nextIndex: Int
}
