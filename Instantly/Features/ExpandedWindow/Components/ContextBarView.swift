import SwiftUI

struct ContextChipView: View {
    let item: ContextItem
    var onRemove: (() -> Void)?

    @State private var isTooltipVisible = false
    @State private var hoverTimer: Timer?

    var body: some View {
        HStack(spacing: 4) {
            chipIcon
            Text(item.type == .selectedText ? "Selected Text" : item.label)
                .font(.system(size: 12))
                .foregroundStyle(.primary.opacity(0.8))
                .lineLimit(1)
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.primary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .frame(width: 16, height: 16)
                .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.primary.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onHover { hovering in
            if item.type == .selectedText {
                if hovering {
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { _ in
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isTooltipVisible = true
                            }
                        }
                    }
                } else {
                    hoverTimer?.invalidate()
                    hoverTimer = nil
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isTooltipVisible = false
                    }
                }
            }
        }
        .popover(isPresented: $isTooltipVisible, arrowEdge: .bottom) {
            Text(item.rawValue ?? item.label)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .lineLimit(10)
                .padding(10)
                .frame(maxWidth: 280)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var chipIcon: some View {
        switch item.type {
        case .activeApp:
            if let icon = item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 14, height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        case .selectedText:
            Image(systemName: "doc.text")
                .font(.system(size: 11))
                .foregroundStyle(.primary.opacity(0.7))
                .frame(width: 14, height: 14)
        }
    }
}

struct ContextBarView: View {
    @Bindable var viewModel: ExpandedWindowViewModel
    @State private var isAddMenuVisible = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if viewModel.contextItems.isEmpty {
                    addContextButton(showLabel: true)
                } else {
                    ForEach(viewModel.contextItems) { item in
                        ContextChipView(item: item) {
                            viewModel.removeContextItem(item)
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                    addContextButton(showLabel: false)
                }
            }
            .padding(.horizontal, 16)
            .animation(.spring(duration: 0.25), value: viewModel.contextItems)
        }
        .frame(height: 36)
    }

    private func addContextButton(showLabel: Bool) -> some View {
        ContextAddButton(showLabel: showLabel) {
            isAddMenuVisible.toggle()
        }
        .popover(isPresented: $isAddMenuVisible, arrowEdge: .bottom) {
            contextAddMenu
        }
    }

    private var contextAddMenu: some View {
        VStack(alignment: .leading, spacing: 6) {
            ContextAddMenuRow(
                icon: "doc.on.clipboard",
                title: "Add clipboard text",
                subtitle: "Use current clipboard content as context",
                isEnabled: viewModel.canAddClipboardContext()
            ) {
                if viewModel.addClipboardContext() {
                    isAddMenuVisible = false
                }
            }

            ContextAddMenuRow(
                icon: "app.badge",
                title: "Add captured app",
                subtitle: "Re-attach the app context captured on open",
                isEnabled: viewModel.canAddCapturedActiveAppContext()
            ) {
                if viewModel.addCapturedActiveAppContext() {
                    isAddMenuVisible = false
                }
            }

            ContextAddMenuRow(
                icon: "text.quote",
                title: "Add selected text",
                subtitle: "Re-attach selected text captured on open",
                isEnabled: viewModel.canAddCapturedSelectedTextContext()
            ) {
                if viewModel.addCapturedSelectedTextContext() {
                    isAddMenuVisible = false
                }
            }
        }
        .padding(8)
        .frame(width: 260)
    }
}

private struct ContextAddButton: View {
    let showLabel: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary.opacity(isHovered ? 0.8 : 0.6))
                    .frame(width: 15, height: 15)

                if showLabel {
                    Text("Add context")
                        .font(.system(size: 12))
                        .foregroundStyle(.primary.opacity(isHovered ? 0.8 : 0.6))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.primary.opacity(isHovered ? 0.14 : 0.09))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}

private struct ContextAddMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isEnabled: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary.opacity(isEnabled ? 0.75 : 0.3))
                    .frame(width: 14, height: 14)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary.opacity(isEnabled ? 0.9 : 0.45))

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.primary.opacity(isEnabled ? 0.6 : 0.35))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(isHovered && isEnabled ? Color.primary.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
