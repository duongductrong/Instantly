import SwiftUI

struct PanelContentView: View {
    @Bindable var viewModel: PanelContentViewModel

    var body: some View {
        ZStack {
            if SettingsService.shared.settings.system.visualStyle == .vibrancy {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            } else {
                Color(nsColor: .windowBackgroundColor)
            }

            if viewModel.isExpanded {
                ExpandedWindowView(viewModel: PanelController.shared.expandedViewModel)
                    .opacity(viewModel.showContent ? 1 : 0)
            } else {
                FloatingPillView()
            }
        }
    }
}
