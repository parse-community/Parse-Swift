//
//  ParseInstallationTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 9/7/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import XCTest
@testable import ParseSwift

class ParseInstallationTests: XCTestCase {

    struct Installation: ParseInstallation {
        var installationId: String?
        var deviceType: String?
        var deviceToken: String?
        var badge: Int?
        var timeZone: String?
        var channels: [String]?
        var appName: String?
        var appIdentifier: String?
        var appVersion: String?
        var parseVersion: String?
        var localeIdentifier: String?
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ACL?
        var customKey: String?
    }

    override func setUp() {
        super.setUp()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url)
    }

    override func tearDown() {
        super.tearDown()
        _ = KeychainStore.shared.removeAllObjects()
    }

    func testNewInstallationIdentifierIsLowercase() {
        guard let installationIdFromContainer
            = Installation.currentInstallationContainer.installationId else {
            XCTFail("Should have retreived installationId from container")
            return
        }

        XCTAssertEqual(installationIdFromContainer, installationIdFromContainer.lowercased())

        guard let installationIdFromCurrent = Installation.current?.installationId else {
            XCTFail("Should have retreived installationId from container")
            return
        }

        XCTAssertEqual(installationIdFromCurrent, installationIdFromCurrent.lowercased())
        XCTAssertEqual(installationIdFromContainer, installationIdFromCurrent)
    }

    func testInstallationMutableValuesCanBeChangedInMemory() {
        guard let originalInstallation = Installation.current else {
            XCTFail("All of these Installation values should have unwraped")
            return
        }

        Installation.current?.customKey = "Changed"
        XCTAssertNotEqual(originalInstallation.customKey, Installation.current?.customKey)
    }

    func testInstallationCustomValuesNotSavedToKeychain() {
        Installation.current?.customKey = "Changed"
        Installation.saveCurrentContainerToKeychain()
        guard let keychainInstallation: CurrentInstallationContainer<Installation>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            return
        }
        XCTAssertNil(keychainInstallation.currentInstallation?.customKey)
    }

    func testInstallationImmutableFieldsCannotBeChangedInMemory() {
        guard let originalInstallation = Installation.current,
            let originalInstallationId = originalInstallation.installationId,
            let originalDeviceType = originalInstallation.deviceType,
            let originalBadge = originalInstallation.badge,
            let originalTimeZone = originalInstallation.timeZone,
            let originalAppName = originalInstallation.appName,
            let originalAppIdentifier = originalInstallation.appIdentifier,
            let originalAppVersion = originalInstallation.appVersion,
            let originalParseVersion = originalInstallation.parseVersion,
            let originalLocaleIdentifier = originalInstallation.localeIdentifier
            else {
                XCTFail("All of these Installation values should have unwraped")
            return
        }

        Installation.current?.installationId = "changed"
        Installation.current?.deviceType = "changed"
        Installation.current?.badge = 500
        Installation.current?.timeZone = "changed"
        Installation.current?.appName = "changed"
        Installation.current?.appIdentifier = "changed"
        Installation.current?.appVersion = "changed"
        Installation.current?.parseVersion = "changed"
        Installation.current?.localeIdentifier = "changed"

        XCTAssertEqual(originalInstallationId, Installation.current?.installationId)
        XCTAssertEqual(originalDeviceType, Installation.current?.deviceType)
        XCTAssertEqual(originalBadge, Installation.current?.badge)
        XCTAssertEqual(originalTimeZone, Installation.current?.timeZone)
        XCTAssertEqual(originalAppName, Installation.current?.appName)
        XCTAssertEqual(originalAppIdentifier, Installation.current?.appIdentifier)
        XCTAssertEqual(originalAppVersion, Installation.current?.appVersion)
        XCTAssertEqual(originalParseVersion, Installation.current?.parseVersion)
        XCTAssertEqual(originalLocaleIdentifier, Installation.current?.localeIdentifier)
    }

    func testInstallationImmutableFieldsCannotBeChangedInKeychain() {
        guard let originalInstallation = Installation.current,
            let originalInstallationId = originalInstallation.installationId,
            let originalDeviceType = originalInstallation.deviceType,
            let originalBadge = originalInstallation.badge,
            let originalTimeZone = originalInstallation.timeZone,
            let originalAppName = originalInstallation.appName,
            let originalAppIdentifier = originalInstallation.appIdentifier,
            let originalAppVersion = originalInstallation.appVersion,
            let originalParseVersion = originalInstallation.parseVersion,
            let originalLocaleIdentifier = originalInstallation.localeIdentifier
            else {
                XCTFail("All of these Installation values should have unwraped")
            return
        }

        Installation.current?.installationId = "changed"
        Installation.current?.deviceType = "changed"
        Installation.current?.badge = 500
        Installation.current?.timeZone = "changed"
        Installation.current?.appName = "changed"
        Installation.current?.appIdentifier = "changed"
        Installation.current?.appVersion = "changed"
        Installation.current?.parseVersion = "changed"
        Installation.current?.localeIdentifier = "changed"

        Installation.saveCurrentContainerToKeychain()

        guard let keychainInstallation: CurrentInstallationContainer<Installation>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            return
        }
        XCTAssertEqual(originalInstallationId, keychainInstallation.currentInstallation?.installationId)
        XCTAssertEqual(originalDeviceType, keychainInstallation.currentInstallation?.deviceType)
        XCTAssertEqual(originalBadge, keychainInstallation.currentInstallation?.badge)
        XCTAssertEqual(originalTimeZone, keychainInstallation.currentInstallation?.timeZone)
        XCTAssertEqual(originalAppName, keychainInstallation.currentInstallation?.appName)
        XCTAssertEqual(originalAppIdentifier, keychainInstallation.currentInstallation?.appIdentifier)
        XCTAssertEqual(originalAppVersion, keychainInstallation.currentInstallation?.appVersion)
        XCTAssertEqual(originalParseVersion, keychainInstallation.currentInstallation?.parseVersion)
        XCTAssertEqual(originalLocaleIdentifier, keychainInstallation.currentInstallation?.localeIdentifier)
    }

    func testInstallationHasApplicationBadge() {
        #if canImport(UIKit) && !os(watchOS)
        UIApplication.shared.applicationIconBadgeNumber = 10
        guard let installationBadge = Installation.current?.badge else {
            XCTFail("Should have retreived badge")
            return
        }
        XCTAssertEqual(installationBadge, 10)
        #elseif canImport(AppKit)
        NSApplication.shared.dockTile.badgeLabel = "10"
        guard let installationBadge = Installation.current?.badge else {
            XCTFail("Should have retreived badge")
            return
        }
        XCTAssertEqual(installationBadge, 10)
        #endif
    }
}
