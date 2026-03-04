import SwiftUI

/// macOS Tahoe-style appearance mode picker with three visual thumbnail cards.
struct AppearanceModePicker: View {
    let selectedMode: AppearanceMode
    let onSelect: (AppearanceMode) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppearanceMode.allCases) { mode in
                AppearanceCard(
                    mode: mode,
                    isSelected: selectedMode == mode,
                    onSelect: { onSelect(mode) }
                )
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Appearance Card

private struct AppearanceCard: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Mini window thumbnail
                windowThumbnail(for: mode)
                    .frame(width: 96, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Color.accentColor : Color.primary.opacity(0.15),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    )
                    .shadow(color: .black.opacity(0.08), radius: 2, y: 1)

                // Label + checkmark
                HStack(spacing: 4) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.accentColor)
                    }

                    Text(mode.title)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func windowThumbnail(for mode: AppearanceMode) -> some View {
        switch mode {
        case .light:
            lightThumbnail
        case .dark:
            darkThumbnail
        case .auto:
            autoThumbnail
        }
    }

    // MARK: - Light Thumbnail

    private var lightThumbnail: some View {
        ZStack {
            // Background
            Color(nsColor: .controlBackgroundColor)

            VStack(spacing: 0) {
                // Title bar
                HStack(spacing: 3) {
                    Circle().fill(Color.red.opacity(0.8)).frame(width: 5, height: 5)
                    Circle().fill(Color.yellow.opacity(0.8)).frame(width: 5, height: 5)
                    Circle().fill(Color.green.opacity(0.8)).frame(width: 5, height: 5)
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color(white: 0.92))

                // Content area
                HStack(spacing: 0) {
                    // Sidebar
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor.opacity(0.3))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(white: 0.82))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(white: 0.82))
                            .frame(height: 4)
                        Spacer()
                    }
                    .padding(4)
                    .frame(width: 28)
                    .background(Color(white: 0.94))

                    // Main content
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(white: 0.85))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(white: 0.85))
                            .frame(width: 40, height: 4, alignment: .leading)
                        Spacer()
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                }
            }
        }
    }

    // MARK: - Dark Thumbnail

    private var darkThumbnail: some View {
        ZStack {
            Color(white: 0.15)

            VStack(spacing: 0) {
                // Title bar
                HStack(spacing: 3) {
                    Circle().fill(Color.red.opacity(0.8)).frame(width: 5, height: 5)
                    Circle().fill(Color.yellow.opacity(0.8)).frame(width: 5, height: 5)
                    Circle().fill(Color.green.opacity(0.8)).frame(width: 5, height: 5)
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color(white: 0.2))

                // Content area
                HStack(spacing: 0) {
                    // Sidebar
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor.opacity(0.4))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(white: 0.3))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(white: 0.3))
                            .frame(height: 4)
                        Spacer()
                    }
                    .padding(4)
                    .frame(width: 28)
                    .background(Color(white: 0.18))

                    // Main content
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(white: 0.3))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(white: 0.3))
                            .frame(width: 40, height: 4, alignment: .leading)
                        Spacer()
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.15))
                }
            }
        }
    }

    // MARK: - Auto Thumbnail (Split)

    private var autoThumbnail: some View {
        ZStack {
            HStack(spacing: 0) {
                // Left half — light
                ZStack {
                    Color.white

                    VStack(spacing: 0) {
                        HStack(spacing: 3) {
                            Circle().fill(Color.red.opacity(0.8)).frame(width: 5, height: 5)
                            Circle().fill(Color.yellow.opacity(0.8)).frame(width: 5, height: 5)
                            Spacer()
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color(white: 0.92))

                        VStack(spacing: 3) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(white: 0.85))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(white: 0.85))
                                .frame(height: 4)
                            Spacer()
                        }
                        .padding(4)
                    }
                }

                // Right half — dark
                ZStack {
                    Color(white: 0.15)

                    VStack(spacing: 0) {
                        HStack(spacing: 3) {
                            Spacer()
                            Circle().fill(Color.green.opacity(0.8)).frame(width: 5, height: 5)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color(white: 0.2))

                        VStack(spacing: 3) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(white: 0.3))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(white: 0.3))
                                .frame(height: 4)
                            Spacer()
                        }
                        .padding(4)
                    }
                }
            }
        }
    }
}
