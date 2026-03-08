import AppKit
import Carbon.HIToolbox
import SwiftUI

/// Manages the ⌘E floating toolbar panel: hotkey registration, positioning at cursor, and action dispatch.
@MainActor
final class QuickToolbarController {
    static let shared = QuickToolbarController()

    private var panel: FloatingPanel?
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyHandlerRef: EventHandlerRef?
    private var clickMonitor: Any?
    private var capturedContext: [ContextItem] = []
    private var inlineViewModel: InlineResultViewModel?
    private var lastSourceApp: NSRunningApplication?
    private var lastMouseLocation: NSPoint = .zero

    // Keyboard-navigation state for the toolbar
    private var currentActions: [QuickToolbarAction] = []
    private var selectedIndex: Int = 0

    private init() {}

    // MARK: - Hotkey Registration (Carbon API)

    func setupHotkey() {
        installHotKeyHandler()
        registerHotKey()
    }

    // MARK: - Show / Hide

    func show(at mouseLocation: NSPoint) {
        // Capture context BEFORE our panel steals focus
        lastSourceApp = NSWorkspace.shared.frontmostApplication
        capturedContext = ActiveAppContextService.captureContext()
        lastMouseLocation = mouseLocation

        let actions = QuickToolbarAction.builtInActions
        currentActions = actions
        selectedIndex = 0

        let toolbarView = QuickToolbarView(
            actions: actions,
            selectedIndex: selectedIndex,
            onAction: { [weak self] action in
                self?.handleAction(action)
            },
            onDismiss: { [weak self] in
                self?.hide()
            }
        )

        let rowCount = CGFloat(actions.count)
        let estimatedHeight = (rowCount * DesignTokens.toolbarRowHeight) + 12 // 6pt padding top + bottom
        let toolbarSize = CGSize(width: DesignTokens.toolbarWidth, height: estimatedHeight)

        // Position: just below the mouse cursor, clamped to screen
        let origin = clampedOrigin(for: toolbarSize, near: mouseLocation)

        if let panel {
            // Reuse existing panel
            let hostingView = NSHostingView(rootView: AnyView(toolbarView.ignoresSafeArea()))
            panel.contentView = hostingView
            panel.contentView?.wantsLayer = true
            panel.contentView?.layer?.cornerRadius = DesignTokens.toolbarCornerRadius
            panel.contentView?.layer?.masksToBounds = true
            panel.setFrame(NSRect(origin: origin, size: toolbarSize), display: true)
            panel.makeKeyAndOrderFront(nil)
        } else {
            let newPanel = FloatingPanel(contentView: toolbarView)
            newPanel.setFrame(NSRect(origin: origin, size: toolbarSize), display: true)
            newPanel.updateCornerRadius(DesignTokens.toolbarCornerRadius)
            newPanel.makeKeyAndOrderFront(nil)
            panel = newPanel
        }

        startClickMonitor()
        startKeyMonitor()
    }

    func hide() {
        stopClickMonitor()
        stopKeyMonitor()
        inlineViewModel?.cancel()
        inlineViewModel = nil
        panel?.orderOut(nil)
        capturedContext = []
        currentActions = []
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    // MARK: - Action Dispatch

    private func handleAction(_ action: QuickToolbarAction) {
        if action.isInlineAction {
            handleInlineAction(action)
        } else {
            handleExpandWindowAction(action)
        }
    }

    private func handleExpandWindowAction(_ action: QuickToolbarAction) {
        let context = capturedContext
        hide()

        // Open the Expanded Window with context + action prompt pre-injected
        let controller = PanelController.shared
        let vm = controller.expandedViewModel
        vm.setContext(context)
        vm.queryText = action.prompt + " "
        vm.shouldMoveCursorToEnd = true

        // Ensure the panel is shown and expanded
        if controller.state == .hidden {
            controller.show()
        }
        if controller.state != .expanded {
            controller.expand()
        }

        // Auto-submit after a short delay so the panel is fully ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            vm.sendMessage()
        }
    }

    private func handleInlineAction(_ action: QuickToolbarAction) {
        // Get the selected text from context
        guard let selectedTextItem = capturedContext.first(where: { $0.type == .selectedText }),
              let selectedText = selectedTextItem.rawValue, !selectedText.isEmpty
        else {
            // No selected text — dismiss
            hide()
            return
        }

        let vm = InlineResultViewModel()
        inlineViewModel = vm

        // Transform the toolbar into the inline result bubble
        showInlineBubble(viewModel: vm)

        // Start watching for Tab / Esc keys
        startKeyMonitor()

        // Start streaming the LLM result
        vm.run(action: action, selectedText: selectedText, sourceApp: lastSourceApp)
    }

    private func showInlineBubble(viewModel: InlineResultViewModel) {
        let bubbleView = InlineResultBubbleView(
            viewModel: viewModel,
            onDismiss: { [weak self] in
                self?.hide()
            },
            onApply: { [weak self] in
                self?.handleApplyInlineResult()
            }
        )

        // Use a generous container size — the panel is transparent so only the
        // SwiftUI bubble (with its own background + clipShape) is visible.
        let containerSize = CGSize(
            width: DesignTokens.inlineBubbleMaxWidth + 120,
            height: 280
        )
        let origin = clampedOrigin(for: containerSize, near: lastMouseLocation)

        guard let panel else { return }

        let hostingView = NSHostingView(rootView: AnyView(bubbleView.ignoresSafeArea()))
        panel.contentView = hostingView
        panel.contentView?.wantsLayer = true
        // Do NOT set cornerRadius or masksToBounds — the SwiftUI view handles
        // its own clipping and shadows. The panel is just a transparent container.
        panel.contentView?.layer?.cornerRadius = 0
        panel.contentView?.layer?.masksToBounds = false
        panel.setFrame(NSRect(origin: origin, size: containerSize), display: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func handleApplyInlineResult() {
        guard let vm = inlineViewModel else { return }
        vm.applyResult()
        hide()
    }

    // MARK: - Key Monitor

    private var keyMonitor: Any?

    private func startKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            // --- Inline-result mode: Tab to apply, Esc to dismiss ---
            if inlineViewModel != nil {
                // Tab key (keyCode 48) — apply result
                if event.keyCode == 48 {
                    if let vm = inlineViewModel, !vm.isLoading, !vm.resultText.isEmpty {
                        DispatchQueue.main.async { self.handleApplyInlineResult() }
                        return nil
                    }
                }
                // Esc key (keyCode 53) — dismiss
                if event.keyCode == 53 {
                    DispatchQueue.main.async { self.hide() }
                    return nil
                }
                return event
            }

            // --- Toolbar mode: arrow navigation, enter, esc ---
            switch event.keyCode {
            case 126: // Up Arrow
                moveSelection(by: -1)
                return nil
            case 125: // Down Arrow
                moveSelection(by: 1)
                return nil
            case 36: // Return / Enter
                let idx = selectedIndex
                if idx >= 0, idx < currentActions.count, !currentActions[idx].isDisabled {
                    DispatchQueue.main.async { self.handleAction(self.currentActions[idx]) }
                }
                return nil
            case 53: // Escape
                DispatchQueue.main.async { self.hide() }
                return nil
            default:
                return event
            }
        }
    }

    private func stopKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    // MARK: - Keyboard Selection

    private func moveSelection(by delta: Int) {
        let count = currentActions.count
        guard count > 0 else { return }
        var next = (selectedIndex + delta + count) % count
        // Skip disabled actions
        let start = next
        while currentActions[next].isDisabled {
            next = (next + delta + count) % count
            if next == start { break }
        }
        selectedIndex = next
        refreshToolbarView()
    }

    private func refreshToolbarView() {
        guard panel?.isVisible == true, inlineViewModel == nil else { return }

        let toolbarView = QuickToolbarView(
            actions: currentActions,
            selectedIndex: selectedIndex,
            onAction: { [weak self] action in
                self?.handleAction(action)
            },
            onDismiss: { [weak self] in
                self?.hide()
            }
        )

        let hostingView = NSHostingView(rootView: AnyView(toolbarView.ignoresSafeArea()))
        panel?.contentView = hostingView
        panel?.contentView?.wantsLayer = true
        panel?.contentView?.layer?.cornerRadius = DesignTokens.toolbarCornerRadius
        panel?.contentView?.layer?.masksToBounds = true
    }

    // MARK: - Positioning

    private func clampedOrigin(for size: CGSize, near mouseLocation: NSPoint) -> NSPoint {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
            ?? NSScreen.main
            ?? NSScreen.screens.first
        else {
            return NSPoint(x: mouseLocation.x, y: mouseLocation.y - size.height - DesignTokens.toolbarVerticalOffset)
        }

        let visibleFrame = screen.visibleFrame

        // Place below cursor (macOS coordinates: y increases upward)
        var x = mouseLocation.x - size.width / 2
        var y = mouseLocation.y - size.height - DesignTokens.toolbarVerticalOffset

        // Clamp horizontally
        x = max(visibleFrame.minX + 4, min(x, visibleFrame.maxX - size.width - 4))

        // Clamp vertically — if toolbar would go below screen, place it above the cursor instead
        if y < visibleFrame.minY + 4 {
            y = mouseLocation.y + DesignTokens.toolbarVerticalOffset + 20 // 20 ≈ cursor height
        }
        y = min(y, visibleFrame.maxY - size.height - 4)

        return NSPoint(x: x, y: y)
    }

    // MARK: - Click-Outside Monitor

    private func startClickMonitor() {
        guard clickMonitor == nil else { return }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, let panel = self.panel, panel.isVisible else { return }
                if !panel.frame.contains(NSEvent.mouseLocation) {
                    self.hide()
                }
            }
        }
    }

    private func stopClickMonitor() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    // MARK: - Carbon Hotkey

    private func installHotKeyHandler() {
        guard hotKeyHandlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                // Check the hotkey ID to distinguish from PanelController's hotkey
                var hotKeyID = EventHotKeyID()
                let result = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard result == noErr else { return noErr }

                // Only handle our own hotkey (signature "INTB")
                let expectedSignature = OSType(0x494E_5442) // "INTB"
                guard hotKeyID.signature == expectedSignature, hotKeyID.id == 1 else {
                    return OSStatus(eventNotHandledErr)
                }

                assert(Thread.isMainThread)
                QuickToolbarController.shared.handleHotKeyPressed()
                return noErr
            },
            1,
            &eventType,
            nil,
            &hotKeyHandlerRef
        )

        if status != noErr {
            hotKeyHandlerRef = nil
        }
    }

    private func registerHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x494E_5442) // "INTB" — distinct from PanelController's "INST"
        hotKeyID.id = 1

        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_E),
            UInt32(cmdKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            hotKeyRef = nil
        }
    }

    private func handleHotKeyPressed() {
        if isVisible {
            hide()
        } else {
            show(at: NSEvent.mouseLocation)
        }
    }
}
