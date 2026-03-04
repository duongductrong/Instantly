import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationSplitView {
            SettingsSidebarView(selectedSection: selectedSectionBinding)
        } detail: {
            selectedSectionContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ProPalette.detailBackground)
        }
        .navigationSplitViewColumnWidth(min: 300, ideal: 320, max: 360)
        .navigationSplitViewStyle(.balanced)
        .toolbar(.hidden, for: .windowToolbar)
        .background(ProPalette.detailBackground)
        .ignoresSafeArea(.container, edges: .top)
        .preferredColorScheme(.dark)
    }

    private var selectedSectionBinding: Binding<SettingsViewModel.Section?> {
        Binding(
            get: { viewModel.selectedSection },
            set: { newValue in
                if let newValue {
                    viewModel.selectedSection = newValue
                }
            }
        )
    }

    private var selectedSectionContent: some View {
        ProToolSettingsDetailView(selectedSection: viewModel.selectedSection)
    }
}

private struct ProToolSettingsDetailView: View {
    let selectedSection: SettingsViewModel.Section

    private let events: [ReplayEvent] = [
        ReplayEvent(time: "+0:01", icon: "sparkles", type: .ai, text: "plan session.replay.trace --window=120s"),
        ReplayEvent(
            time: "+0:06",
            icon: "wrench.and.screwdriver.fill",
            type: .write,
            text: "write Instantly/Features/Settings/SettingsView.swift"
        ),
        ReplayEvent(
            time: "+0:12",
            icon: "sparkles",
            type: .ai,
            text: "summarize activity burst and annotate anomalies"
        ),
        ReplayEvent(
            time: "+0:19",
            icon: "wrench.and.screwdriver.fill",
            type: .write,
            text: "write Instantly/Features/Settings/Components/SettingsSidebarView.swift"
        ),
        ReplayEvent(time: "+0:27", icon: "sparkles", type: .ai, text: "generate waveform color map logic"),
        ReplayEvent(
            time: "+0:35",
            icon: "wrench.and.screwdriver.fill",
            type: .write,
            text: "write Instantly/Services/SettingsWindowController.swift"
        ),
        ReplayEvent(time: "+0:44", icon: "sparkles", type: .ai, text: "refine dense event feed typography"),
        ReplayEvent(
            time: "+0:56",
            icon: "wrench.and.screwdriver.fill",
            type: .write,
            text: "write command xcodebuild -project Instantly.xcodeproj -scheme Instantly"
        ),
        ReplayEvent(time: "+1:08", icon: "sparkles", type: .ai, text: "verify visual parity against pro-tool target"),
        ReplayEvent(
            time: "+1:16",
            icon: "wrench.and.screwdriver.fill",
            type: .write,
            text: "write final replay metadata and status markers"
        ),
    ]

    private let metricItems: [ReplayMetric] = [
        ReplayMetric(icon: "terminal", value: "24"),
        ReplayMetric(icon: "doc.text.fill", value: "6"),
        ReplayMetric(icon: "wrench.and.screwdriver.fill", value: "11"),
        ReplayMetric(icon: "sparkles", value: "17"),
        ReplayMetric(icon: "clock", value: "01:23"),
        ReplayMetric(icon: "bolt.fill", value: "3.2k"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            activityVisualizerCard
            metadataCard
            eventLogCard
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ProPalette.detailBackground)
    }

    private var header: some View {
        ZStack {
            Text("Session Replay")
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            HStack {
                Text("< Sessions")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ProPalette.blue)

                Spacer()

                Text(statusText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private var activityVisualizerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Visualizer")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            WaveformVisualizerView()
                .frame(height: 160)

            HStack(spacing: 8) {
                PlaybackChip(title: "Play", icon: "play.fill", isActive: true)
                PlaybackChip(title: "1x", icon: nil, isActive: false)
                PlaybackChip(title: "2x", icon: nil, isActive: false)
                PlaybackChip(title: "4x", icon: nil, isActive: false)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ProPalette.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                "Replay task: sync session annotations with command timeline and resolve divergence across recent tool-write bursts."
            )
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(.white.opacity(0.92))
            .lineSpacing(2)

            HStack(spacing: 8) {
                MetadataBadge(title: "aurora-api", color: ProPalette.blue)
                MetadataBadge(title: "Opus 4.6", color: ProPalette.yellow)
                MetadataBadge(title: "Replay Core", color: Color.white.opacity(0.65))
            }

            HStack(spacing: 12) {
                ForEach(metricItems) { item in
                    HStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 10, weight: .semibold))
                        Text(item.value)
                            .font(.system(size: 11, weight: .medium))
                            .monospaced()
                    }
                    .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ProPalette.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var eventLogCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Event Log")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(events) { event in
                        ReplayEventRow(event: event)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ProPalette.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var statusText: String {
        switch selectedSection {
        case .assistant:
            "38"
        case .model:
            "42"
        case .system:
            "35"
        }
    }
}

private struct WaveformVisualizerView: View {
    private let bars = WaveformBar.makeBars(count: 140)
    private let progress: CGFloat = 0.58

    var body: some View {
        GeometryReader { proxy in
            let horizontalInset: CGFloat = 14
            let playheadX = horizontalInset + ((proxy.size.width - (horizontalInset * 2)) * progress)

            ZStack(alignment: .bottomLeading) {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(bars) { bar in
                        Capsule(style: .continuous)
                            .fill(bar.color)
                            .frame(width: 3, height: bar.height)
                            .shadow(color: bar.glowColor, radius: bar.glowRadius, x: 0, y: 0)
                    }
                }
                .padding(.horizontal, horizontalInset)
                .padding(.vertical, 18)

                Rectangle()
                    .fill(ProPalette.blue.opacity(0.9))
                    .frame(width: 1, height: proxy.size.height - 20)
                    .position(x: playheadX, y: proxy.size.height / 2)

                Circle()
                    .stroke(ProPalette.blue, lineWidth: 2)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(ProPalette.waveformBackground)
                    )
                    .overlay {
                        Image(systemName: "hand.point.up.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(ProPalette.blue)
                    }
                    .position(x: playheadX, y: 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ProPalette.waveformBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }
}

private struct PlaybackChip: View {
    let title: String
    let icon: String?
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .monospaced()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(isActive ? Color.white.opacity(0.9) : Color.secondary)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(isActive ? 0.12 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct MetadataBadge: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(color.opacity(0.92))
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.16))
            )
    }
}

private struct ReplayEventRow: View {
    let event: ReplayEvent

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(event.time)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .monospaced()
                .foregroundStyle(ProPalette.mutedBlue)
                .frame(width: 58, alignment: .leading)

            Image(systemName: event.icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(event.type == .write ? ProPalette.yellow : ProPalette.blue)
                .frame(width: 14)

            Text(event.text)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .monospaced()
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }
}

private struct ReplayEvent: Identifiable {
    let id = UUID()
    let time: String
    let icon: String
    let type: ReplayEventType
    let text: String
}

private enum ReplayEventType {
    case write
    case ai
}

private struct ReplayMetric: Identifiable {
    let id = UUID()
    let icon: String
    let value: String
}

private struct WaveformBar: Identifiable {
    enum Tone {
        case yellow
        case blue
        case muted
    }

    let id: Int
    let height: CGFloat
    let tone: Tone

    var color: Color {
        switch tone {
        case .yellow:
            ProPalette.yellow
        case .blue:
            ProPalette.blue
        case .muted:
            ProPalette.mutedGray
        }
    }

    var glowColor: Color {
        switch tone {
        case .yellow:
            ProPalette.yellow.opacity(0.85)
        case .blue:
            ProPalette.blue.opacity(0.8)
        case .muted:
            .clear
        }
    }

    var glowRadius: CGFloat {
        switch tone {
        case .yellow, .blue:
            3
        case .muted:
            0
        }
    }

    static func makeBars(count: Int) -> [WaveformBar] {
        (0 ..< count).map { index in
            let progress = Double(index) / Double(max(1, count - 1))
            let burstA = max(0, sin((progress * 9.5 - 0.8) * .pi))
            let burstB = max(0, sin((progress * 12.8 + 0.35) * .pi))
            let burstC = max(0, sin((progress * 7.2 + 1.5) * .pi))
            let envelope = (burstA * 0.46) + (burstB * 0.36) + (burstC * 0.18)
            let jitter = Double((index * 31 + 11) % 19) / 19.0
            let activity = min(1.0, envelope * 0.84 + (jitter * 0.16))
            let height = CGFloat(12 + (activity * 78))

            let tone: Tone = if activity > 0.7 {
                .yellow
            } else if activity > 0.44 {
                .blue
            } else {
                .muted
            }

            return WaveformBar(id: index, height: height, tone: tone)
        }
    }
}

private enum ProPalette {
    static let detailBackground = Color(hex: 0x0D0D0E)
    static let cardBackground = Color(hex: 0x17171A)
    static let waveformBackground = Color(hex: 0x111114)
    static let blue = Color(hex: 0x007AFF)
    static let yellow = Color(hex: 0xFFD60A)
    static let mutedGray = Color(hex: 0x3A3A3C)
    static let mutedBlue = Color(hex: 0x6B89AF)
}

private extension Color {
    init(hex: Int, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
