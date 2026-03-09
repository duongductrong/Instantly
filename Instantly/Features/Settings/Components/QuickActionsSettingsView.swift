import SwiftUI
import UniformTypeIdentifiers

struct QuickActionsSettingsView: View {
    private let settingsService = SettingsService.shared

    @State private var draft: QuickActionsSettings = .defaultValue
    @State private var draggingToolbarActionID: UUID?
    @State private var draggingQuickActionID: UUID?

    private var hasChanges: Bool {
        draft != settingsService.settings.quickActions
    }

    var body: some View {
        Form {
            toolbarActionsSection
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
                    .onDrag {
                        draggingQuickActionID = action.id
                        return NSItemProvider(object: action.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate: ReorderDropDelegate(
                        currentItemID: action.id,
                        items: $draft.quickActions,
                        draggingItemID: $draggingQuickActionID
                    ))
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

    // MARK: - Toolbar Actions Section

    private var toolbarActionsSection: some View {
        Section {
            if draft.toolbarActions.isEmpty {
                emptyPlaceholder(
                    icon: "rectangle.grid.1x2",
                    message: "No toolbar actions yet."
                )
            } else {
                ForEach($draft.toolbarActions) { $action in
                    ToolbarActionRow(action: $action, onDelete: {
                        draft.toolbarActions.removeAll { $0.id == action.id }
                    })
                    .onDrag {
                        draggingToolbarActionID = action.id
                        return NSItemProvider(object: action.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate: ReorderDropDelegate(
                        currentItemID: action.id,
                        items: $draft.toolbarActions,
                        draggingItemID: $draggingToolbarActionID
                    ))
                }
            }

            Button {
                let newAction = ToolbarAction(
                    label: "",
                    prompt: "",
                    actionType: .expand
                )
                draft.toolbarActions.append(newAction)
            } label: {
                Label("Add Toolbar Action", systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.grid.1x2")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Toolbar Actions (⌘E)")
            }
        } footer: {
            Text(
                "Actions shown in the floating toolbar when you press ⌘E. Inline actions replace selected text; Expand actions open the chat window."
            )
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
        }
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
                DragHandle()

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

// MARK: - Toolbar Action Row

private struct ToolbarActionRow: View {
    @Binding var action: ToolbarAction
    let onDelete: () -> Void

    @State private var isExpanded = false

    private var typeColor: Color {
        action.actionType == .inline ? .cyan : .indigo
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 10) {
                DragHandle()

                Image(systemName: action.icon.isEmpty ? "bolt.fill" : action.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(typeColor)
                    .frame(width: 24, height: 24)
                    .background(typeColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(action.label.isEmpty ? "New Toolbar Action" : action.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(action.label.isEmpty ? .secondary : .primary)

                        Text(action.actionType == .inline ? "Inline" : "Expand")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(typeColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(typeColor.opacity(0.12))
                            .clipShape(Capsule())
                    }

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
                        Text("Icon")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                        TextField("SF Symbol name", text: $action.icon)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack(spacing: 8) {
                        Text("Type")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                        Picker("", selection: $action.actionType) {
                            ForEach(ToolbarActionType.allCases) { type in
                                Text(type.title).tag(type)
                            }
                        }
                        .labelsHidden()
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Text("Prompt")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                            .padding(.top, 4)
                        TextEditor(text: $action.prompt)
                            .font(.system(size: 12))
                            .frame(minHeight: 60, maxHeight: 120)
                            .scrollContentBackground(.hidden)
                            .padding(6)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                            )
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

// MARK: - Drag Handle

private struct DragHandle: View {
    @State private var isHovering = false

    var body: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(isHovering ? .secondary : .tertiary)
            .frame(width: 14, height: 20)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.openHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

// MARK: - Reorder Drop Delegate

private struct ReorderDropDelegate<Item: Identifiable>: DropDelegate where Item.ID == UUID {
    let currentItemID: UUID
    @Binding var items: [Item]
    @Binding var draggingItemID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggingID = draggingItemID,
              draggingID != currentItemID,
              let fromIndex = items.firstIndex(where: { $0.id == draggingID }),
              let toIndex = items.firstIndex(where: { $0.id == currentItemID })
        else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingItemID = nil
        return true
    }
}
