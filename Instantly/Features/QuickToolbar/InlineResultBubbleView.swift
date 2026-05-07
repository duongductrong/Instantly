import SwiftUI

/// Floating bubble that shows the LLM result for inline content-modifying actions.
/// Features a clear header (action name + close), content area, and a footer action bar
/// with a prominent Apply button and keyboard hints.
struct InlineResultBubbleView: View {
    @Bindable var viewModel: InlineResultViewModel
    let onDismiss: () -> Void
    let onApply: () -> Void

    private var isResultReady: Bool {
        !viewModel.isLoading && !viewModel.resultText.isEmpty && viewModel.errorMessage == nil
    }

    private var bubbleShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DesignTokens.toolbarCornerRadius, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            contentArea
                .frame(maxWidth: DesignTokens.inlineBubbleMaxWidth, alignment: .leading)

            if isResultReady {
                footer
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .fixedSize(horizontal: false, vertical: true)
        .background(backgroundMaterial.clipShape(bubbleShape))
        .clipShape(bubbleShape)
        .overlay(
            bubbleShape
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
        )
        .preferredColorScheme(
            SettingsService.shared.settings.system.appearanceMode.resolvedColorScheme
        )
    }

    // MARK: - Background

    private var backgroundMaterial: some View {
        Group {
            if SettingsService.shared.settings.system.visualStyle == .vibrancy {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
            } else {
                Color(nsColor: .windowBackgroundColor)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            // Action icon
            Image(systemName: viewModel.actionIcon.isEmpty ? "sparkles" : viewModel.actionIcon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignTokens.brandGreen)
                .frame(width: 24, height: 24)
                .background(DesignTokens.brandGreen.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            // Action name
            Text(viewModel.actionLabel.isEmpty ? "Editing" : viewModel.actionLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.9))

            Spacer()

            // Close button
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .frame(width: 22, height: 22)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) {
            Divider()
                .opacity(0.15)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoading {
            loadingState
        } else if let error = viewModel.errorMessage {
            errorState(error)
        } else {
            resultState
        }
    }

    private var loadingState: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
                .tint(DesignTokens.brandGreen)

            Text("Editing with \(viewModel.actionLabel)...")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: 48)
        .padding(.top, 8)
    }

    private func errorState(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(.orange)
                .padding(.top, 1)

            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(4)

            Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    private var resultState: some View {
        ScrollView {
            Text(viewModel.resultText)
                .font(.system(size: 14))
                .foregroundStyle(.primary.opacity(0.92))
                .lineSpacing(4)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 220)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 0) {
            // Keyboard hint
            HStack(spacing: 4) {
                keyboardBadge("Tab")
                Text("to apply")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary.opacity(0.6))

                Text("·")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary.opacity(0.4))

                keyboardBadge("Esc")
                Text("to dismiss")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary.opacity(0.6))
            }

            Spacer()

            // Apply button
            Button {
                onApply()
            } label: {
                HStack(spacing: 5) {
                    Text("Apply")
                        .font(.system(size: 12, weight: .semibold))

                    Image(systemName: "arrow.turn.down.left")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(DesignTokens.brandGreen)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .padding(.top, 10)
        .overlay(alignment: .top) {
            Divider()
                .opacity(0.15)
        }
    }

    // MARK: - Helpers

    private func keyboardBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary.opacity(0.7))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
            )
    }
}
