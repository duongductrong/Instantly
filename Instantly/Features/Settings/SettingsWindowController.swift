import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private init() {}

    func open() {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.titlebarAppearsTransparent = true
        newWindow.titleVisibility = .hidden
        newWindow.toolbarStyle = .unifiedCompact
        newWindow.contentView = hostingView
        newWindow.minSize = NSSize(width: 700, height: 500)
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = WindowCloseDelegate.shared

        newWindow.appearance = SettingsService.shared.settings.system.appearanceMode.resolvedAppearance

        window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    fileprivate func handleWindowClosed(_ closedWindow: NSWindow) {
        if closedWindow === window {
            window = nil
        }
    }
}

// MARK: - Window Close Delegate

private final class WindowCloseDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowCloseDelegate()

    func windowWillClose(_ notification: Notification) {
        guard let closedWindow = notification.object as? NSWindow else { return }
        Task { @MainActor in
            SettingsWindowController.shared.handleWindowClosed(closedWindow)
        }
    }
}
