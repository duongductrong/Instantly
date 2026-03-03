import Carbon.HIToolbox
import SwiftUI

struct ShortcutRecorderField: View {
    let title: String
    let subtitle: String?
    @Binding var shortcut: HotkeyBinding

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Button {
                isRecording ? stopRecording() : startRecording()
            } label: {
                HStack {
                    Image(systemName: isRecording ? "keyboard.badge.ellipsis" : "keyboard")
                        .font(.system(size: 12, weight: .semibold))
                    Text(isRecording ? "Press keys..." : shortcut.displayString)
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .foregroundStyle(.white.opacity(0.9))
                .background(Color.white.opacity(isRecording ? 0.16 : 0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(isRecording ? 0.28 : 0.14), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        stopRecording()
        isRecording = true

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
                return nil
            }

            let modifiers = HotkeyBinding.carbonModifiers(from: event.modifierFlags)
            guard modifiers != 0 else {
                NSSound.beep()
                return nil
            }

            shortcut = HotkeyBinding(keyCode: UInt32(event.keyCode), carbonModifiers: modifiers)
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        isRecording = false
    }
}
