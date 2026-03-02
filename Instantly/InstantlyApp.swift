import SwiftUI

@main
struct InstantlyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible windows — panel managed by PanelController
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        PanelController.shared.setupHotkey()
        PanelController.shared.observeScreenChanges()
        PanelController.shared.show()
    }
}
