import SwiftUI

struct ExpandedWindowView: View {
    @Bindable var viewModel: ExpandedWindowViewModel

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            BodyView(viewModel: viewModel)
            ContextBarView(viewModel: viewModel)
            InputBarView(viewModel: viewModel)
        }
        .frame(
            width: DesignTokens.expandedWidth,
            height: DesignTokens.expandedHeight
        )
        .preferredColorScheme(.dark)
    }
}
