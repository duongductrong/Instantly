import SwiftUI

@main
struct InstantlyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible windows — panel managed by PanelController
        Settings {
            SettingsView()
                .frame(minWidth: 600, minHeight: 400)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        _ = SettingsService.shared

        PanelController.shared.setupHotkey()
        PanelController.shared.observeScreenChanges()

        if SettingsService.shared.settings.system.showPanelOnAppLaunch {
            PanelController.shared.show()
        }
    }
}
