import SwiftUI

/// A multi-line text input that grows with content, supports Shift+Enter for new lines,
/// and Enter to submit. Wraps NSTextView for precise key event handling.
/// Supports inline mention-tag attachments (pill/chip rendering).
struct MultiLineTextView: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var font: NSFont = .systemFont(ofSize: 14)
    var textColor: NSColor = .labelColor
    var placeholderColor: NSColor = .placeholderTextColor
    var maxHeight: CGFloat = 120
    var onSubmit: (() -> Void)?
    var onArrowUp: (() -> Bool)?
    var onArrowDown: (() -> Bool)?
    var onEscape: (() -> Void)?
    var isAutocompleteActive: Bool = false
    @Binding var shouldMoveCursorToEnd: Bool

    @Binding var dynamicHeight: CGFloat
    @Binding var shouldFocus: Bool

    /// The view model, used for mention-tag insertion signals.
    var viewModel: ExpandedWindowViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.scrollerStyle = .overlay
        scrollView.scrollerKnobStyle = .light

        if let scroller = scrollView.verticalScroller {
            scroller.controlSize = .mini
        }

        let textView = SubmitTextView()
        textView.delegate = context.coordinator
        textView.onSubmit = onSubmit
        textView.onArrowUp = onArrowUp
        textView.onArrowDown = onArrowDown
        textView.onEscape = onEscape
        textView.isAutocompleteActive = isAutocompleteActive
        textView.font = font
        textView.textColor = textColor
        textView.insertionPointColor = textColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 0, height: 2)
        textView.autoresizingMask = [.width]

        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: .greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        context.coordinator.textView = textView

        // Register the extractReadableText closure on the view model
        let coordinator = context.coordinator
        viewModel.extractReadableText = { [weak coordinator] in
            coordinator?.extractReadableText() ?? ""
        }

        DispatchQueue.main.async {
            context.coordinator.recalculateHeight()
            textView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? SubmitTextView else { return }

        // Handle pending mention insertion first
        if let mentionItem = viewModel.pendingMentionInsertion {
            context.coordinator.insertMentionTag(mentionItem, in: textView)
            DispatchQueue.main.async {
                viewModel.pendingMentionInsertion = nil
            }
        }

        // Sync plain text changes (only if no mention insertion just happened)
        if viewModel.pendingMentionInsertion == nil, textView.string != text {
            let shouldPlaceAtEnd = shouldMoveCursorToEnd
            let previousRanges = textView.selectedRanges
            textView.string = text

            if shouldPlaceAtEnd {
                let endPos = textView.string.utf16.count
                textView.setSelectedRange(NSRange(location: endPos, length: 0))
                DispatchQueue.main.async {
                    shouldMoveCursorToEnd = false
                }
            } else {
                let maxLocation = textView.string.utf16.count
                let safeRanges = previousRanges.compactMap { rangeValue -> NSValue? in
                    let range = rangeValue.rangeValue
                    if range.location <= maxLocation {
                        let safeLength = min(range.length, maxLocation - range.location)
                        return NSValue(range: NSRange(location: range.location, length: safeLength))
                    }
                    return nil
                }
                if !safeRanges.isEmpty {
                    textView.selectedRanges = safeRanges
                }
            }

            context.coordinator.recalculateHeight()
        }

        // Update autocomplete callbacks
        textView.onSubmit = onSubmit
        textView.onArrowUp = onArrowUp
        textView.onArrowDown = onArrowDown
        textView.onEscape = onEscape
        textView.isAutocompleteActive = isAutocompleteActive

        // Update placeholder visibility
        context.coordinator.updatePlaceholder()

        // Focus on demand
        if shouldFocus {
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
                shouldFocus = false
            }
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MultiLineTextView
        weak var textView: NSTextView?
        private var placeholderLabel: NSTextField?

        /// Tracks whether we're programmatically editing the text storage
        /// to prevent re-entrant textDidChange syncing.
        private var isInsertingMention = false

        init(_ parent: MultiLineTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // Skip syncing when we're inserting a mention programmatically
            guard !isInsertingMention else { return }

            parent.text = textView.string
            recalculateHeight()
            updatePlaceholder()
        }

        // MARK: - Mention Tag Insertion

        /// Replaces the "@query" text with a styled mention (bold + green).
        func insertMentionTag(_ item: AutocompleteItem, in textView: NSTextView) {
            guard let textStorage = textView.textStorage else { return }

            // Find the "@" and everything after it (the query) to replace
            let fullString = textStorage.string
            guard let atRange = fullString.range(of: "@", options: .backwards) else { return }

            // The range from "@" to the cursor position
            let atNSLocation = fullString.distance(from: fullString.startIndex, to: atRange.lowerBound)
            let cursorLocation = textView.selectedRange().location
            let replacementLength = cursorLocation - atNSLocation
            guard replacementLength > 0 else { return }

            let nsRange = NSRange(location: atNSLocation, length: replacementLength)

            // Build the styled mention attributed string
            let mentionString = MentionStyle.attributedString(for: item, font: parent.font)

            // Insert atomically
            isInsertingMention = true
            textStorage.beginEditing()
            textStorage.replaceCharacters(in: nsRange, with: mentionString)
            textStorage.endEditing()

            // Move cursor to after the inserted mention + trailing space
            let newCursorPos = atNSLocation + mentionString.length
            textView.setSelectedRange(NSRange(location: newCursorPos, length: 0))

            // Sync the plain text back
            parent.text = textView.string
            isInsertingMention = false

            recalculateHeight()
            updatePlaceholder()
        }

        /// Extracts the plain text from the text storage.
        /// Since mentions are now styled text (not attachments), the string is already readable.
        func extractReadableText() -> String {
            guard let textStorage = textView?.textStorage else {
                return parent.text
            }
            return textStorage.string
        }

        // MARK: - Layout

        func recalculateHeight() {
            guard let textView,
                  let container = textView.textContainer,
                  let layoutManager = textView.layoutManager
            else { return }

            layoutManager.ensureLayout(for: container)
            let usedRect = layoutManager.usedRect(for: container)
            let inset = textView.textContainerInset
            let contentHeight = usedRect.height + inset.height * 2

            let singleLineHeight = (parent.font.ascender - parent.font.descender + parent.font.leading) + inset
                .height * 2
            let minHeight = max(singleLineHeight, 22)
            let newHeight = min(max(contentHeight, minHeight), parent.maxHeight)

            let needsScroll = contentHeight > parent.maxHeight
            if let scrollView = textView.enclosingScrollView {
                scrollView.hasVerticalScroller = needsScroll
            }

            if abs(parent.dynamicHeight - newHeight) > 0.5 {
                DispatchQueue.main.async {
                    self.parent.dynamicHeight = newHeight
                }
            }
        }

        func updatePlaceholder() {
            guard let textView else { return }

            if placeholderLabel == nil {
                let label = NSTextField(labelWithString: parent.placeholder)
                label.font = parent.font
                label.textColor = parent.placeholderColor
                label.backgroundColor = .clear
                label.isBezeled = false
                label.isEditable = false
                label.isSelectable = false
                label.translatesAutoresizingMaskIntoConstraints = false
                textView.addSubview(label)

                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(
                        equalTo: textView.leadingAnchor,
                        constant: textView.textContainerInset.width + 5
                    ),
                    label.topAnchor.constraint(
                        equalTo: textView.topAnchor,
                        constant: textView.textContainerInset.height
                    ),
                ])

                placeholderLabel = label
            }

            placeholderLabel?.isHidden = !textView.string.isEmpty
        }
    }
}

// MARK: - SubmitTextView (Enter to submit, Shift+Enter for newline, atomic backspace for tags)

final class SubmitTextView: NSTextView {
    var onSubmit: (() -> Void)?
    var onArrowUp: (() -> Bool)?
    var onArrowDown: (() -> Bool)?
    var onEscape: (() -> Void)?
    var isAutocompleteActive: Bool = false

    override func keyDown(with event: NSEvent) {
        let keyCode = event.keyCode
        let isShiftPressed = event.modifierFlags.contains(.shift)

        // Escape key → dismiss autocomplete
        if keyCode == 53, isAutocompleteActive {
            onEscape?()
            return
        }

        // Arrow Up → navigate autocomplete (callback returns true if handled)
        if keyCode == 126, onArrowUp?() == true {
            return
        }

        // Arrow Down → navigate autocomplete (callback returns true if handled)
        if keyCode == 125, onArrowDown?() == true {
            return
        }

        // Backspace → atomic deletion of mention tags
        if keyCode == 51 {
            if deleteMentionTagBeforeCursor() {
                return
            }
        }

        // Enter without Shift → confirm autocomplete selection or submit
        if keyCode == 36, !isShiftPressed {
            if isAutocompleteActive {
                onSubmit?()
            } else {
                onSubmit?()
            }
            return
        }

        // Shift+Enter or any other key → default behavior (inserts newline for Shift+Enter)
        super.keyDown(with: event)
    }

    /// Checks if the character before the cursor is part of a mention (has `.mentionItem` attribute).
    /// If so, deletes the entire mention range atomically (including trailing space).
    /// Returns true if a mention was deleted.
    private func deleteMentionTagBeforeCursor() -> Bool {
        guard let textStorage else { return false }
        let cursorLocation = selectedRange().location
        guard cursorLocation > 0 else { return false }

        let checkIndex = cursorLocation - 1
        guard checkIndex < textStorage.length else { return false }

        // Check if the char before cursor has the mentionItem attribute
        var mentionRange = NSRange(location: 0, length: 0)
        let attrs = textStorage.attributes(at: checkIndex, effectiveRange: &mentionRange)

        var hasMention = attrs[.mentionItem] is AutocompleteItem

        // If not, check if we're on the trailing space right after a mention
        if !hasMention, checkIndex > 0 {
            let charBefore = (textStorage.string as NSString).substring(
                with: NSRange(location: checkIndex, length: 1)
            )
            if charBefore == " " {
                let prevAttrs = textStorage.attributes(at: checkIndex - 1, effectiveRange: &mentionRange)
                hasMention = prevAttrs[.mentionItem] is AutocompleteItem
            }
        }

        guard hasMention else { return false }

        // Expand the range to include the trailing space if present
        var deleteEnd = mentionRange.location + mentionRange.length
        if deleteEnd < textStorage.length {
            let nextChar = (textStorage.string as NSString).substring(
                with: NSRange(location: deleteEnd, length: 1)
            )
            if nextChar == " " {
                deleteEnd += 1
            }
        }

        let deleteRange = NSRange(location: mentionRange.location, length: deleteEnd - mentionRange.location)

        // Perform atomic deletion
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: deleteRange, with: "")
        textStorage.endEditing()

        // Update cursor
        setSelectedRange(NSRange(location: mentionRange.location, length: 0))

        // Notify delegate of text change
        delegate?.textDidChange?(Notification(name: NSText.didChangeNotification, object: self))

        return true
    }
}
