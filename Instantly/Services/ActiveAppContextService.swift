import AppKit
import ApplicationServices

struct ContextItem: Identifiable, Equatable {
    let id = UUID()
    let type: ContextType
    let label: String
    let rawValue: String?
    let icon: NSImage?
    let bundleIdentifier: String?

    enum ContextType {
        case activeApp
        case selectedText
    }

    /// Identity-based equality — each capture is a distinct snapshot
    static func == (lhs: ContextItem, rhs: ContextItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum ActiveAppContextService {
    /// Capture all available context from the current frontmost app.
    /// MUST be called BEFORE our panel takes focus.
    static func captureContext() -> [ContextItem] {
        var items: [ContextItem] = []

        guard let app = NSWorkspace.shared.frontmostApplication else { return items }

        // Active app chip
        if let name = app.localizedName {
            items.append(ContextItem(
                type: .activeApp,
                label: name,
                rawValue: nil,
                icon: app.icon,
                bundleIdentifier: app.bundleIdentifier
            ))
        }

        // Selected text chip (AX first, clipboard fallback only when a selection exists)
        if isAccessibilityGranted() {
            let pid = app.processIdentifier
            let axSelectedText = selectedText(from: pid)
            let shouldTryClipboardFallback = (axSelectedText?.isEmpty ?? true)
                && hasNonEmptySelection(from: pid)
            let text: String? = if let axSelectedText, !axSelectedText.isEmpty {
                axSelectedText
            } else if shouldTryClipboardFallback {
                selectedTextViaClipboard()
            } else {
                nil
            }
            if let text, !text.isEmpty {
                let truncated = text.count > 80
                    ? String(text.prefix(77)) + "..."
                    : text
                items.append(ContextItem(
                    type: .selectedText,
                    label: truncated,
                    rawValue: text,
                    icon: nil,
                    bundleIdentifier: app.bundleIdentifier
                ))
            }
        }

        return items
    }

    // MARK: - Accessibility

    static func isAccessibilityGranted() -> Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibilityPermission() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(opts as CFDictionary)
    }

    // MARK: - Selected Text via AXUIElement

    static func selectedText(from pid: pid_t) -> String? {
        guard let element = focusedElement(from: pid) else { return nil }

        var selectedValue: AnyObject?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedValue
        ) == .success
        else { return nil }

        return selectedValue as? String
    }

    static func hasNonEmptySelection(from pid: pid_t) -> Bool {
        guard let element = focusedElement(from: pid) else { return false }

        if let range = rangeValue(from: element, attribute: kAXSelectedTextRangeAttribute as CFString) {
            return range.length > 0
        }

        var selectedRangesValue: AnyObject?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangesAttribute as CFString,
            &selectedRangesValue
        ) == .success,
            let selectedRanges = selectedRangesValue as? [AnyObject]
        else { return false }

        for value in selectedRanges {
            if let range = rangeValue(from: value), range.length > 0 {
                return true
            }
        }

        return false
    }

    // MARK: - Selected Text via Clipboard (fallback for Electron apps)

    /// Simulates Cmd+C to copy selected text, reads the clipboard, then restores original contents.
    /// Used as fallback when AX `kAXSelectedTextAttribute` isn't supported (e.g. VSCode, Slack).
    static func selectedTextViaClipboard() -> String? {
        let pasteboard = NSPasteboard.general

        // Save current clipboard contents
        let backup = pasteboard.pasteboardItems?.compactMap { item -> (String, Data)? in
            guard let type = item.types.first,
                  let data = item.data(forType: type)
            else { return nil }
            return (type.rawValue, data)
        }

        // Clear clipboard so we can detect if Cmd+C actually wrote something
        pasteboard.clearContents()
        let baselineChangeCount = pasteboard.changeCount

        // Simulate Cmd+C via CGEvent
        let source = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        else {
            restoreClipboard(backup: backup)
            return nil
        }
        keyDown.flags = CGEventFlags.maskCommand
        keyUp.flags = CGEventFlags.maskCommand
        keyDown.post(tap: CGEventTapLocation.cghidEventTap)
        keyUp.post(tap: CGEventTapLocation.cghidEventTap)

        let copiedText = waitForCopiedText(
            on: pasteboard,
            baselineChangeCount: baselineChangeCount
        )

        // Restore original clipboard contents
        restoreClipboard(backup: backup)

        return copiedText
    }

    private static func restoreClipboard(backup: [(String, Data)]?) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard let backup, !backup.isEmpty else { return }
        for (typeRaw, data) in backup {
            pasteboard.setData(data, forType: NSPasteboard.PasteboardType(typeRaw))
        }
    }

    private static func waitForCopiedText(on pasteboard: NSPasteboard, baselineChangeCount: Int)
        -> String?
    {
        for _ in 0 ..< 30 {
            if pasteboard.changeCount != baselineChangeCount {
                return pasteboard.string(forType: .string)
            }
            usleep(10_000) // 10ms
        }
        return nil
    }

    private static func rangeValue(from element: AXUIElement, attribute: CFString) -> CFRange? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let value
        else { return nil }
        return rangeValue(from: value)
    }

    private static func rangeValue(from value: AnyObject) -> CFRange? {
        guard CFGetTypeID(value) == AXValueGetTypeID() else { return nil }

        let axValue = unsafeBitCast(value, to: AXValue.self)
        guard AXValueGetType(axValue) == .cfRange else { return nil }

        var range = CFRange()
        guard AXValueGetValue(axValue, .cfRange, &range) else { return nil }
        return range
    }

    private static func focusedElement(from pid: pid_t) -> AXUIElement? {
        guard pid > 0 else { return nil }

        let appElement = AXUIElementCreateApplication(pid)
        var focusedElement: AnyObject?
        guard AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        ) == .success,
            let element = focusedElement
        else { return nil }

        guard CFGetTypeID(element) == AXUIElementGetTypeID() else { return nil }

        return unsafeBitCast(element, to: AXUIElement.self)
    }
}
