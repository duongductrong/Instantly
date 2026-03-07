import SwiftUI

struct ExpandedWindowView: View {
    @Bindable var viewModel: ExpandedWindowViewModel
    @State private var newChatShortcutMonitor: Any?
    @State private var inputBarMinY: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            BodyView(viewModel: viewModel)
            ContextBarView(viewModel: viewModel)
            InputBarView(viewModel: viewModel)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                inputBarMinY = geo.frame(in: .named("expandedWindow")).minY
                            }
                            .onChange(of: geo.size.height) { _, _ in
                                inputBarMinY = geo.frame(in: .named("expandedWindow")).minY
                            }
                    }
                )
        }
        .coordinateSpace(name: "expandedWindow")
        .overlay {
            if viewModel.showAutocomplete {
                VStack {
                    Spacer()
                    AutocompletePopupView(
                        items: viewModel.filteredAutocompleteItems,
                        selectedIndex: viewModel.autocompleteSelectedIndex,
                        onSelect: { item in
                            viewModel.selectAutocompleteItem(item)
                        }
                    )
                    .padding(.horizontal, 12)
                }
                .frame(height: inputBarMinY - 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeOut(duration: 0.15), value: viewModel.filteredAutocompleteItems.count)
            }
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
