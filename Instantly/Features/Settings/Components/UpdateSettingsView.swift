import Combine
import Sparkle
import SwiftUI

final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false
    private var cancellable: AnyCancellable?

    init(updater: SPUUpdater) {
        self.cancellable = updater.publisher(for: \.canCheckForUpdates)
            .sink { [weak self] value in
                self?.canCheckForUpdates = value
            }
    }
}

struct UpdateSettingsView: View {
    private let updater: SPUUpdater
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel

    init() {
        let service = UpdateService.shared
        self.updater = service.updater
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: service.updater)
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("Check for Updates…") {
                            updater.checkForUpdates()
                        }
                        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
                    }
                }
            }

            Section {
                Toggle("Automatically check for updates", isOn: Binding(
                    get: { updater.automaticallyChecksForUpdates },
                    set: { updater.automaticallyChecksForUpdates = $0 }
                ))

                Toggle("Automatically download updates", isOn: Binding(
                    get: { updater.automaticallyDownloadsUpdates },
                    set: { updater.automaticallyDownloadsUpdates = $0 }
                ))
            }

            Section {
                HStack {
                    Text("Feed URL")
                        .font(.system(size: 12))
                    Spacer()
                    Text(feedURL)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var feedURL: String {
        Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String ?? "Not set"
    }
}
