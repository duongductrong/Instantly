import SwiftUI

struct AboutSettingsView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.blue)

            Text("Instantly")
                .font(.system(size: 22, weight: .bold))

            Text("The AI Assistant")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Text("Version \(appVersion) (\(buildNumber))")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)

            Spacer()

            Text("© 2026 Instantly. All rights reserved.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
