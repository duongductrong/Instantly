import AppKit
import SwiftUI

// MARK: - Mention Attribute Key

extension NSAttributedString.Key {
    /// Custom attribute used to mark mention ranges in the text view.
    /// The value is the `AutocompleteItem` associated with this mention.
    static let mentionItem = NSAttributedString.Key("com.instantly.mentionItem")
}

// MARK: - Mention Styling

enum MentionStyle {
    /// The highlight color for mention text, loaded from the asset catalog.
    static var highlightColor: NSColor {
        NSColor(named: "MentionHighlight") ?? NSColor(named: "BrandGreen") ?? NSColor(
            red: 0.300,
            green: 0.680,
            blue: 0.180,
            alpha: 1.0
        )
    }

    /// Builds a styled `NSAttributedString` for a mention,
    /// matching the surrounding text font but with bold weight and green highlight.
    static func attributedString(for item: AutocompleteItem, font: NSFont) -> NSAttributedString {
        let boldFont = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
        let mentionText = "@\(item.label)"

        let attributes: [NSAttributedString.Key: Any] = [
            .font: boldFont,
            .foregroundColor: highlightColor,
            .mentionItem: item,
        ]

        let result = NSMutableAttributedString()

        // The highlighted mention text
        let mentionString = NSAttributedString(string: mentionText, attributes: attributes)
        result.append(mentionString)

        // Trailing space in normal style so the user can continue typing normally
        let spaceAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
        ]
        result.append(NSAttributedString(string: " ", attributes: spaceAttrs))

        return result
    }
}
