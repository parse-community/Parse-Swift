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

    struct Config: ParseConfig {
        var welcomeMessage: String?
        var winningNumber: Int?
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

    func testCreateParseInstallationOnInit() {
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

        guard let currentInstallation = Installation.current else {
            XCTFail("Should unwrap current Installation")
            return
        }

        // Should be in Keychain
        guard let memoryInstallation: CurrentInstallationContainer<Installation>
            = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                XCTFail("Should get object from Keychain")
            return
        }
        XCTAssertEqual(memoryInstallation.currentInstallation, currentInstallation)

        #if !os(Linux) && !os(Android)
        // Should be in Keychain
        guard let keychainInstallation: CurrentInstallationContainer<Installation>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                XCTFail("Should get object from Keychain")
            return
        }
        XCTAssertEqual(keychainInstallation.currentInstallation, currentInstallation)
        #endif
    }

    #if !os(Linux) && !os(Android)
    func testFetchMissingCurrentInstallation() {
        let memory = InMemoryKeyValueStore()
        ParseStorage.shared.use(memory)
        let installationId = "testMe"
        let badContainer = CurrentInstallationContainer<Installation>(currentInstallation: nil,
                                                                      installationId: installationId)
        Installation.currentContainer = badContainer
        Installation.saveCurrentContainerToKeychain()
        ParseVersion.current = ParseConstants.version

        let expectation1 = XCTestExpectation(description: "Wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            var foundInstallation = Installation()
            foundInstallation.updateAutomaticInfo()
            foundInstallation.objectId = "yarr"
            foundInstallation.installationId = installationId

            let results = QueryResponse<Installation>(results: [foundInstallation], count: 1)
            MockURLProtocol.mockRequests { _ in
                do {
                    let encoded = try ParseCoding.jsonEncoder().encode(results)
                    return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
                } catch {
                    return nil
                }
            }

            guard let url = URL(string: "http://localhost:1337/1") else {
                XCTFail("Should create valid URL")
                return
            }

            ParseSwift.initialize(applicationId: "applicationId",
                                  clientKey: "clientKey",
                                  masterKey: "masterKey",
                                  serverURL: url,
                                  keyValueStore: memory,
                                  testing: true)

            guard let currentInstallation = Installation.current else {
                XCTFail("Should unwrap current Installation")
                expectation1.fulfill()
                return
            }

            XCTAssertEqual(currentInstallation, foundInstallation)

            // Should be in Keychain
            guard let memoryInstallation: CurrentInstallationContainer<Installation>
                = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                    XCTFail("Should get object from Keychain")
                expectation1.fulfill()
                return
            }
            XCTAssertEqual(memoryInstallation.currentInstallation, currentInstallation)

            #if !os(Linux) && !os(Android)
            // Should be in Keychain
            guard let keychainInstallation: CurrentInstallationContainer<Installation>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainInstallation.currentInstallation, currentInstallation)
            #endif
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }
    #endif

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
        Installation.currentContainer.installationId = newInstallation.installationId
        Installation.currentContainer.currentInstallation = newInstallation
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

    func testDontOverwriteOldInstallationBecauseVersionLess() throws {
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        let memory = InMemoryKeyValueStore()
        ParseStorage.shared.use(memory)
        ParseVersion.current = "0.0.0"
        var newInstallation = Installation()
        newInstallation.updateAutomaticInfo()
        newInstallation.installationId = UUID().uuidString.lowercased()
        Installation.currentContainer.installationId = newInstallation.installationId
        Installation.currentContainer.currentInstallation = newInstallation
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
        XCTAssertTrue(installation.hasSameInstallationId(as: newInstallation))
        XCTAssertEqual(ParseVersion.current, ParseConstants.version)
    }

    func testDontOverwriteOldInstallationBecauseVersionEqual() throws {
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        let memory = InMemoryKeyValueStore()
        ParseStorage.shared.use(memory)
        ParseVersion.current = ParseConstants.version
        var newInstallation = Installation()
        newInstallation.updateAutomaticInfo()
        newInstallation.installationId = UUID().uuidString.lowercased()
        Installation.currentContainer.installationId = newInstallation.installationId
        Installation.currentContainer.currentInstallation = newInstallation
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
        XCTAssertTrue(installation.hasSameInstallationId(as: newInstallation))
        XCTAssertEqual(ParseVersion.current, ParseConstants.version)
    }

    func testDontOverwriteOldInstallationBecauseVersionGreater() throws {
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        let memory = InMemoryKeyValueStore()
        ParseStorage.shared.use(memory)
        let newVersion = "1000.0.0"
        ParseVersion.current = newVersion
        var newInstallation = Installation()
        newInstallation.updateAutomaticInfo()
        newInstallation.installationId = UUID().uuidString.lowercased()
        Installation.currentContainer.installationId = newInstallation.installationId
        Installation.currentContainer.currentInstallation = newInstallation
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
        XCTAssertTrue(installation.hasSameInstallationId(as: newInstallation))
        XCTAssertEqual(ParseVersion.current, newVersion)
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
        Installation.currentContainer.installationId = newInstallation.installationId
        Installation.currentContainer.currentInstallation = newInstallation
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
    func testMigrateOldKeychainToNew() throws {
        var user = BaseParseUser()
        user.objectId = "wow"
        var userContainer = CurrentUserContainer<BaseParseUser>()
        userContainer.currentUser = user
        userContainer.sessionToken = "session"
        let installationId = "id"
        var installation = Installation()
        installation.installationId = installationId
        installation.objectId = "now"
        installation.updateAutomaticInfo()
        var installationContainer = CurrentInstallationContainer<Installation>()
        installationContainer.currentInstallation = installation
        installationContainer.installationId = installationId
        let config = Config(welcomeMessage: "hello", winningNumber: 5)
        var configContainer = CurrentConfigContainer<Config>()
        configContainer.currentConfig = config
        var acl = ParseACL()
        acl.setReadAccess(objectId: "hello", value: true)
        acl.setReadAccess(objectId: "wow", value: true)
        acl.setWriteAccess(objectId: "wow", value: true)
        let aclContainer = DefaultACL(defaultACL: acl,
                                      lastCurrentUserObjectId: user.objectId,
                                      useCurrentUser: true)
        let version = "1.9.7"
        try? KeychainStore.old.set(version, for: ParseStorage.Keys.currentVersion)
        try? KeychainStore.old.set(userContainer, for: ParseStorage.Keys.currentUser)
        try? KeychainStore.old.set(installationContainer, for: ParseStorage.Keys.currentInstallation)
        try? KeychainStore.old.set(configContainer, for: ParseStorage.Keys.currentConfig)
        try? KeychainStore.old.set(aclContainer, for: ParseStorage.Keys.defaultACL)
        let expectation1 = XCTestExpectation(description: "Wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let url = URL(string: "http://localhost:1337/1") else {
                XCTFail("Should create valid URL")
                expectation1.fulfill()
                return
            }
            ParseSwift.initialize(applicationId: "applicationId",
                                  clientKey: "clientKey",
                                  masterKey: "masterKey",
                                  serverURL: url)
            XCTAssertEqual(ParseVersion.current, ParseConstants.version)
            XCTAssertEqual(BaseParseUser.current, user)
            XCTAssertEqual(Installation.current, installation)
            XCTAssertEqual(Config.current?.welcomeMessage, config.welcomeMessage)
            XCTAssertEqual(Config.current?.winningNumber, config.winningNumber)
            let defaultACL = try? ParseACL.defaultACL()
            XCTAssertEqual(defaultACL, acl)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

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
        XCTAssertEqual(Installation.currentContainer.installationId, objcInstallationId)
    }

    func testDeleteObjcSDKKeychain() throws {

        //Set keychain the way objc sets keychain
        guard let identifier = Bundle.main.bundleIdentifier else {
            XCTFail("Should have unwrapped")
            return
        }
        let objcInstallationId = "helloWorld"
        let objcParseKeychain = KeychainStore(service: "\(identifier).com.parse.sdk")
        _ = objcParseKeychain.set(object: objcInstallationId, forKey: "installationId")

        guard let retrievedInstallationId: String? = try objcParseKeychain.get(valueFor: "installationId") else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(retrievedInstallationId, objcInstallationId)
        XCTAssertNoThrow(try ParseSwift.deleteObjectiveCKeychain())
        let retrievedInstallationId2: String? = try objcParseKeychain.get(valueFor: "installationId")
        XCTAssertNil(retrievedInstallationId2)

        //This is needed for tear down
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url)
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
        XCTAssertNotNil(Installation.currentContainer.installationId)
        XCTAssertNotEqual(installation.installationId, objcInstallationId)
        XCTAssertNotEqual(Installation.currentContainer.installationId, objcInstallationId)
    }
    #endif
}
