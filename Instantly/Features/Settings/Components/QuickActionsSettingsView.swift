import SwiftUI

struct QuickActionsSettingsView: View {
    private let settingsService = SettingsService.shared

    @State private var draft: QuickActionsSettings = .defaultValue

    private var hasChanges: Bool {
        draft != settingsService.settings.quickActions
    }

    var body: some View {
        Form {
            mentionableModelsSection
            quickActionsSection

            Section {
                HStack {
                    Button("Reset to Defaults") {
                        draft = .defaultValue
                    }

                    Spacer()

                    Button("Save") {
                        settingsService.updateQuickActions { $0 = draft }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasChanges)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            draft = settingsService.settings.quickActions
        }
    }

    // MARK: - Mentionable Models Section

    private var mentionableModelsSection: some View {
        Section {
            if draft.mentionableModels.isEmpty {
                emptyPlaceholder(
                    icon: "brain.head.profile",
                    message: "No mentionable models yet."
                )
            } else {
                ForEach($draft.mentionableModels) { $model in
                    MentionableModelRow(model: $model, onDelete: {
                        draft.mentionableModels.removeAll { $0.id == model.id }
                    })
                }
            }

            Button {
                let newModel = MentionableModel(
                    label: "",
                    provider: .ollama,
                    modelId: ""
                )
                draft.mentionableModels.append(newModel)
            } label: {
                Label("Add Model", systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Mentionable Models")
            }
        } footer: {
            Text("Models available for @-mention in the chat input. Type @ followed by a model name to switch.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        Section {
            if draft.quickActions.isEmpty {
                emptyPlaceholder(
                    icon: "bolt.fill",
                    message: "No quick actions yet."
                )
            } else {
                ForEach($draft.quickActions) { $action in
                    QuickActionRow(action: $action, onDelete: {
                        draft.quickActions.removeAll { $0.id == action.id }
                    })
                }
            }

            Button {
                let newAction = QuickAction(
                    label: "",
                    prompt: ""
                )
                draft.quickActions.append(newAction)
            } label: {
                Label("Add Action", systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Quick Actions")
            }
        } footer: {
            Text("Actions available for @-mention. The prompt is prepended to your message when selected.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Empty Placeholder

    private func emptyPlaceholder(icon: String, message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
    }
}

// MARK: - Mentionable Model Row

private struct MentionableModelRow: View {
    @Binding var model: MentionableModel
    let onDelete: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 10) {
                Image(systemName: model.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.purple)
                    .frame(width: 24, height: 24)
                    .background(Color.purple.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 1) {
                    Text(model.label.isEmpty ? "New Model" : model.label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(model.label.isEmpty ? .secondary : .primary)

                    Text(model.provider.title + (model.modelId.isEmpty ? "" : " · \(model.modelId)"))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                Toggle("", isOn: $model.isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }

            // Expandable detail
            if isExpanded {
                VStack(spacing: 10) {
                    Divider()

                    HStack(spacing: 8) {
                        Text("Label")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                        TextField("e.g. GPT-4.1 Mini", text: $model.label)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack(spacing: 8) {
                        Text("Provider")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                        Picker("", selection: $model.provider) {
                            ForEach(ProviderKind.allCases) { provider in
                                Text(provider.title).tag(provider)
                            }
                        }
                        .labelsHidden()
                    }

                    HStack(spacing: 8) {
                        Text("Model ID")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                        TextField("e.g. gpt-4.1-mini", text: $model.modelId)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.top, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            if model.label.isEmpty {
                isExpanded = true
            }
        }
    }
}

// MARK: - Quick Action Row

private struct QuickActionRow: View {
    @Binding var action: QuickAction
    let onDelete: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 10) {
                Image(systemName: action.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.orange)
                    .frame(width: 24, height: 24)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 1) {
                    Text(action.label.isEmpty ? "New Action" : action.label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(action.label.isEmpty ? .secondary : .primary)

                    Text(action.prompt.isEmpty ? "No prompt" : action.prompt)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                Toggle("", isOn: $action.isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }

            // Expandable detail
            if isExpanded {
                VStack(spacing: 10) {
                    Divider()

                    HStack(spacing: 8) {
                        Text("Label")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                        TextField("e.g. Summarize", text: $action.label)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack(spacing: 8) {
                        Text("Prompt")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                        TextField("e.g. Summarize the following:", text: $action.prompt)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.top, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            if action.label.isEmpty {
                isExpanded = true
            }
        }
    }
}
