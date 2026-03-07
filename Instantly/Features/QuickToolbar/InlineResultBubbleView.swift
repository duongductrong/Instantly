import SwiftUI

/// Floating bubble that shows the LLM result for inline content-modifying actions.
/// Adapts width to content (max 400pt). Shows loading state, result text,
/// and a Tab button to apply the result to the source app.
struct InlineResultBubbleView: View {
    @Bindable var viewModel: InlineResultViewModel
    let onDismiss: () -> Void
    let onApply: () -> Void

    private var isResultReady: Bool {
        !viewModel.isLoading && !viewModel.resultText.isEmpty && viewModel.errorMessage == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // Content area
                contentArea
                    .frame(maxWidth: DesignTokens.inlineBubbleMaxWidth, alignment: .leading)

                // Tab-to-insert button (right side)
                if isResultReady {
                    Divider()
                        .frame(height: 28)
                        .padding(.horizontal, 6)

                    tabButton
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.toolbarCornerRadius, style: .continuous))
        .preferredColorScheme(
            SettingsService.shared.settings.system.appearanceMode.resolvedColorScheme
        )
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
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
                .tint(.secondary)

            Text("Thinking")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .italic()
        }
        .frame(minHeight: 24)
    }

    private func errorState(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.orange)

            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
    }

    private var resultState: some View {
        ScrollView {
            Text(viewModel.resultText)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
                .lineSpacing(3)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 200)
    }

    // MARK: - Tab Button

    private var tabButton: some View {
        Button {
            onApply()
        } label: {
            HStack(spacing: 4) {
                Text("Tab")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Image(systemName: "arrow.turn.down.left")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
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
}
