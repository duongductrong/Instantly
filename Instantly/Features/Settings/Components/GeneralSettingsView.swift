import SwiftUI

struct GeneralSettingsView: View {
    private let settingsService = SettingsService.shared

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Keyboard shortcut")
                    Spacer()
                    HotkeyRecorderButton(
                        binding: settingsService.settings.system.globalHotkey,
                        onRecord: { newBinding in
                            settingsService.updateSystem { $0.globalHotkey = newBinding }
                            PanelController.shared.setupHotkey()
                        }
                    )
                }
            } header: {
                Text("Appearance")
            }

            Section {
                Toggle(isOn: Binding(
                    get: { settingsService.settings.system.showPanelOnAppLaunch },
                    set: { value in settingsService.updateSystem { $0.showPanelOnAppLaunch = value } }
                )) {
                    Text("Show panel on app launch")
                }

                Toggle(isOn: Binding(
                    get: { settingsService.settings.system.launchAtLogin },
                    set: { value in
                        settingsService.updateSystem { $0.launchAtLogin = value }
                        try? LaunchAtLoginService.setEnabled(value)
                    }
                )) {
                    Text("Start at login")
                }
            } header: {
                Text("General")
            }

            Section {
                Button("Reset All Settings", role: .destructive) {
                    settingsService.resetAllSettings()
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Hotkey Recorder Button

struct HotkeyRecorderButton: View {
    let binding: HotkeyBinding
    let onRecord: (HotkeyBinding) -> Void

    @State private var isRecording = false

    var body: some View {
        Button {
            isRecording.toggle()
        } label: {
            if isRecording {
                Text("Press shortcut…")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor, lineWidth: 1)
                    )
            } else {
                Text(binding.isValid ? binding.displayString : "Record Shortcut")
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
            }
        }
        .buttonStyle(.plain)
        .onKeyPress { _ in
            guard isRecording else { return .ignored }
            // Handled by NSEvent monitor below
            return .ignored
        }
        .background {
            if isRecording {
                HotkeyRecorderEventCatcher { newBinding in
                    onRecord(newBinding)
                    isRecording = false
                }
            }
        }
    }
}

// MARK: - NSEvent-based Hotkey Recorder

private struct HotkeyRecorderEventCatcher: NSViewRepresentable {
    let onRecord: (HotkeyBinding) -> Void

    func makeNSView(context _: Context) -> HotkeyRecorderNSView {
        let view = HotkeyRecorderNSView()
        view.onRecord = onRecord
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: HotkeyRecorderNSView, context _: Context) {
        nsView.onRecord = onRecord
    }
}

final class HotkeyRecorderNSView: NSView {
    var onRecord: ((HotkeyBinding) -> Void)?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        let modifiers = HotkeyBinding.carbonModifiers(
            from: event.modifierFlags.intersection([.command, .shift, .option, .control])
        )
        guard modifiers != 0 else { return }

        let newBinding = HotkeyBinding(keyCode: UInt32(event.keyCode), carbonModifiers: modifiers)
        onRecord?(newBinding)
    }
}
