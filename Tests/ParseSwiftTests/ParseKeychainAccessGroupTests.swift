//
//  ParseKeychainAccessGroupTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/3/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows)
import Foundation
import XCTest
@testable import ParseSwift

class ParseKeychainAccessGroupTests: XCTestCase {

    struct User: ParseUser {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // These are required by ParseUser
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?
    }

    struct LoginSignupResponse: ParseUser {

        var objectId: String?
        var createdAt: Date?
        var sessionToken: String
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // These are required by ParseUser
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?

        init() {
            let date = Date()
            self.createdAt = date
            self.updatedAt = date
            self.objectId = "yarr"
            self.ACL = nil
            self.customKey = "blah"
            self.sessionToken = "myToken"
            self.username = "hello10"
            self.email = "hello@parse.com"
        }
    }

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

        //: Implement your own version of merge
        func merge(with object: Self) throws -> Self {
            var updated = try mergeParse(with: object)
            if updated.shouldRestoreKey(\.customKey,
                                         original: object) {
                updated.customKey = object.customKey
            }
            return updated
        }
    }

    struct Config: ParseConfig {
        var welcomeMessage: String?
        var winningNumber: Int?
    }

    let group = "TEAM.com.parse.parseswift"
    let keychainAccessGroup = ParseKeychainAccessGroup(accessGroup: "TEAM.com.parse.parseswift",
                                                       isSyncingKeychainAcrossDevices: false)
    let keychainAccessGroupSync = ParseKeychainAccessGroup(accessGroup: "TEAM.com.parse.parseswift",
                                                           isSyncingKeychainAcrossDevices: true)
    let helloKeychainAccessGroup = ParseKeychainAccessGroup(accessGroup: "hello",
                                                            isSyncingKeychainAcrossDevices: false)
    let noKeychainAccessGroup = ParseKeychainAccessGroup()

    override func setUpWithError() throws {
        try super.setUpWithError()
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

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        #if !os(Linux) && !os(Android) && !os(Windows)
        _ = KeychainStore.shared.removeAllObjects()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func userLogin() throws {
        let loginResponse = LoginSignupResponse()
        let loginUserName = "hello10"
        let loginPassword = "world"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        _ = try User.login(username: loginUserName, password: loginPassword)
        MockURLProtocol.removeAll()
    }

    func testKeychainAccessGroupCreatedOnServerInit() throws {
        XCTAssertNotNil(ParseKeychainAccessGroup.current)
        XCTAssertNil(ParseSwift.configuration.keychainAccessGroup.accessGroup)
        XCTAssertFalse(ParseSwift.configuration.keychainAccessGroup.isSyncingKeychainAcrossDevices)
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, ParseKeychainAccessGroup.current)
    }

    func testUpdateKeychainAccessGroup() throws {
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, ParseKeychainAccessGroup.current)
        ParseKeychainAccessGroup.current = keychainAccessGroupSync
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, ParseKeychainAccessGroup.current)
        ParseKeychainAccessGroup.current = nil
        XCTAssertEqual(ParseKeychainAccessGroup.current, noKeychainAccessGroup)
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, noKeychainAccessGroup)
        ParseKeychainAccessGroup.current = keychainAccessGroupSync
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, ParseKeychainAccessGroup.current)
    }

    func testCanGetKeychainAccessGroupFromKeychain() throws {
        guard let currentAccessGroup = ParseKeychainAccessGroup.current else {
            XCTFail("Should have unwrapped")
            return
        }
        try ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentAccessGroup)
        XCTAssertEqual(currentAccessGroup, ParseKeychainAccessGroup.current)
    }

    func testDeleteKeychainAccessGroup() throws {
        XCTAssertEqual(ParseKeychainAccessGroup.current, noKeychainAccessGroup)
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, noKeychainAccessGroup)
        ParseKeychainAccessGroup.deleteCurrentContainerFromKeychain()
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, noKeychainAccessGroup)
        XCTAssertNil(ParseKeychainAccessGroup.current)
        ParseKeychainAccessGroup.current = keychainAccessGroup
        XCTAssertEqual(ParseKeychainAccessGroup.current, keychainAccessGroup)
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, keychainAccessGroup)
    }

    func testCanCopyEntireKeychain() throws {
        try userLogin()
        Config.current = .init(welcomeMessage: "yolo", winningNumber: 1)
        _ = try ParseACL.setDefaultACL(ParseACL(), withAccessForCurrentUser: true)
        guard let user: CurrentUserContainer<User> =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let installation: CurrentInstallationContainer<Installation> =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let version: String =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentVersion) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let accessGroup: ParseKeychainAccessGroup =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentAccessGroup) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let config: CurrentConfigContainer<Config> =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let acl: DefaultACL =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.defaultACL) else {
            XCTFail("Should have unwrapped")
            return
        }
        let otherKeychain = KeychainStore(service: "other")
        try otherKeychain.copy(KeychainStore.shared,
                               oldAccessGroup: ParseSwift.configuration.keychainAccessGroup,
                               newAccessGroup: ParseSwift.configuration.keychainAccessGroup)
        guard let otherUser: CurrentUserContainer<User> =
                try? otherKeychain.get(valueFor: ParseStorage.Keys.currentUser) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let otherInstallation: CurrentInstallationContainer<Installation> =
                try? otherKeychain.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let otherVersion: String =
                try? otherKeychain.get(valueFor: ParseStorage.Keys.currentVersion) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let otherAccessGroup: ParseKeychainAccessGroup =
                try? otherKeychain.get(valueFor: ParseStorage.Keys.currentAccessGroup) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let otherConfig: CurrentConfigContainer<Config> =
                try? otherKeychain.get(valueFor: ParseStorage.Keys.currentConfig) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let otherAcl: DefaultACL =
                try? otherKeychain.get(valueFor: ParseStorage.Keys.defaultACL) else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(user, otherUser)
        XCTAssertEqual(installation, otherInstallation)
        XCTAssertEqual(version, otherVersion)
        XCTAssertEqual(accessGroup, otherAccessGroup)
        XCTAssertEqual(config, otherConfig)
        XCTAssertEqual(acl, otherAcl)
    }

    func testRemoveOldObjectsFromKeychain() throws {
        try userLogin()
        Config.current = .init(welcomeMessage: "yolo", winningNumber: 1)
        _ = try ParseACL.setDefaultACL(ParseACL(), withAccessForCurrentUser: true)

        guard let _: CurrentUserContainer<User> =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let _: CurrentInstallationContainer<Installation> =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let _: String =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentVersion) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let _: ParseKeychainAccessGroup =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentAccessGroup) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let _: CurrentConfigContainer<Config> =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let _: DefaultACL =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.defaultACL) else {
            XCTFail("Should have unwrapped")
            return
        }
        let deleted = KeychainStore.shared.removeOldObjects(accessGroup: ParseSwift.configuration.keychainAccessGroup)
        XCTAssertTrue(deleted)
        if let _: CurrentUserContainer<User> =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) {
            XCTFail("Should be nil")
        }
        if let _: CurrentConfigContainer<Config> =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) {
            XCTFail("Should be nil")
        }
        if let _: DefaultACL =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.defaultACL) {
            XCTFail("Should be nil")
        }
        guard let _: CurrentInstallationContainer<Installation> =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let _: String =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentVersion) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let _: ParseKeychainAccessGroup =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentAccessGroup) else {
            XCTFail("Should have unwrapped")
            return
        }
    }

    func testNoUserNoAccessGroupNoSync() throws {
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                               accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: noKeychainAccessGroup))
    }

    func testUserNoAccessGroupNoSync() throws {
        try userLogin()
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: noKeychainAccessGroup))
    }

    func testSetAccessGroupWithNoSync() throws {
        try userLogin()
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: noKeychainAccessGroup))
        #if !os(macOS)
        do {
            try ParseSwift.setAccessGroup(group, synchronizeAcrossDevices: false)
            XCTFail("Should have thrown error due to entitlements")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("-34018"))
        }
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                               accessGroup: helloKeychainAccessGroup))
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: helloKeychainAccessGroup))
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: helloKeychainAccessGroup))
        #endif
        // Since error was thrown, original Keychain should be left intact
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: noKeychainAccessGroup))
    }

    func testSetAccessGroupWithSync() throws {
        try userLogin()
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: noKeychainAccessGroup))
        do {
            try ParseSwift.setAccessGroup(group, synchronizeAcrossDevices: true)
            XCTFail("Should have thrown error due to entitlements")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("-34018"))
        }
        #if !os(macOS)
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                               accessGroup: helloKeychainAccessGroup))
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: helloKeychainAccessGroup))
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: helloKeychainAccessGroup))
        #endif
        // Since error was thrown, original Keychain should be left intact
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: noKeychainAccessGroup))
    }

    func testSetAccessNilGroupWithSync() throws {
        try userLogin()
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: noKeychainAccessGroup))
        do {
            try ParseSwift.setAccessGroup(nil, synchronizeAcrossDevices: true)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("must be set to a valid string"))
        }
        #if !os(macOS)
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                               accessGroup: helloKeychainAccessGroup))
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: helloKeychainAccessGroup))
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: helloKeychainAccessGroup))
        #endif
        // Since error was thrown, original Keychain should be left intact
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: noKeychainAccessGroup))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: noKeychainAccessGroup))
    }

    func testSetAccessGroupWhenNotInit() throws {
        try ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentAccessGroup)
        try KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentAccessGroup)
        do {
            try ParseSwift.setAccessGroup("hello", synchronizeAcrossDevices: true)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            print(parseError)
            XCTAssertTrue(parseError.message.contains("initialize the SDK"))
        }
    }

    func testSetAccessGroupNoChangeInAccessGroup() throws {
        ParseKeychainAccessGroup.current = noKeychainAccessGroup
        try userLogin()
        try ParseSwift.setAccessGroup(noKeychainAccessGroup.accessGroup,
                                      synchronizeAcrossDevices: noKeychainAccessGroup.isSyncingKeychainAcrossDevices)
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, noKeychainAccessGroup)
    }

    func testSetAccessGroupChangeInAccessGroup() throws {
        try userLogin()
        ParseKeychainAccessGroup.current = keychainAccessGroup
        try ParseSwift.setAccessGroup(helloKeychainAccessGroup.accessGroup,
                                      synchronizeAcrossDevices: helloKeychainAccessGroup.isSyncingKeychainAcrossDevices)
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, helloKeychainAccessGroup)
    }
}
#endif
