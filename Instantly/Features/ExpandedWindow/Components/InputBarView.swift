import SwiftUI

struct InputBarView: View {
    @Bindable var viewModel: ExpandedWindowViewModel
    @State private var textHeight: CGFloat = 22

    /// Max height before scrollbar activates
    private let maxInputHeight: CGFloat = 120

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.15))

            HStack(alignment: .center, spacing: 10) {
                MultiLineTextView(
                    text: $viewModel.queryText,
                    placeholder: "Ask anything...",
                    font: .systemFont(ofSize: 14),
                    textColor: .white,
                    maxHeight: maxInputHeight,
                    onSubmit: {
                        // Handle submit — future integration point
                    },
                    dynamicHeight: $textHeight
                )
                .frame(height: textHeight)
                .animation(.easeOut(duration: 0.15), value: textHeight)

                Button(action: {}) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    Image(systemName: "at")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
