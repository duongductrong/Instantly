@testable import Instantly
import XCTest

final class InfoPlistValidationTests: XCTestCase {
    func testInfoPlistContainsSUFeedURL() throws {
        let url = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String
        XCTAssertNotNil(url, "SUFeedURL must be set")
        XCTAssertTrue(try XCTUnwrap(url?.hasPrefix("https://")), "Feed URL must use HTTPS")
    }

    func testInfoPlistContainsSUPublicEDKey() throws {
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        XCTAssertNotNil(key, "SUPublicEDKey must be set")
        XCTAssertFalse(try XCTUnwrap(key?.isEmpty), "SUPublicEDKey must not be empty")
        XCTAssertNotEqual(key, "PLACEHOLDER_REPLACE_WITH_EDDSA_PUBLIC_KEY", "SUPublicEDKey must not be placeholder")
    }

    func testInfoPlistContainsCFBundleVersion() throws {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        XCTAssertNotNil(version, "CFBundleVersion must be set")
        XCTAssertGreaterThan(try Int(XCTUnwrap(version)) ?? 0, 0, "CFBundleVersion must be a positive integer")
    }

    func testInfoPlistContainsCFBundleShortVersionString() throws {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        XCTAssertNotNil(version, "CFBundleShortVersionString must be set")
        XCTAssertFalse(try XCTUnwrap(version?.isEmpty), "CFBundleShortVersionString must not be empty")
    }
}

final class UpdateServiceTests: XCTestCase {
    func testUpdateServiceIsSingleton() {
        let service1 = UpdateService.shared
        let service2 = UpdateService.shared
        XCTAssertTrue(service1 === service2, "UpdateService must be a singleton")
    }

    func testUpdaterControllerNotNil() {
        let service = UpdateService.shared
        XCTAssertNotNil(service.updaterController, "SPUStandardUpdaterController must not be nil")
    }

    func testUpdaterNotNil() {
        let service = UpdateService.shared
        XCTAssertNotNil(service.updater, "SPUUpdater must not be nil")
    }

    func testCheckForUpdatesDoesNotCrash() {
        let service = UpdateService.shared
        XCTAssertNoThrow(service.checkForUpdates())
    }
}
