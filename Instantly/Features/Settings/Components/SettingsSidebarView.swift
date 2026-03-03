import SwiftUI

struct SettingsSidebarView: View {
    @Binding var selectedSection: SettingsViewModel.Section?

    var body: some View {
        List(SettingsViewModel.Section.allCases, selection: $selectedSection) { section in
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.system(size: 13, weight: .medium))
                    Text(section.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: section.icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            .tag(section)
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}
