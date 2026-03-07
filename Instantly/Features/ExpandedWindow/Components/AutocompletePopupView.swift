import SwiftUI

// MARK: - Autocomplete Popup

struct AutocompletePopupView: View {
    let items: [AutocompleteItem]
    let selectedIndex: Int
    let onSelect: (AutocompleteItem) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let maxVisibleHeight: CGFloat = 240
    private let itemHeight: CGFloat = 36
    private let cornerRadius: CGFloat = 12

    private var idealHeight: CGFloat {
        CGFloat(items.count) * itemHeight + 12 // 12 = vertical padding (6 top + 6 bottom)
    }

    var body: some View {
        let _ =
            print(
                "[Autocomplete][PopupView] items(\(items.count)): \(items.map(\.label)), selectedIndex: \(selectedIndex)"
            )
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                AutocompleteRowView(
                                    item: item,
                                    isSelected: index == selectedIndex
                                )
                                .id(item.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onSelect(item)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .frame(height: min(idealHeight, maxVisibleHeight))
                    .onChange(of: selectedIndex) { _, newIndex in
                        if newIndex >= 0, newIndex < items.count {
                            withAnimation(.easeOut(duration: 0.1)) {
                                proxy.scrollTo(items[newIndex].id, anchor: .center)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .background(popupBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: -4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeOut(duration: 0.15), value: items.count)
        }
    }

    private var popupBackground: some ShapeStyle {
        colorScheme == .dark
            ? Color(nsColor: NSColor.controlBackgroundColor)
            : Color(nsColor: NSColor.controlBackgroundColor)
    }
}

// MARK: - Row View

private struct AutocompleteRowView: View {
    let item: AutocompleteItem
    let isSelected: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            // Category icon
            Image(systemName: item.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
                .background(iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            // Label
            Text(item.label)
                .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            // Category badge
            Text(item.category.displayLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(badgeTextColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(badgeBackground)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? selectionColor : Color.clear)
        )
        .contentShape(Rectangle())
    }

    // MARK: - Style helpers

    private var iconColor: Color {
        switch item.category {
        case .model:
            Color.purple
        case .quickAction:
            Color.orange
        }
    }

    private var iconBackground: Color {
        iconColor.opacity(0.12)
    }

    private var badgeTextColor: Color {
        switch item.category {
        case .model:
            Color.purple
        case .quickAction:
            Color.orange
        }
    }

    private var badgeBackground: Color {
        badgeTextColor.opacity(0.12)
    }

    private var selectionColor: Color {
        Color.primary.opacity(0.08)
    }
}
