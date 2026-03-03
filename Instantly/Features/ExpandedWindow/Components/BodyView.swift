import SwiftUI

struct BodyView: View {
    @Bindable var viewModel: ExpandedWindowViewModel
    @State private var streamingScrollTask: Task<Void, Never>?

    private let suggestionChips = [
        "Summarize this text",
        "Explain this code",
        "Help me write...",
    ]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.messages.isEmpty {
                        emptyState
                    } else {
                        conversationView
                    }

                    // Attachment chips
                    if !viewModel.attachments.isEmpty {
                        attachmentChips
                    }

                    // Status/error message
                    if !viewModel.statusMessage.isEmpty {
                        statusIndicator
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
            .onDisappear {
                streamingScrollTask?.cancel()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.messages.last?.content) { _, _ in
                scheduleStreamingScroll(with: proxy)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 20)
            Text("What can I help with?")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: 8) {
                ForEach(suggestionChips, id: \.self) { chip in
                    Button {
                        viewModel.queryText = chip
                        viewModel.sendMessage()
                    } label: {
                        Text(chip)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Conversation

    private var conversationView: some View {
        ForEach(viewModel.messages) { message in
            if message.role != .system {
                messageBubble(message)
            }
        }
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        ConversationMessageView(
            message: message,
            onCopy: { viewModel.copyMessageContent(message) },
            onSpeak: { viewModel.toggleSpeakMessageContent(message) },
            isSpeaking: viewModel.isMessageSpeaking(message)
        ) {
            messageText(for: message)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(message.role.bubbleBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private func messageText(for message: ChatMessage) -> some View {
        let displayContent = message.content.isEmpty && message.role == .assistant ? "..." : message.content

        if message.role == .assistant {
            AssistantMarkdownView(content: displayContent)
                .foregroundStyle(.white)
        } else {
            Text(displayContent)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .textSelection(.enabled)
        }
    }

    // MARK: - Attachments

    private var attachmentChips: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.attachments) { attachment in
                HStack(spacing: 6) {
                    Image(systemName: attachment.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)

                    Text(attachment.filename)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Status

    private var statusIndicator: some View {
        HStack(spacing: 8) {
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
            }

            Text(viewModel.statusMessage)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func scheduleStreamingScroll(with proxy: ScrollViewProxy) {
        streamingScrollTask?.cancel()
        streamingScrollTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(40))
            guard !Task.isCancelled else { return }
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
}

private struct ConversationMessageView<Content: View>: View {
    let message: ChatMessage
    let onCopy: () -> Void
    let onSpeak: () -> Void
    let isSpeaking: Bool
    let content: Content

    private let actionBarEstimatedHeight: CGFloat = 32
    private let actionBarGapFromMessage: CGFloat = 12

    private var actionBarVerticalOffset: CGFloat {
        actionBarEstimatedHeight + actionBarGapFromMessage
    }

    private var messageBottomSpacing: CGFloat {
        actionBarVerticalOffset + 4
    }

    @State private var isHovered = false

    init(
        message: ChatMessage,
        onCopy: @escaping () -> Void,
        onSpeak: @escaping () -> Void,
        isSpeaking: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.message = message
        self.onCopy = onCopy
        self.onSpeak = onSpeak
        self.isSpeaking = isSpeaking
        self.content = content()
    }

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            content
                .overlay(alignment: actionAlignment) {
                    if isHovered {
                        MessageActionsOverlay(
                            backgroundColor: message.role.bubbleBackgroundColor,
                            isSpeaking: isSpeaking,
                            onCopy: onCopy,
                            onSpeak: onSpeak
                        )
                        .padding(6)
                        .offset(y: actionBarVerticalOffset)
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    }
                }

            if message.role == .assistant { Spacer(minLength: 40) }
        }
        .padding(.bottom, messageBottomSpacing)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }

    private var actionAlignment: Alignment {
        message.role == .assistant ? .bottomLeading : .bottomTrailing
    }
}

private struct MessageActionsOverlay: View {
    let backgroundColor: Color
    let isSpeaking: Bool
    let onCopy: () -> Void
    let onSpeak: () -> Void

    @State private var didCopy = false
    @State private var resetCopyTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 6) {
            MessageActionIconButton(
                icon: didCopy ? "checkmark" : "doc.on.doc",
                tooltip: didCopy ? "Copied" : "Copy message",
                isActive: didCopy,
                action: handleCopy
            )

            MessageActionIconButton(
                icon: isSpeaking ? "stop.fill" : "speaker.wave.2",
                tooltip: isSpeaking ? "Stop speaking" : "Speak message",
                isActive: isSpeaking,
                action: onSpeak
            )
        }
        .padding(4)
        .background(backgroundColor)
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        }
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        .onDisappear {
            resetCopyTask?.cancel()
        }
    }

    private func handleCopy() {
        onCopy()
        resetCopyTask?.cancel()
        withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
            didCopy = true
        }

        resetCopyTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(850))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                didCopy = false
            }
        }
    }
}

private extension ChatMessage.Role {
    var bubbleBackgroundColor: Color {
        switch self {
        case .user:
            // .accentColor.opacity(0.6)
            .white.opacity(0.08)
        case .assistant, .system:
            .white.opacity(0.08)
        }
    }
}

private struct MessageActionIconButton: View {
    let icon: String
    let tooltip: String
    let isActive: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: isActive)
                .foregroundStyle(.white.opacity(isHovered || isActive ? 0.95 : 0.72))
                .frame(width: 24, height: 24)
                .background(.white.opacity(isHovered || isActive ? 0.16 : 0.08))
                .clipShape(Circle())
                .scaleEffect(isHovered ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.24, dampingFraction: 0.8), value: isActive)
        .overlay(alignment: .top) {
            if isHovered {
                MessageActionTooltip(text: tooltip)
                    .offset(y: -30)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}

private struct MessageActionTooltip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.82))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .fixedSize()
            .allowsHitTesting(false)
    }
}
