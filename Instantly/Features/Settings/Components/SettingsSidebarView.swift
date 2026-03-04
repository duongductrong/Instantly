import SwiftUI

struct SettingsSidebarView: View {
    @Binding var selectedSection: SettingsViewModel.Section?
    @State private var hoveredSection: SettingsViewModel.Section?

    private let groups: [SidebarGroup] = [
        SidebarGroup(title: "Workspace", sections: [.assistant, .model]),
        SidebarGroup(title: "System", sections: [.system]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(groups) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.title)
                            .font(.system(size: 10, weight: .bold).smallCaps())
                            .kerning(1.2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(group.sections) { section in
                                sidebarItem(for: section)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            Button {
                selectedSection = .system
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Settings")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .foregroundStyle(.white.opacity(0.88))
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }

    private func sidebarItem(for section: SettingsViewModel.Section) -> some View {
        let isActive = selectedSection == section
        let isHovered = hoveredSection == section

        return Button {
            selectedSection = section
        } label: {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 14)
                Text(section.title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.56))
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isActive
                            ? Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255)
                            : (isHovered ? Color.white.opacity(0.05) : .clear)
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isInside in
            hoveredSection = isInside ? section : (hoveredSection == section ? nil : hoveredSection)
        }
    }
}

private struct SidebarGroup: Identifiable {
    let title: String
    let sections: [SettingsViewModel.Section]

    var id: String {
        title
    }
}
