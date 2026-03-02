import SwiftUI

struct FloatingPillView: View {
    @State private var viewModel = FloatingPillViewModel()

    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: DesignTokens.pillSize, height: DesignTokens.pillSize)
            .background(
                ZStack {
                    VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    Color.black.opacity(0.7)
                }
            )
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(viewModel.isHovered ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: viewModel.isHovered)
            .onHover { hovering in
                viewModel.isHovered = hovering
            }
            .onTapGesture {
                PanelController.shared.toggle()
            }
    }
}
