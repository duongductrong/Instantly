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
            width: viewModel.expandedWidth,
            height: DesignTokens.expandedHeight
        )
        .preferredColorScheme(.dark)
        .background {
            Button("") {
                viewModel.clearConversation()
            }
            .keyboardShortcut("n", modifiers: .command)
            .opacity(0)
            .frame(width: 0, height: 0)
        }
    }
}
