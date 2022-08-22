//
//  ParseKeychainTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/3/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows)
import Foundation
import XCTest
@testable import ParseSwift

class ParseKeychainTests: XCTestCase {

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

    let group = "TEAM.com.parse.parseswift"

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url,
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        #if !os(Linux) && !os(Android) && !os(Windows)
        _ = KeychainStore.shared.removeAllObjects(accessGroup: nil)
        _ = KeychainStore.shared.removeAllObjects(accessGroup: group)
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

    func testNoUserNoAccessGroupNoSync() throws {
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                               accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: nil))
    }

    func testUserNoAccessGroupNoSync() throws {
        try userLogin()
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: nil))
    }

    func testSetAccessGroupWithNoSync() throws {
        try userLogin()
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: nil))
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
                                               accessGroup: "hello"))
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: "hello"))
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: "hello"))
        #endif
        // Since error was thrown, original Keychain should be left intact
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: nil))
    }

    func testSetAccessGroupWithSync() throws {
        try userLogin()
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: nil))
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
                                               accessGroup: "hello"))
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: "hello"))
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: "hello"))
        #endif
        // Since error was thrown, original Keychain should be left intact
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: nil))
    }

    func testSetAccessNilGroupWithSync() throws {
        try userLogin()
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: nil))
        do {
            try ParseSwift.setAccessGroup(nil, synchronizeAcrossDevices: true)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("must be set using"))
        }
        #if !os(macOS)
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                               accessGroup: "hello"))
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: "hello"))
        XCTAssertNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: "hello"))
        #endif
        // Since error was thrown, original Keychain should be left intact
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: nil))
        XCTAssertNotNil(KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                                  accessGroup: nil))
    }
}
#endif
