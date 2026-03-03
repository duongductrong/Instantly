import AppKit
import Carbon.HIToolbox
import SwiftUI

/// Central controller managing panel lifecycle, animation, hotkey, and interaction monitors.
@MainActor
final class PanelController {
    static let shared = PanelController()

    enum PanelState {
        case hidden, collapsed, expanded
    }

    private(set) var state: PanelState = .hidden
    private var panel: FloatingPanel?
    private let contentViewModel = PanelContentViewModel()
    let expandedViewModel = ExpandedWindowViewModel()

    // Event monitors
    private var mouseMonitor: Any?
    private var escMonitor: Any?
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyHandlerRef: EventHandlerRef?
    private var hasRequestedAXPermission = false
    private var activeHotkeyBinding: HotkeyBinding?

    private init() {}

    // MARK: - Hotkey Registration (Carbon API)

    func setupHotkey() {
        installHotKeyHandlerIfNeeded()

        let desiredBinding = SettingsService.shared.settings.system.globalHotkey
        if registerHotKey(desiredBinding) {
            activeHotkeyBinding = desiredBinding
            return
        }

        if let activeHotkeyBinding, registerHotKey(activeHotkeyBinding) {
            return
        }

        let fallback = AppSettings.defaultValue.system.globalHotkey
        if registerHotKey(fallback) {
            activeHotkeyBinding = fallback
            SettingsService.shared.updateSystem { $0.globalHotkey = fallback }
        }
    }

    // MARK: - Panel Lifecycle

    func show() {
        guard panel == nil else {
            panel?.orderFront(nil)
            state = .collapsed
            return
        }

        let view = PanelContentView(viewModel: contentViewModel)
        let newPanel = FloatingPanel(contentView: view)

        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let pillSize = CGSize(width: DesignTokens.pillWidth, height: DesignTokens.pillHeight)
        let origin = ScreenPositionService.pillOrigin(screen: screen, pillSize: pillSize)
        let frame = NSRect(origin: origin, size: pillSize)

        newPanel.setFrame(frame, display: true)
        newPanel.updateCornerRadius(DesignTokens.pillCornerRadius)
        newPanel.orderFront(nil)

        panel = newPanel
        state = .collapsed
        contentViewModel.isExpanded = false
        contentViewModel.showContent = false
    }

    func hide() {
        stopMouseMonitor()
        stopEscMonitor()
        expandedViewModel.clearContext()
        expandedViewModel.resetExpandedWidth()
        contentViewModel.isExpanded = false
        contentViewModel.showContent = false
        panel?.orderOut(nil)
        state = .hidden
    }

    func toggle() {
        switch state {
        case .hidden:
            show()
            expand()
        case .collapsed:
            expand()
        case .expanded:
            collapse()
        }
    }

    // MARK: - Expand / Collapse

    func expand() {
        guard state == .collapsed, let panel else { return }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        // Hotkey path injects context before toggle(); manual open does not.
        // Capture here only when empty so we don't overwrite hotkey-captured context.
        if expandedViewModel.contextItems.isEmpty {
            expandedViewModel.setContext(ActiveAppContextService.captureContext())
        }

        let expandedSize = currentExpandedSize()
        let expandedOrigin = ScreenPositionService.expandedOrigin(
            screen: screen,
            expandedSize: expandedSize
        )
        let expandedFrame = NSRect(origin: expandedOrigin, size: expandedSize)

        panel.animateFrame(
            to: expandedFrame,
            cornerRadius: DesignTokens.panelCornerRadius,
            duration: DesignTokens.slideUpDuration
        )

        contentViewModel.expand()
        state = .expanded
        panel.makeKeyAndOrderFront(nil)

        startMouseMonitor()
        startEscMonitor()
    }

    func toggleExpandedWidth() {
        guard state == .expanded, let panel else { return }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        expandedViewModel.toggleExpandedWidth()

        let expandedSize = currentExpandedSize()
        let expandedOrigin = ScreenPositionService.expandedOrigin(
            screen: screen,
            expandedSize: expandedSize
        )

        panel.animateFrame(
            to: NSRect(origin: expandedOrigin, size: expandedSize),
            cornerRadius: DesignTokens.panelCornerRadius,
            duration: 0.2
        )
    }

    func collapse() {
        guard state == .expanded, let panel else { return }
        stopMouseMonitor()
        stopEscMonitor()

        contentViewModel.collapse()
        expandedViewModel.clearContext()

        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let pillSize = CGSize(width: DesignTokens.pillWidth, height: DesignTokens.pillHeight)
        let pillOrigin = ScreenPositionService.pillOrigin(screen: screen, pillSize: pillSize)
        let pillFrame = NSRect(origin: pillOrigin, size: pillSize)

        DispatchQueue.main.asyncAfter(deadline: .now() + DesignTokens.collapseContentDuration) {
            panel.animateFrame(
                to: pillFrame,
                cornerRadius: DesignTokens.pillCornerRadius,
                duration: DesignTokens.slideDownDuration
            )
        }

        state = .collapsed
    }

    // MARK: - Event Monitors

    private func startMouseMonitor() {
        guard mouseMonitor == nil else { return }
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.state == .expanded, let panel = self.panel else { return }
                if !panel.frame.contains(NSEvent.mouseLocation) {
                    self.collapse()
                }
            }
        }
    }

    private func stopMouseMonitor() {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
    }

    private func startEscMonitor() {
        guard escMonitor == nil else { return }
        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                DispatchQueue.main.async { self?.collapse() }
                return nil
            }
            return event
        }
    }

    private func stopEscMonitor() {
        if let monitor = escMonitor {
            NSEvent.removeMonitor(monitor)
            escMonitor = nil
        }
    }

    private func installHotKeyHandlerIfNeeded() {
        guard hotKeyHandlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ -> OSStatus in
                // Carbon hotkey callbacks run on the main run loop on macOS.
                assert(Thread.isMainThread, "Carbon hotkey callback must run on main thread")
                PanelController.shared.handleHotKeyPressed()
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

    private func registerHotKey(_ binding: HotkeyBinding) -> Bool {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        guard binding.isValid else { return false }

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x494E_5354) // "INST"
        hotKeyID.id = 1

        let status = RegisterEventHotKey(
            binding.keyCode,
            binding.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        return status == noErr
    }

    private func handleHotKeyPressed() {
        // Capture context SYNCHRONOUSLY before panel steals frontmost status.
        let contextItems = ActiveAppContextService.captureContext()
        Task { @MainActor in
            let controller = PanelController.shared
            // Request AX permission once on first hotkey press.
            if !controller.hasRequestedAXPermission {
                controller.hasRequestedAXPermission = true
                ActiveAppContextService.requestAccessibilityPermission()
            }
            controller.expandedViewModel.setContext(contextItems)
            controller.toggle()
        }
    }

    // MARK: - Screen Change Observer

    func observeScreenChanges() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reposition()
        }
    }

    private func reposition() {
        guard let panel, state != .hidden else { return }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        if state == .collapsed {
            let pillSize = CGSize(width: DesignTokens.pillWidth, height: DesignTokens.pillHeight)
            let origin = ScreenPositionService.pillOrigin(screen: screen, pillSize: pillSize)
            panel.setFrame(NSRect(origin: origin, size: pillSize), display: true)
        } else {
            let expandedSize = currentExpandedSize()
            let expandedOrigin = ScreenPositionService.expandedOrigin(
                screen: screen,
                expandedSize: expandedSize
            )
            panel.setFrame(NSRect(origin: expandedOrigin, size: expandedSize), display: true)
        }
    }

    private func currentExpandedSize() -> CGSize {
        CGSize(
            width: expandedViewModel.expandedWidth,
            height: DesignTokens.expandedHeight
        )
    }
}
