import AppKit
import SwiftUI

/// Controller that manages the onboarding window lifecycle.
@MainActor
final class OnboardingWindowController {
    static let shared = OnboardingWindowController()

    private var window: NSWindow?

    private init() {}

    /// Shows the onboarding window. Calls `onComplete` when the user finishes.
    func showOnboarding(onComplete: @escaping () -> Void) {
        guard window == nil else { return }

        // Hide the panel and close other windows
        PanelController.shared.hide()
        for window in NSApp.windows {
            window.close()
        }

        let onboardingView = OnboardingView()
        onboardingView.viewModel.onComplete = { [weak self] in
            self?.dismiss()
            onComplete()
        }

        let hostingView = NSHostingView(rootView: onboardingView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        newWindow.contentView = hostingView
        newWindow.titlebarAppearsTransparent = true
        newWindow.titleVisibility = .hidden
        newWindow.toolbar = nil
        newWindow.isMovableByWindowBackground = true
        // newWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        // newWindow.standardWindowButton(.zoomButton)?.isHidden = true
        newWindow.center()
        newWindow.isReleasedWhenClosed = false

        // Apply appearance
        let mode = SettingsService.shared.settings.system.appearanceMode
        newWindow.appearance = mode.resolvedAppearance

        window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func dismiss() {
        window?.close()
        window = nil
    }
}
