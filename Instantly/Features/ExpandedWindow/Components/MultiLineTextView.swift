import SwiftUI

/// A multi-line text input that grows with content, supports Shift+Enter for new lines,
/// and Enter to submit. Wraps NSTextView for precise key event handling.
struct MultiLineTextView: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var font: NSFont = .systemFont(ofSize: 14)
    var textColor: NSColor = .labelColor
    var placeholderColor: NSColor = .placeholderTextColor
    var maxHeight: CGFloat = 120
    var onSubmit: (() -> Void)?

    @Binding var dynamicHeight: CGFloat
    @Binding var shouldFocus: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false // Hidden until content reaches maxHeight
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.scrollerStyle = .overlay
        scrollView.scrollerKnobStyle = .light

        // Use thin scroller
        if let scroller = scrollView.verticalScroller {
            scroller.controlSize = .mini
        }

        let textView = SubmitTextView()
        textView.delegate = context.coordinator
        textView.onSubmit = onSubmit
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

        // Initial height calculation and auto-focus
        DispatchQueue.main.async {
            context.coordinator.recalculateHeight()
            textView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Prevent update loops
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            context.coordinator.recalculateHeight()
        }

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

        init(_ parent: MultiLineTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            recalculateHeight()
            updatePlaceholder()
        }

        func recalculateHeight() {
            guard let textView,
                  let container = textView.textContainer,
                  let layoutManager = textView.layoutManager
            else { return }

            layoutManager.ensureLayout(for: container)
            let usedRect = layoutManager.usedRect(for: container)
            let inset = textView.textContainerInset
            let contentHeight = usedRect.height + inset.height * 2

            // Single line height as minimum
            let singleLineHeight = (parent.font.ascender - parent.font.descender + parent.font.leading) + inset
                .height * 2
            let minHeight = max(singleLineHeight, 22)
            let newHeight = min(max(contentHeight, minHeight), parent.maxHeight)

            // Only show scrollbar when content exceeds maxHeight
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

// MARK: - SubmitTextView (Enter to submit, Shift+Enter for newline)

private final class SubmitTextView: NSTextView {
    var onSubmit: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        let isReturn = event.keyCode == 36
        let isShiftPressed = event.modifierFlags.contains(.shift)

        if isReturn, !isShiftPressed {
            // Enter without Shift → submit
            onSubmit?()
            return
        }

        // Shift+Enter or any other key → default behavior (inserts newline for Shift+Enter)
        super.keyDown(with: event)
    }
}
