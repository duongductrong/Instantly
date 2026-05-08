import SwiftUI

struct QuickToolbarView: View {
    let actions: [QuickToolbarAction]
    let selectedIndex: Int
    let initialQueryText: String
    let isInputFocused: Bool
    let onQueryChange: (String) -> Void
    let onInlineSubmit: (String) -> Void
    let onAction: (QuickToolbarAction) -> Void
    let onDismiss: () -> Void

    @State private var queryText: String = ""
    @FocusState private var inputFocusState: Bool
    @State private var hoveredActionID: String?

    private var toolbarShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DesignTokens.toolbarCornerRadius, style: .continuous)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Inline request input row
            inputRow
                .focused($inputFocusState)
                .onChange(of: isInputFocused) { _, newValue in
                    inputFocusState = newValue
                }

            Divider()
                .padding(.horizontal, 12)
                .opacity(0.4)

            ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                QuickToolbarRow(
                    action: action,
                    isHovered: hoveredActionID == action.id,
                    isKeyboardSelected: !isInputFocused && selectedIndex == index
                )
                .onHover { hovering in
                    guard !action.isDisabled else { return }
                    hoveredActionID = hovering ? action.id : nil
                }
                .onTapGesture {
                    guard !action.isDisabled else { return }
                    onAction(action)
                }

                if index < actions.count - 1 {
                    Divider()
                        .padding(.horizontal, 12)
                        .opacity(0.4)
                }
            }
        }
        .padding(.vertical, 6)
        .frame(width: DesignTokens.toolbarWidth)
        .background(backgroundMaterial.clipShape(toolbarShape))
        .clipShape(toolbarShape)
        .overlay(
            toolbarShape
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
        )
        .preferredColorScheme(
            SettingsService.shared.settings.system.appearanceMode.resolvedColorScheme
        )
        .onAppear {
            queryText = initialQueryText
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                inputFocusState = isInputFocused
            }
        }
    }

    private var inputRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(inputIconColor)
                .frame(width: 22, height: 22)

            TextField("Ask anything...", text: $queryText)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.primary.opacity(0.85))
                .textFieldStyle(.plain)
                .lineLimit(1)
                .onSubmit {
                    onInlineSubmit(queryText)
                }
                .onChange(of: queryText) { _, newValue in
                    onQueryChange(newValue)
                }

            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: DesignTokens.toolbarRowHeight)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(inputBackgroundColor)
                .padding(.horizontal, 6)
        )
        .contentShape(Rectangle())
    }

    private var inputIconColor: Color {
        if inputFocusState {
            return DesignTokens.brandGreen
        }
        return .secondary
    }

    private var inputBackgroundColor: Color {
        .clear
    }

    private var backgroundMaterial: some View {
        Group {
            if SettingsService.shared.settings.system.visualStyle == .vibrancy {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
            } else {
                Color(nsColor: .windowBackgroundColor)
            }
        }
    }
}

// MARK: - Row

private struct QuickToolbarRow: View {
    let action: QuickToolbarAction
    let isHovered: Bool
    let isKeyboardSelected: Bool

    private var isActive: Bool {
        !action.isDisabled && (isHovered || isKeyboardSelected)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: action.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 22, height: 22)

            // Use hidden semibold text as sizing reference to prevent layout shift
            Text(action.label)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .hidden()
                .overlay(alignment: .leading) {
                    Text(action.label)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(labelColor)
                        .lineLimit(1)
                }

            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: DesignTokens.toolbarRowHeight)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundColor)
                .padding(.horizontal, 6)
        )
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.12), value: isActive)
    }

    private var iconColor: Color {
        if action.isDisabled {
            return .secondary.opacity(0.5)
        }
        if isActive {
            return DesignTokens.brandGreen
        }
        return .secondary
    }

    private var labelColor: Color {
        if action.isDisabled {
            return .secondary.opacity(0.5)
        }
        return .primary.opacity(0.85)
    }

    private var backgroundColor: Color {
        if isActive {
            return DesignTokens.brandGreen.opacity(0.12)
        }
        return .clear
    }
}
