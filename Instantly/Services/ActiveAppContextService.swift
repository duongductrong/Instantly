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

        // Selected text chip (AX first, clipboard fallback for Electron/non-AX apps)
        if isAccessibilityGranted() {
            let pid = app.processIdentifier
            let axSelectedText = selectedText(from: pid)
            let axFailed = (axSelectedText?.isEmpty ?? true)
            let isElectronLike = requiresClipboardFallback(bundleID: app.bundleIdentifier)
            let shouldTryClipboardFallback = axFailed
                && (isElectronLike || hasNonEmptySelection(from: pid))
            let text: String? = if let axSelectedText, !axSelectedText.isEmpty {
                axSelectedText
            } else if shouldTryClipboardFallback {
                selectedTextViaClipboard(forBundleID: app.bundleIdentifier, pid: pid)
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

    // MARK: - Electron / Non-AX App Detection

    /// Known bundle identifiers for apps that don't support AX selected text attributes.
    /// These apps require the clipboard fallback (Cmd+C simulation) to capture selected text.
    private static let clipboardFallbackBundleIDs: Set<String> = [
        "com.microsoft.VSCode",
        "com.microsoft.VSCodeInsiders",
        "com.visualstudio.code.oss", // VSCodium
        "com.slack.Slack",
        "com.discord.Discord",
        "com.spotify.client",
        "com.brave.Browser",
    ]

    private static func requiresClipboardFallback(bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return clipboardFallbackBundleIDs.contains(bundleID)
    }

    /// Detect whether the focused AX element is a terminal pane.
    /// VSCode terminals use Cmd+Shift+C for copy instead of Cmd+C.
    private static func isFocusedElementTerminal(pid: pid_t) -> Bool {
        guard let element = focusedElement(from: pid) else { return false }

        var roleValue: AnyObject?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXRoleAttribute as CFString,
            &roleValue
        ) == .success,
            let role = roleValue as? String
        else { return false }

        // Check role and role description for terminal indicators
        if role == "AXGroup" || role == "AXTextArea" {
            var descriptionValue: AnyObject?
            if AXUIElementCopyAttributeValue(
                element,
                kAXRoleDescriptionAttribute as CFString,
                &descriptionValue
            ) == .success,
                let desc = descriptionValue as? String
            {
                let lowered = desc.lowercased()
                if lowered.contains("terminal") || lowered.contains("xterm") {
                    return true
                }
            }

            // Also check the AX description/title for terminal hints
            var titleValue: AnyObject?
            if AXUIElementCopyAttributeValue(
                element,
                kAXDescriptionAttribute as CFString,
                &titleValue
            ) == .success,
                let title = titleValue as? String
            {
                let lowered = title.lowercased()
                if lowered.contains("terminal") || lowered.contains("xterm") {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Selected Text via Clipboard (fallback for Electron apps)

    /// Simulates Cmd+C (or Cmd+Shift+C for terminals) to copy selected text,
    /// reads the clipboard, then restores original contents.
    /// Used as fallback when AX `kAXSelectedTextAttribute` isn't supported (e.g. VSCode, Slack).
    static func selectedTextViaClipboard(forBundleID bundleID: String? = nil, pid: pid_t = 0) -> String? {
        let pasteboard = NSPasteboard.general

        // Save ALL clipboard contents (all types per item) for faithful restore
        let backup: [[(String, Data)]] = pasteboard.pasteboardItems?.map { item in
            item.types.compactMap { type in
                guard let data = item.data(forType: type) else { return nil }
                return (type.rawValue, data)
            }
        } ?? []

        // Clear clipboard so we can detect if the copy actually wrote something
        pasteboard.clearContents()
        let baselineChangeCount = pasteboard.changeCount

        // Determine whether to use Cmd+Shift+C (terminal) or Cmd+C (editor)
        let useShiftModifier = requiresClipboardFallback(bundleID: bundleID)
            && pid > 0
            && isFocusedElementTerminal(pid: pid)

        // Simulate the copy keystroke via CGEvent
        let source = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        else {
            restoreClipboard(backup: backup)
            return nil
        }

        var flags: CGEventFlags = .maskCommand
        if useShiftModifier {
            flags.insert(.maskShift)
        }
        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.post(tap: CGEventTapLocation.cghidEventTap)
        keyUp.post(tap: CGEventTapLocation.cghidEventTap)

        // Electron apps can be slower to handle copy — use longer wait
        let maxAttempts = requiresClipboardFallback(bundleID: bundleID) ? 50 : 30
        let copiedText = waitForCopiedText(
            on: pasteboard,
            baselineChangeCount: baselineChangeCount,
            maxAttempts: maxAttempts
        )

        // Restore original clipboard contents
        restoreClipboard(backup: backup)

        return copiedText
    }

    private static func restoreClipboard(backup: [[(String, Data)]]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard !backup.isEmpty else { return }
        for itemTypes in backup {
            guard !itemTypes.isEmpty else { continue }
            let pasteboardItem = NSPasteboardItem()
            for (typeRaw, data) in itemTypes {
                pasteboardItem.setData(data, forType: NSPasteboard.PasteboardType(typeRaw))
            }
            pasteboard.writeObjects([pasteboardItem])
        }
    }

    private static func waitForCopiedText(
        on pasteboard: NSPasteboard,
        baselineChangeCount: Int,
        maxAttempts: Int = 30
    )
        -> String?
    {
        for _ in 0 ..< maxAttempts {
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
