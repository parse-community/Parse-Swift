//
//  MigrateObjCSDKCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 8/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if canImport(Combine) && !os(Linux) && !os(Android) && !os(Windows)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class MigrateObjCSDKCombineTests: XCTestCase {
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

    struct UserDefault: ParseUser {

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
    }

    struct LoginSignupResponse: ParseUser {

        var objectId: String?
        var createdAt: Date?
        var sessionToken: String?
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
    }

    struct GameScore: ParseObject {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int?
        var player: String?

        // custom initializers
        init() {}
        init (objectId: String?) {
            self.objectId = objectId
        }
        init(points: Int) {
            self.points = points
            self.player = "Jen"
        }
        init(points: Int, name: String) {
            self.points = points
            self.player = name
        }
    }

    let loginUserName = "hello10"
    let loginPassword = "world"
    let objcInstallationId = "helloWorld"
    let objcSessionToken = "wow"
    let objcSessionToken2 = "now"

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
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        try KeychainStore.objectiveC?.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func setupObjcKeychainSDK(useOldObjCToken: Bool = false,
                              useBothTokens: Bool = false) {

        // Set keychain the way objc sets keychain
        guard let objcParseKeychain = KeychainStore.objectiveC else {
            XCTFail("Should have unwrapped")
            return
        }

        _ = objcParseKeychain.set(object: objcInstallationId, forKey: "installationId")
        if useBothTokens {
            _ = objcParseKeychain.set(object: objcSessionToken, forKey: "sessionToken")
            _ = objcParseKeychain.set(object: objcSessionToken2, forKey: "session_token")
        } else if !useOldObjCToken {
            _ = objcParseKeychain.set(object: objcSessionToken, forKey: "sessionToken")
        } else {
            _ = objcParseKeychain.set(object: objcSessionToken, forKey: "session_token")
        }
    }

    func loginNormally(sessionToken: String) throws -> User {
        var loginResponse = LoginSignupResponse()
        loginResponse.sessionToken = sessionToken

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        return try User.login(username: "parse", password: "user")
    }

    func testLoginUsingObjCKeychain() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Login")

        setupObjcKeychainSDK()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = objcSessionToken
        serverResponse.username = loginUserName

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let publisher = User.loginUsingObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { loggedIn in
            XCTAssertEqual(loggedIn.updatedAt, serverResponse.updatedAt)
            XCTAssertEqual(loggedIn.email, serverResponse.email)
            XCTAssertEqual(loggedIn.username, self.loginUserName)
            XCTAssertNil(loggedIn.password)
            XCTAssertEqual(loggedIn.objectId, serverResponse.objectId)
            XCTAssertEqual(loggedIn.sessionToken, self.objcSessionToken)
            XCTAssertEqual(loggedIn.customKey, serverResponse.customKey)
            XCTAssertNil(loggedIn.ACL)

            guard let userFromKeychain = User.current else {
                XCTFail("Could not get CurrentUser from Keychain")
                expectation1.fulfill()
                return
            }

            XCTAssertEqual(loggedIn.updatedAt, userFromKeychain.updatedAt)
            XCTAssertEqual(loggedIn.email, userFromKeychain.email)
            XCTAssertEqual(userFromKeychain.username, self.loginUserName)
            XCTAssertNil(userFromKeychain.password)
            XCTAssertEqual(loggedIn.objectId, userFromKeychain.objectId)
            XCTAssertEqual(userFromKeychain.sessionToken, self.objcSessionToken)
            XCTAssertEqual(loggedIn.customKey, userFromKeychain.customKey)
            XCTAssertNil(userFromKeychain.ACL)
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginUsingObjCKeychainOldSessionTokenKey() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Login")

        setupObjcKeychainSDK(useOldObjCToken: true)

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = objcSessionToken
        serverResponse.username = loginUserName

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let publisher = User.loginUsingObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { loggedIn in
            XCTAssertEqual(loggedIn.updatedAt, serverResponse.updatedAt)
            XCTAssertEqual(loggedIn.email, serverResponse.email)
            XCTAssertEqual(loggedIn.username, self.loginUserName)
            XCTAssertNil(loggedIn.password)
            XCTAssertEqual(loggedIn.objectId, serverResponse.objectId)
            XCTAssertEqual(loggedIn.sessionToken, self.objcSessionToken)
            XCTAssertEqual(loggedIn.customKey, serverResponse.customKey)
            XCTAssertNil(loggedIn.ACL)

            guard let userFromKeychain = User.current else {
                XCTFail("Could not get CurrentUser from Keychain")
                expectation1.fulfill()
                return
            }

            XCTAssertEqual(loggedIn.updatedAt, userFromKeychain.updatedAt)
            XCTAssertEqual(loggedIn.email, userFromKeychain.email)
            XCTAssertEqual(userFromKeychain.username, self.loginUserName)
            XCTAssertNil(userFromKeychain.password)
            XCTAssertEqual(loggedIn.objectId, userFromKeychain.objectId)
            XCTAssertEqual(userFromKeychain.sessionToken, self.objcSessionToken)
            XCTAssertEqual(loggedIn.customKey, userFromKeychain.customKey)
            XCTAssertNil(userFromKeychain.ACL)
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginUsingObjCKeychainUseNewOverOld() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Login")

        setupObjcKeychainSDK(useBothTokens: true)

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = objcSessionToken
        serverResponse.username = loginUserName

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let publisher = User.loginUsingObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { loggedIn in
            XCTAssertEqual(loggedIn.updatedAt, serverResponse.updatedAt)
            XCTAssertEqual(loggedIn.email, serverResponse.email)
            XCTAssertEqual(loggedIn.username, self.loginUserName)
            XCTAssertNil(loggedIn.password)
            XCTAssertEqual(loggedIn.objectId, serverResponse.objectId)
            XCTAssertEqual(loggedIn.sessionToken, self.objcSessionToken)
            XCTAssertEqual(loggedIn.customKey, serverResponse.customKey)
            XCTAssertNil(loggedIn.ACL)

            guard let userFromKeychain = User.current else {
                XCTFail("Could not get CurrentUser from Keychain")
                expectation1.fulfill()
                return
            }

            XCTAssertEqual(loggedIn.updatedAt, userFromKeychain.updatedAt)
            XCTAssertEqual(loggedIn.email, userFromKeychain.email)
            XCTAssertEqual(userFromKeychain.username, self.loginUserName)
            XCTAssertNil(userFromKeychain.password)
            XCTAssertEqual(loggedIn.objectId, userFromKeychain.objectId)
            XCTAssertEqual(userFromKeychain.sessionToken, self.objcSessionToken)
            XCTAssertEqual(loggedIn.customKey, userFromKeychain.customKey)
            XCTAssertNil(userFromKeychain.ACL)
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginUsingObjCKeychainNoKeychain() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Login")

        let publisher = User.loginUsingObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTAssertTrue(error.message.contains("Objective-C"))
                    expectation1.fulfill()
                    return
                } else {
                    XCTFail("Should have thrown error")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown error")
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginUsingObjCKeychainAlreadyLoggedIn() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Login")

        setupObjcKeychainSDK()
        let currentUser = try loginNormally(sessionToken: objcSessionToken)
        MockURLProtocol.removeAll()

        let publisher = User.loginUsingObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { returnedUser in
            XCTAssertTrue(currentUser.hasSameObjectId(as: returnedUser))
            XCTAssertEqual(currentUser.sessionToken, returnedUser.sessionToken)
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginUsingObjCKeychainAlreadyLoggedInWithDiffererentSession() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Login")

        setupObjcKeychainSDK()
        _ = try loginNormally(sessionToken: objcSessionToken2)
        MockURLProtocol.removeAll()

        let publisher = User.loginUsingObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTAssertTrue(error.message.contains("different"))
                    expectation1.fulfill()
                    return
                } else {
                    XCTFail("Should have thrown error")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown error")
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }
}
#endif
