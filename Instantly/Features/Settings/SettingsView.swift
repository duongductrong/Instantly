import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar(removing: .sidebarToggle)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedTab) {
            // Top section: General, About
            ForEach(SettingsTab.topSection) { tab in
                sidebarItem(tab)
            }

            // "Instantly" section
            Section {
                ForEach(SettingsTab.instantlySection) { tab in
                    sidebarItem(tab)
                }
            } header: {
                Text("Instantly")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180, idealWidth: 200, maxWidth: 220)
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 12)
        }
    }

    private func sidebarItem(_ tab: SettingsTab) -> some View {
        Label {
            Text(tab.title)
        } icon: {
            Image(systemName: tab.icon)
        }
        .tag(tab)
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .general:
            GeneralSettingsView()
        case .about:
            AboutSettingsView()
        case .assistant:
            AssistantSettingsView()
        case .model:
            ModelSettingsView()
        case .quickActions:
            QuickActionsSettingsView()
        }
    }
}
