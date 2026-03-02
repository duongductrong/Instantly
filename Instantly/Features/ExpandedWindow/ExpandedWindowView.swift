import SwiftUI

struct ExpandedWindowView: View {
    @State private var viewModel = ExpandedWindowViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            BodyView(viewModel: viewModel)
            InputBarView(viewModel: viewModel)
        }
        .frame(
            width: DesignTokens.expandedWidth,
            height: DesignTokens.expandedHeight
        )
        .preferredColorScheme(.dark)
    }
}
