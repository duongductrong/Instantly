import SwiftUI

/// Welcome step — elegant macOS-style introduction with subtle gradients and feature highlights.
struct WelcomeStepView: View {
    let onContinue: () -> Void

    private struct Feature: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String
    }

    private let features: [Feature] = [
        Feature(icon: "command", title: "Global Hotkey", subtitle: "Summon instantly from anywhere"),
        Feature(icon: "brain.head.profile", title: "Local AI", subtitle: "Private, on-device intelligence"),
        Feature(icon: "bolt.fill", title: "Quick Actions", subtitle: "Translate, summarize, and more"),
    ]

    var body: some View {
        ZStack {
            // Subtle ambient gradient
            RadialGradient(
                colors: [
                    DesignTokens.brandGreen.opacity(0.08),
                    Color.clear,
                ],
                center: .top,
                startRadius: 80,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App icon with background
                ZStack {
                    Circle()
                        .fill(DesignTokens.brandGreen.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(DesignTokens.brandGreen)
                }
                .padding(.bottom, 28)

                // Title
                Text("Welcome to Instantly")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                    .padding(.bottom, 8)

                // Subtitle
                Text("Your AI-powered assistant, always one shortcut away.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 36)

                // Feature highlights
                VStack(spacing: 14) {
                    ForEach(features) { feature in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(DesignTokens.brandGreen.opacity(0.10))
                                    .frame(width: 36, height: 36)
                                Image(systemName: feature.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(DesignTokens.brandGreen)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text(feature.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.primary.opacity(0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                }
                .frame(maxWidth: 380)
                .padding(.bottom, 40)

                Spacer()

                // Get Started button
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 220)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
                .padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
