import SwiftUI

struct InputBarView: View {
    @Bindable var viewModel: ExpandedWindowViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var textHeight: CGFloat = 22

    /// Max height before scrollbar activates
    private let maxInputHeight: CGFloat = 120
    private let actionButtonSize: CGFloat = 28

    private var hasInputText: Bool {
        !viewModel.queryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var submitButtonBackground: Color {
        colorScheme == .dark ? .white : .black
    }

    private var submitIconColor: Color {
        colorScheme == .dark ? .black : .white
    }

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
                        viewModel.sendMessage()
                    },
                    dynamicHeight: $textHeight
                )
                .frame(height: textHeight)
                .animation(.easeOut(duration: 0.15), value: textHeight)

                if viewModel.isLoading {
                    Button(action: { viewModel.stopGenerating() }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.white)
                            .frame(width: actionButtonSize, height: actionButtonSize)
                            .background(Color.red.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: {}) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: actionButtonSize, height: actionButtonSize)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        if hasInputText {
                            viewModel.sendMessage()
                        }
                    }) {
                        Image(systemName: hasInputText ? "arrow.up" : "at")
                            .font(.system(size: 13, weight: hasInputText ? .semibold : .regular))
                            .foregroundStyle(hasInputText ? submitIconColor : .white.opacity(0.7))
                            .frame(width: actionButtonSize, height: actionButtonSize)
                            .background(hasInputText ? submitButtonBackground : Color.white.opacity(0.1))
                            .clipShape(Circle())
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.18), value: hasInputText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
