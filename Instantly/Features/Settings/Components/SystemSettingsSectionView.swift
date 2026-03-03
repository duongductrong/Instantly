import SwiftUI

struct SystemSettingsSectionView: View {
    let settings: SystemSettings
    let statusMessage: String
    let keychainMessage: String
    let onLaunchAtLoginChanged: (Bool) -> Void
    let onGlobalHotkeyChanged: (HotkeyBinding) -> Void
    let onShowPanelOnAppLaunchChanged: (Bool) -> Void
    let onResetAll: () -> Void

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: onLaunchAtLoginChanged
                ))

                Toggle("Show panel on app launch", isOn: Binding(
                    get: { settings.showPanelOnAppLaunch },
                    set: onShowPanelOnAppLaunchChanged
                ))
            }

            Section("Keyboard") {
                ShortcutRecorderField(
                    title: "Global Hotkey",
                    subtitle: "Applies instantly when changed.",
                    shortcut: Binding(
                        get: { settings.globalHotkey },
                        set: onGlobalHotkeyChanged
                    )
                )
            }

            Section {
                Button("Reset All Settings", role: .destructive) {
                    onResetAll()
                }
            }

            if !statusMessage.isEmpty {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }
            }

            if !keychainMessage.isEmpty {
                Section {
                    Text(keychainMessage)
                        .foregroundStyle(.red.opacity(0.9))
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}
