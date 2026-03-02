import SwiftUI

struct InputBarView: View {
    @Bindable var viewModel: ExpandedWindowViewModel
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.15))

            HStack(spacing: 10) {
                TextField("Ask Highlight anything...", text: $viewModel.queryText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        // Handle submit — future integration point
                    }

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
        .onAppear {
            isTextFieldFocused = true
        }
    }
}
