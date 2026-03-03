import Foundation
import ServiceManagement

enum LaunchAtLoginService {
    enum LaunchAtLoginError: LocalizedError {
        case notSupported
        case registerFailed(Error)
        case unregisterFailed(Error)

        var errorDescription: String? {
            switch self {
            case .notSupported:
                "Launch at login is not available in this build."
            case let .registerFailed(error):
                "Failed to enable launch at login: \(error.localizedDescription)"
            case let .unregisterFailed(error):
                "Failed to disable launch at login: \(error.localizedDescription)"
            }
        }
    }

    static func isEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        switch SMAppService.mainApp.status {
        case .notRegistered:
            throw LaunchAtLoginError.notSupported
        default:
            break
        }

        if enabled {
            guard !isEnabled() else { return }
            do {
                try SMAppService.mainApp.register()
            } catch {
                throw LaunchAtLoginError.registerFailed(error)
            }
        } else {
            guard isEnabled() else { return }
            do {
                try SMAppService.mainApp.unregister()
            } catch {
                throw LaunchAtLoginError.unregisterFailed(error)
            }
        }
    }
}
