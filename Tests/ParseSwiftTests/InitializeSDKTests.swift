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
        var originalData: Data?
        var customKey: String?
    }

    struct Config: ParseConfig {
        var welcomeMessage: String?
        var winningNumber: Int?
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        Parse.configuration = .init(applicationId: "applicationId",
                                    primaryKey: "primaryKey",
                                    serverURL: url)
        Parse.configuration.isTestingSDK = true
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        try KeychainStore.objectiveC?.deleteAllObjectiveC()
        try KeychainStore.old.deleteAll()
        URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func addCachedResponse() {
        if URLSession.parse.configuration.urlCache == nil {
            URLSession.parse.configuration.urlCache = .init()
        }
        guard let server = URL(string: "http://parse.com"),
              let data = "Test".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }

        let response = URLResponse(url: server, mimeType: nil,
                                   expectedContentLength: data.count,
                                   textEncodingName: nil)
        URLSession.parse.configuration.urlCache?
            .storeCachedResponse(.init(response: response,
                                       data: data),
                                 for: .init(url: server))
        guard let currentCache = URLSession.parse.configuration.urlCache else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertTrue(currentCache.currentMemoryUsage > 0)
    }
/*
    func testDeleteKeychainOnFirstRun() throws {
        let memory = InMemoryKeyValueStore()
        ParseStorage.shared.use(memory)
        guard let server = URL(string: "http://parse.com") else {
            XCTFail("Should have unwrapped")
            return
        }
        Parse.configuration = ParseConfiguration(applicationId: "yo",
                                                      serverURL: server,
                                                      isDeletingKeychainIfNeeded: false)
        let key = "Hello"
        let value = "World"
        try KeychainStore.shared.set(value, for: key)
        addCachedResponse()

        // Keychain should contain value on first run
        ParseSwift.deleteKeychainIfNeeded()

        do {
            let storedValue: String? = try KeychainStore.shared.get(valueFor: key)
            XCTAssertEqual(storedValue, value)
            guard let firstRun = UserDefaults.standard.object(forKey: ParseConstants.bundlePrefix) as? String else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssertEqual(firstRun, ParseConstants.bundlePrefix)

            // Keychain should remain unchanged on 2+ runs
            ParseSwift.configuration.isDeletingKeychainIfNeeded = true
            ParseSwift.deleteKeychainIfNeeded()
            let storedValue2: String? = try KeychainStore.shared.get(valueFor: key)
            XCTAssertEqual(storedValue2, value)
            guard let firstRun2 = UserDefaults.standard
                    .object(forKey: ParseConstants.bundlePrefix) as? String else {
                        XCTFail("Should have unwrapped")
                        return
                    }
            XCTAssertEqual(firstRun2, ParseConstants.bundlePrefix)

            // Keychain should delete on first run
            UserDefaults.standard.removeObject(forKey: ParseConstants.bundlePrefix)
            UserDefaults.standard.synchronize()
            let firstRun3 = UserDefaults.standard.object(forKey: ParseConstants.bundlePrefix) as? String
            XCTAssertNil(firstRun3)
            addCachedResponse()
            ParseSwift.deleteKeychainIfNeeded()
            let storedValue3: String? = try KeychainStore.shared.get(valueFor: key)
            XCTAssertNil(storedValue3)
            guard let firstRun4 = UserDefaults.standard
                    .object(forKey: ParseConstants.bundlePrefix) as? String else {
                        XCTFail("Should have unwrapped")
                        return
                    }
            XCTAssertEqual(firstRun4, ParseConstants.bundlePrefix)

            guard let currentCache = URLSession.parse.configuration.urlCache else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssertTrue(currentCache.currentMemoryUsage == 0)
        } catch {
            XCTFail("\(error)")
        }
    }*/
    #endif

    func testCreateParseInstallationOnInit() {
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }

        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              primaryKey: "primaryKey",
                              serverURL: url,
                              testing: true) { (_, credential) in
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

        #if !os(Linux) && !os(Android) && !os(Windows)
        // Should be in Keychain
        guard let keychainInstallation: CurrentInstallationContainer<Installation>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                XCTFail("Should get object from Keychain")
            return
        }
        XCTAssertEqual(keychainInstallation.currentInstallation, currentInstallation)
        #endif
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testFetchMissingCurrentInstallation() {
        let memory = InMemoryKeyValueStore()
        ParseStorage.shared.use(memory)
        let installationId = "testMe"
        let badContainer = CurrentInstallationContainer<Installation>(currentInstallation: nil,
                                                                      installationId: installationId)
        Installation.currentContainer = badContainer
        Installation.saveCurrentContainerToKeychain()
        ParseVersion.current = ParseConstants.version

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

        let expectation1 = XCTestExpectation(description: "Wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {

            guard let url = URL(string: "http://localhost:1337/1") else {
                XCTFail("Should create valid URL")
                expectation1.fulfill()
                return
            }

            ParseSwift.initialize(applicationId: "applicationId",
                                  clientKey: "clientKey",
                                  primaryKey: "primaryKey",
                                  serverURL: url,
                                  primitiveStore: memory,
                                  testing: true)

            guard let currentInstallation = Installation.current else {
                XCTFail("Should unwrap current Installation")
                expectation1.fulfill()
                return
            }

            XCTAssertEqual(currentInstallation.installationId, installationId)

            // Should be in Keychain
            guard let memoryInstallation: CurrentInstallationContainer<Installation>
                = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                    XCTFail("Should get object from Keychain")
                expectation1.fulfill()
                return
            }
            XCTAssertEqual(memoryInstallation.currentInstallation, currentInstallation)

            // Should be in Keychain
            guard let keychainInstallation: CurrentInstallationContainer<Installation>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                    XCTFail("Should get object from Keychain")
                    expectation1.fulfill()
                return
            }
            XCTAssertEqual(keychainInstallation.currentInstallation, currentInstallation)
            MockURLProtocol.removeAll()
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
                              primaryKey: "primaryKey",
                              serverURL: url,
                              testing: true) { (_, credential) in
            credential(.performDefaultHandling, nil)
        }
        XCTAssertNotNil(Parse.sessionDelegate.authentication)
        ParseSwift.updateAuthentication(nil)
        XCTAssertNil(Parse.sessionDelegate.authentication)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
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
                              primaryKey: "primaryKey",
                              serverURL: url,
                              primitiveStore: memory,
                              testing: true)
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
                              primaryKey: "primaryKey",
                              serverURL: url,
                              primitiveStore: memory,
                              testing: true)
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
                              primaryKey: "primaryKey",
                              serverURL: url,
                              primitiveStore: memory,
                              testing: true)
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
                              primaryKey: "primaryKey",
                              serverURL: url,
                              primitiveStore: memory,
                              testing: true)
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
                              primaryKey: "primaryKey",
                              serverURL: url,
                              primitiveStore: memory,
                              testing: true)
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
                              primaryKey: "primaryKey",
                              serverURL: url,
                              migratingFromObjcSDK: true,
                              testing: true)
        guard let installation = Installation.current else {
            XCTFail("Should have installation")
            return
        }
        XCTAssertNotNil(installation.installationId)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
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
                                  primaryKey: "primaryKey",
                                  serverURL: url,
                                  testing: true)
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

        // Set keychain the way objc sets keychain
        guard let objcParseKeychain = KeychainStore.objectiveC else {
            XCTFail("Should have unwrapped")
            return
        }
        let objcInstallationId = "helloWorld"
        _ = objcParseKeychain.setObjectiveC(object: objcInstallationId, forKey: "installationId")

        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              primaryKey: "primaryKey",
                              serverURL: url,
                              migratingFromObjcSDK: true,
                              testing: true)
        guard let installation = Installation.current else {
            XCTFail("Should have installation")
            return
        }
        XCTAssertEqual(installation.installationId, objcInstallationId)
        XCTAssertEqual(Installation.currentContainer.installationId, objcInstallationId)
    }

    #if !os(macOS)
    func testInitializeSDKNoTest() {

        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              primaryKey: "primaryKey",
                              serverURL: url)
        guard Installation.current != nil else {
            XCTFail("Should have installation")
            return
        }
    }
    #endif

    func testDeleteObjcSDKKeychain() throws {

        //Set keychain the way objc sets keychain
        guard let objcParseKeychain = KeychainStore.objectiveC else {
            XCTFail("Should have unwrapped")
            return
        }
        let objcInstallationId = "helloWorld"
        _ = objcParseKeychain.setObjectiveC(object: objcInstallationId, forKey: "installationId")

        guard let retrievedInstallationId: String? = objcParseKeychain.objectObjectiveC(forKey: "installationId") else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(retrievedInstallationId, objcInstallationId)
        XCTAssertNoThrow(try ParseSwift.deleteObjectiveCKeychain())
        let retrievedInstallationId2: String? = objcParseKeychain.objectObjectiveC(forKey: "installationId")
        XCTAssertNil(retrievedInstallationId2)

        //This is needed for tear down
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              primaryKey: "primaryKey",
                              serverURL: url,
                              testing: true)
    }

    func testMigrateObjcSDKMissingInstallation() {

        //Set keychain the way objc sets keychain
        guard let objcParseKeychain = KeychainStore.objectiveC else {
            XCTFail("Should have unwrapped")
            return
        }
        let objcInstallationId = "helloWorld"
        _ = objcParseKeychain.setObjectiveC(object: objcInstallationId, forKey: "anotherPlace")

        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              primaryKey: "primaryKey",
                              serverURL: url,
                              migratingFromObjcSDK: true,
                              testing: true)
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
