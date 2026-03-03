import SwiftUI

struct BodyView: View {
    @Bindable var viewModel: ExpandedWindowViewModel

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
            .onChange(of: viewModel.messages.last?.content) { _, _ in
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
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
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            messageText(for: message)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    message.role == .user
                        ? Color.accentColor.opacity(0.6)
                        : Color.white.opacity(0.08)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .textSelection(.enabled)

            if message.role == .assistant { Spacer(minLength: 40) }
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
}
