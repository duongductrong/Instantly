import SwiftUI

struct QuickToolbarView: View {
    let actions: [QuickToolbarAction]
    let onAction: (QuickToolbarAction) -> Void
    let onDismiss: () -> Void

    @State private var hoveredActionID: String?
    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                QuickToolbarRow(
                    action: action,
                    isHovered: hoveredActionID == action.id,
                    isKeyboardSelected: selectedIndex == index
                )
                .onHover { hovering in
                    guard !action.isDisabled else { return }
                    hoveredActionID = hovering ? action.id : nil
                    if hovering { selectedIndex = index }
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
        .background(
            ZStack {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
                Color(nsColor: .windowBackgroundColor).opacity(0.55)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.toolbarCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: DesignTokens.toolbarShadowRadius, x: 0, y: 6)
        .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.return) {
            let idx = selectedIndex
            guard idx >= 0, idx < actions.count, !actions[idx].isDisabled else { return .ignored }
            onAction(actions[idx])
            return .handled
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
    }

    private func moveSelection(by delta: Int) {
        let count = actions.count
        guard count > 0 else { return }
        var next = (selectedIndex + delta + count) % count
        // Skip disabled actions
        let start = next
        while actions[next].isDisabled {
            next = (next + delta + count) % count
            if next == start { break }
        }
        selectedIndex = next
        hoveredActionID = nil
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

            Text(action.label)
                .font(.system(size: 13, weight: action.isHighlighted ? .semibold : .regular))
                .foregroundStyle(labelColor)
                .lineLimit(1)

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
        if action.isHighlighted {
            return Color.accentColor
        }
        return .secondary
    }

    private var labelColor: Color {
        if action.isDisabled {
            return .secondary.opacity(0.5)
        }
        if action.isHighlighted {
            return .primary
        }
        return .primary.opacity(0.85)
    }

    private var backgroundColor: Color {
        if isActive {
            return Color.accentColor.opacity(0.12)
        }
        if action.isHighlighted, !action.isDisabled {
            return Color.accentColor.opacity(0.06)
        }
        return .clear
    }
}
