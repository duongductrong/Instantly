import SwiftUI

struct PanelContentView: View {
    @Bindable var viewModel: PanelContentViewModel

    var body: some View {
        ZStack {
            // VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            Color(nsColor: .windowBackgroundColor)

            if viewModel.isExpanded {
                ExpandedWindowView(viewModel: PanelController.shared.expandedViewModel)
                    .opacity(viewModel.showContent ? 1 : 0)
            } else {
                FloatingPillView()
            }
        }
    }
}
