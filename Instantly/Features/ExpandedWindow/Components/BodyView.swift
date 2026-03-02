import SwiftUI

struct BodyView: View {
    @Bindable var viewModel: ExpandedWindowViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Query text area
                if !viewModel.queryText.isEmpty {
                    Text(viewModel.queryText)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Attachment chips
                if !viewModel.attachments.isEmpty {
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

                // Status indicator
                if !viewModel.statusMessage.isEmpty {
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
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
