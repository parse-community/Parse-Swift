//
//  InitializeSDKTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/3/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import XCTest
@testable import ParseSwift

class InitializeSDKTests: XCTestCase {

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
        var ACL: ParseACL?
        var customKey: String?
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android)
        try KeychainStore.shared.deleteAll()
        if let identifier = Bundle.main.bundleIdentifier {
            try KeychainStore(service: "\(identifier).com.parse.sdk").deleteAll()
        }
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testUpdateAuthChallenge() {
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }

        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url) { (_, credential) in
            credential(.performDefaultHandling, nil)
        }
        XCTAssertNotNil(ParseSwift.sessionDelegate.authentication)
        ParseSwift.updateAuthentication(nil)
        XCTAssertNil(ParseSwift.sessionDelegate.authentication)
    }

    #if !os(Linux) && !os(Android)
    func testDontOverwriteMigratedInstallation() throws {
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        let memory = InMemoryKeyValueStore()
        ParseStorage.shared.use(memory)
        var newInstallation = Installation()
        newInstallation.updateAutomaticInfo()
        newInstallation.objectId = "yarr"
        newInstallation.installationId = UUID().uuidString.lowercased()
        Installation.currentInstallationContainer.installationId = newInstallation.installationId
        Installation.currentInstallationContainer.currentInstallation = newInstallation
        Installation.saveCurrentContainerToKeychain()

        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url,
                              keyValueStore: memory)
        guard let installation = Installation.current else {
            XCTFail("Should have installation")
            return
        }
        XCTAssertTrue(installation.hasSameObjectId(as: newInstallation))
        XCTAssertTrue(installation.hasSameInstallationId(as: newInstallation))
    }
    #endif

    func testOverwriteOldInstallation() throws {
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        let memory = InMemoryKeyValueStore()
        ParseStorage.shared.use(memory)
        var newInstallation = Installation()
        newInstallation.updateAutomaticInfo()
        newInstallation.installationId = UUID().uuidString.lowercased()
        Installation.currentInstallationContainer.installationId = newInstallation.installationId
        Installation.currentInstallationContainer.currentInstallation = newInstallation
        Installation.saveCurrentContainerToKeychain()

        XCTAssertNil(newInstallation.objectId)
        guard let oldInstallation = Installation.current else {
            XCTFail("Should have installation")
            return
        }
        XCTAssertTrue(oldInstallation.hasSameInstallationId(as: newInstallation))

        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url,
                              keyValueStore: memory)
        guard let installation = Installation.current else {
            XCTFail("Should have installation")
            return
        }
        XCTAssertFalse(installation.hasSameInstallationId(as: newInstallation))
    }

    func testMigrateObjcKeychainMissing() {
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url,
                              migrateFromObjcSDK: true)
        guard let installation = Installation.current else {
            XCTFail("Should have installation")
            return
        }
        XCTAssertNotNil(installation.installationId)
    }

    #if !os(Linux) && !os(Android)
    func testMigrateObjcSDK() {

        //Set keychain the way objc sets keychain
        guard let identifier = Bundle.main.bundleIdentifier else {
            XCTFail("Should have unwrapped")
            return
        }
        let objcInstallationId = "helloWorld"
        let objcParseKeychain = KeychainStore(service: "\(identifier).com.parse.sdk")
        _ = objcParseKeychain.set(object: objcInstallationId, forKey: "installationId")

        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url,
                              migrateFromObjcSDK: true)
        guard let installation = Installation.current else {
            XCTFail("Should have installation")
            return
        }
        XCTAssertEqual(installation.installationId, objcInstallationId)
        XCTAssertEqual(Installation.currentInstallationContainer.installationId, objcInstallationId)
    }

    func testMigrateObjcSDKMissingInstallation() {

        //Set keychain the way objc sets keychain
        guard let identifier = Bundle.main.bundleIdentifier else {
            XCTFail("Should have unwrapped")
            return
        }
        let objcInstallationId = "helloWorld"
        let objcParseKeychain = KeychainStore(service: "\(identifier).com.parse.sdk")
        _ = objcParseKeychain.set(object: objcInstallationId, forKey: "anotherPlace")

        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url,
                              migrateFromObjcSDK: true)
        guard let installation = Installation.current else {
            XCTFail("Should have installation")
            return
        }
        XCTAssertNotNil(installation.installationId)
        XCTAssertNotNil(Installation.currentInstallationContainer.installationId)
        XCTAssertNotEqual(installation.installationId, objcInstallationId)
        XCTAssertNotEqual(Installation.currentInstallationContainer.installationId, objcInstallationId)
    }
    #endif
}
