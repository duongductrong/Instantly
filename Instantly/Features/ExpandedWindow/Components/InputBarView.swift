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
        .primary
    }

    private var submitIconColor: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.primary.opacity(0.15))

            HStack(alignment: .center, spacing: 10) {
                MultiLineTextView(
                    text: $viewModel.queryText,
                    placeholder: "Ask anything...",
                    font: .systemFont(ofSize: 14),
                    textColor: .labelColor,
                    maxHeight: maxInputHeight,
                    onSubmit: {
                        if viewModel.showAutocomplete {
                            viewModel.confirmAutocompleteSelection()
                        } else {
                            viewModel.sendMessage()
                        }
                    },
                    onArrowUp: {
                        viewModel.handleAutocompleteArrowUp()
                    },
                    onArrowDown: {
                        viewModel.handleAutocompleteArrowDown()
                    },
                    onEscape: {
                        viewModel.dismissAutocomplete()
                    },
                    isAutocompleteActive: viewModel.showAutocomplete,
                    shouldMoveCursorToEnd: Binding(
                        get: { viewModel.shouldMoveCursorToEnd },
                        set: { viewModel.shouldMoveCursorToEnd = $0 }
                    ),
                    dynamicHeight: $textHeight,
                    shouldFocus: $viewModel.shouldFocusInput,
                    viewModel: viewModel
                )
                .frame(height: textHeight)
                .animation(.easeOut(duration: 0.15), value: textHeight)

                if viewModel.isLoading {
                    Button(action: { viewModel.stopGenerating() }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.primary.opacity(0.7))
                            .frame(width: actionButtonSize, height: actionButtonSize)
                            .background(Color.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: {}) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.primary.opacity(0.7))
                            .frame(width: actionButtonSize, height: actionButtonSize)
                            .background(Color.primary.opacity(0.1))
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
                            .foregroundStyle(hasInputText ? submitIconColor : .primary.opacity(0.7))
                            .frame(width: actionButtonSize, height: actionButtonSize)
                            .background(hasInputText ? submitButtonBackground : Color.primary.opacity(0.1))
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
        .onChange(of: viewModel.queryText) { _, _ in
            viewModel.updateAutocompleteState()
        }
    }
}
