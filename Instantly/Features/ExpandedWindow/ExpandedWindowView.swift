import SwiftUI

struct ExpandedWindowView: View {
    @Bindable var viewModel: ExpandedWindowViewModel
    @State private var newChatShortcutMonitor: Any?

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            BodyView(viewModel: viewModel)
            ContextBarView(viewModel: viewModel)
            InputBarView(viewModel: viewModel)
        }
        .frame(
            width: viewModel.expandedWidth,
            height: DesignTokens.expandedHeight
        )
        .preferredColorScheme(
            SettingsService.shared.settings.system.appearanceMode.resolvedColorScheme
        )
        .onAppear {
            installNewChatShortcutMonitor()
        }
        .onDisappear {
            removeNewChatShortcutMonitor()
        }
    }

    private func installNewChatShortcutMonitor() {
        removeNewChatShortcutMonitor()

        newChatShortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let shortcut = SettingsService.shared.settings.assistant.newChatShortcut
            guard matches(event: event, with: shortcut) else {
                return event
            }

            viewModel.clearConversation()
            return nil
        }
    }

    private func removeNewChatShortcutMonitor() {
        if let newChatShortcutMonitor {
            NSEvent.removeMonitor(newChatShortcutMonitor)
            self.newChatShortcutMonitor = nil
        }
    }

    private func matches(event: NSEvent, with shortcut: HotkeyBinding) -> Bool {
        guard UInt32(event.keyCode) == shortcut.keyCode else { return false }
        let eventModifiers = HotkeyBinding.carbonModifiers(
            from: event.modifierFlags.intersection([.command, .shift, .option, .control])
        )
        return eventModifiers == shortcut.carbonModifiers
    }
}
