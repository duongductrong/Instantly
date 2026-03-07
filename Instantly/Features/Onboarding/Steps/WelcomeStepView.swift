import SwiftUI

/// Welcome step — clean, native macOS introduction.
struct WelcomeStepView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App icon
            Image(systemName: "bolt.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(.tint)
                .padding(.bottom, 20)

            Text("Welcome to Instantly")
                .font(.system(size: 26, weight: .bold))
                .padding(.bottom, 8)

            Text("Your AI-powered assistant,\nalways one shortcut away.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .frame(width: 200)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
