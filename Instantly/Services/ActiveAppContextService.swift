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

        // Selected text chip (AX first, clipboard fallback for Electron apps like VSCode)
        if isAccessibilityGranted() {
            let text = selectedText(from: app.processIdentifier) ?? selectedTextViaClipboard()
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
        guard pid > 0 else { return nil }
        let appElement = AXUIElementCreateApplication(pid)

        var focusedElement: AnyObject?
        guard AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        ) == .success
        else { return nil }

        // swiftlint:disable:next force_cast
        let element = focusedElement as! AXUIElement

        var selectedValue: AnyObject?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedValue
        ) == .success
        else { return nil }

        return selectedValue as? String
    }

    // MARK: - Selected Text via Clipboard (fallback for Electron apps)

    /// Simulates Cmd+C to copy selected text, reads the clipboard, then restores original contents.
    /// Used as fallback when AX `kAXSelectedTextAttribute` isn't supported (e.g. VSCode, Slack).
    static func selectedTextViaClipboard() -> String? {
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount

        // Save current clipboard contents
        let backup = pasteboard.pasteboardItems?.compactMap { item -> (String, Data)? in
            guard let type = item.types.first,
                  let data = item.data(forType: type)
            else { return nil }
            return (type.rawValue, data)
        }

        // Clear clipboard so we can detect if Cmd+C actually wrote something
        pasteboard.clearContents()

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

        // Brief wait for the target app to process the copy command
        usleep(50_000) // 50ms

        // Read the result — only if clipboard actually changed
        let copiedText: String? = if pasteboard.changeCount != changeCount {
            pasteboard.string(forType: .string)
        } else {
            nil
        }

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
}
