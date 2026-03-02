import SwiftUI

struct PanelContentView: View {
    @Bindable var viewModel: PanelContentViewModel

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)

            if viewModel.isExpanded {
                ExpandedWindowView()
                    .opacity(viewModel.showContent ? 1 : 0)
            } else {
                FloatingPillView()
            }
        }
    }
}
