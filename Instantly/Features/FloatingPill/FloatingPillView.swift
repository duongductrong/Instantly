import SwiftUI

struct FloatingPillView: View {
    @State private var viewModel = FloatingPillViewModel()

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Text("Instantly")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .frame(width: DesignTokens.pillWidth, height: DesignTokens.pillHeight)
        .background(
            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                Color.black.opacity(0.7)
            }
        )
        .clipShape(Capsule())
        .scaleEffect(viewModel.isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: viewModel.isHovered)
        .onHover { hovering in
            viewModel.isHovered = hovering
        }
        .onTapGesture {
            PanelController.shared.toggle()
        }
    }
}
