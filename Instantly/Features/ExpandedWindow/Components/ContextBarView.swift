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
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .frame(width: 16, height: 16)
                .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.white.opacity(0.09))
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
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 14, height: 14)
        }
    }
}

struct ContextBarView: View {
    @Bindable var viewModel: ExpandedWindowViewModel

    var body: some View {
        if !viewModel.contextItems.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.contextItems) { item in
                        ContextChipView(item: item) {
                            viewModel.removeContextItem(item)
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, 16)
                .animation(.spring(duration: 0.25), value: viewModel.contextItems)
            }
            .frame(height: 36)
        }
    }
}
