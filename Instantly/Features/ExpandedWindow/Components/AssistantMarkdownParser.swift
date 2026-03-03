import Foundation

enum AssistantMarkdownSegment {
    case markdown(String)
    case fencedCode(language: String?, code: String)
}

enum AssistantMarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(String)
    case divider
    case table(headers: [String], rows: [[String]])
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
}

private struct ParsedTable {
    let headers: [String]
    let rows: [[String]]
    let nextIndex: Int
}
