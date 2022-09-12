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

    let loginUserName = "hello10"
    let loginPassword = "world"
    let objcInstallationId = "helloWorld"
    let objcSessionToken = "wow"
    let objcSessionToken2 = "now"
    let testInstallationObjectId = "yarr"

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
        try KeychainStore.objectiveC?.deleteAllObjectiveC()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func setupObjcKeychainSDK(useOldObjCToken: Bool = false,
                              useBothTokens: Bool = false,
                              installationId: String) {

        // Set keychain the way objc sets keychain
        guard let objcParseKeychain = KeychainStore.objectiveC else {
            XCTFail("Should have unwrapped")
            return
        }

        let currentUserDictionary = ["sessionToken": objcSessionToken]
        let currentUserDictionary2 = ["session_token": objcSessionToken2]
        let currentUserDictionary3 = ["sessionToken": objcSessionToken,
                                      "session_token": objcSessionToken2]
        _ = objcParseKeychain.setObjectiveC(object: installationId, forKey: "installationId")
        if useBothTokens {
            _ = objcParseKeychain.setObjectiveC(object: currentUserDictionary3, forKey: "currentUser")
        } else if !useOldObjCToken {
            _ = objcParseKeychain.setObjectiveC(object: currentUserDictionary, forKey: "currentUser")
        } else {
            _ = objcParseKeychain.setObjectiveC(object: currentUserDictionary2, forKey: "currentUser")
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

        setupObjcKeychainSDK(installationId: objcInstallationId)

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

        setupObjcKeychainSDK(useOldObjCToken: true,
                             installationId: objcInstallationId)

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = objcSessionToken2
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
            XCTAssertEqual(loggedIn.sessionToken, self.objcSessionToken2)
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
            XCTAssertEqual(userFromKeychain.sessionToken, self.objcSessionToken2)
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

        setupObjcKeychainSDK(useBothTokens: true,
                             installationId: objcInstallationId)

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

        setupObjcKeychainSDK(installationId: objcInstallationId)
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

        setupObjcKeychainSDK(installationId: objcInstallationId)
        _ = try loginNormally(sessionToken: objcSessionToken2)
        MockURLProtocol.removeAll()

        let publisher = User.loginUsingObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTAssertTrue(error.message.contains("different"))
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

    func saveCurrentInstallation() throws {
        guard var installation = Installation.current else {
            XCTFail("Should unwrap")
            return
        }
        installation.objectId = testInstallationObjectId
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            guard let saved = try Installation.current?.save(),
                let newCurrentInstallation = Installation.current else {
                XCTFail("Should have a new current installation")
                return
            }
            XCTAssertTrue(saved.hasSameInstallationId(as: newCurrentInstallation))
            XCTAssertTrue(saved.hasSameObjectId(as: newCurrentInstallation))
            XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
            XCTAssertTrue(saved.hasSameInstallationId(as: installationOnServer))
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testMigrateInstallation() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Migrate Installation")

        try saveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard let installation = Installation.current,
            let savedObjectId = installation.objectId else {
                XCTFail("Should unwrap")
                return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        setupObjcKeychainSDK(installationId: objcInstallationId)

        var installationOnServer = installation
        installationOnServer.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installationOnServer.customKey = "newValue"
        installationOnServer.installationId = objcInstallationId
        installationOnServer.channels = ["yo"]
        installationOnServer.deviceToken = "no"

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let publisher = Installation.migrateFromObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in
            guard let currentInstallation = Installation.current else {
                XCTFail("Should have current installation")
                return
            }
            XCTAssertTrue(fetched.hasSameObjectId(as: currentInstallation))
            XCTAssertTrue(fetched.hasSameInstallationId(as: currentInstallation))
            XCTAssertTrue(fetched.hasSameObjectId(as: installationOnServer))
            XCTAssertTrue(fetched.hasSameInstallationId(as: installationOnServer))
            guard let fetchedCreatedAt = fetched.createdAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = installationOnServer.createdAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertEqual(fetched.channels, installationOnServer.channels)
            XCTAssertEqual(fetched.deviceToken, installationOnServer.deviceToken)

            // Should be updated in memory
            XCTAssertEqual(Installation.current?.installationId, self.objcInstallationId)
            XCTAssertEqual(Installation.current?.customKey, installationOnServer.customKey)
            XCTAssertEqual(Installation.current?.channels, installationOnServer.channels)
            XCTAssertEqual(Installation.current?.deviceToken, installationOnServer.deviceToken)

            // Should be updated in Keychain
            guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainInstallation.currentInstallation?.installationId, self.objcInstallationId)
            XCTAssertEqual(keychainInstallation.currentInstallation?.channels, installationOnServer.channels)
            XCTAssertEqual(keychainInstallation.currentInstallation?.deviceToken, installationOnServer.deviceToken)
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testMigrateInstallationDontCopyEntire() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Migrate Installation")

        try saveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard let installation = Installation.current,
            let savedObjectId = installation.objectId else {
                XCTFail("Should unwrap")
                return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        setupObjcKeychainSDK(installationId: objcInstallationId)

        var installationOnServer = installation
        installationOnServer.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installationOnServer.customKey = "newValue"
        installationOnServer.installationId = objcInstallationId
        installationOnServer.channels = ["yo"]
        installationOnServer.deviceToken = "no"

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let publisher = Installation.migrateFromObjCKeychainPublisher(copyEntireInstallation: false)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in
            guard let currentInstallation = Installation.current else {
                XCTFail("Should have current installation")
                return
            }
            XCTAssertTrue(fetched.hasSameObjectId(as: currentInstallation))
            XCTAssertTrue(fetched.hasSameInstallationId(as: currentInstallation))
            XCTAssertTrue(fetched.hasSameObjectId(as: installationOnServer))
            XCTAssertTrue(fetched.hasSameInstallationId(as: installation))
            guard let fetchedCreatedAt = fetched.createdAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = installationOnServer.createdAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertEqual(fetched.channels, installationOnServer.channels)
            XCTAssertEqual(fetched.deviceToken, installationOnServer.deviceToken)

            // Should be updated in memory
            XCTAssertEqual(Installation.current?.installationId, installation.installationId)
            XCTAssertNotEqual(Installation.current?.customKey, installationOnServer.customKey)
            XCTAssertEqual(Installation.current?.channels, installationOnServer.channels)
            XCTAssertEqual(Installation.current?.deviceToken, installationOnServer.deviceToken)

            // Should be updated in Keychain
            guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainInstallation.currentInstallation?.installationId, installation.installationId)
            XCTAssertEqual(keychainInstallation.currentInstallation?.channels, installationOnServer.channels)
            XCTAssertEqual(keychainInstallation.currentInstallation?.deviceToken, installationOnServer.deviceToken)
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testMigrateInstallationAlreadyMigrated() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Migrate Installation")

        try saveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard let installation = Installation.current,
              let savedObjectId = installation.objectId,
              let savedInstallationId = installation.installationId else {
                XCTFail("Should unwrap")
                return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        setupObjcKeychainSDK(installationId: savedInstallationId)

        let publisher = Installation.migrateFromObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in
            guard let currentInstallation = Installation.current else {
                XCTFail("Should have current installation")
                return
            }
            XCTAssertTrue(fetched.hasSameObjectId(as: currentInstallation))
            XCTAssertTrue(fetched.hasSameInstallationId(as: currentInstallation))
            XCTAssertTrue(fetched.hasSameObjectId(as: installation))
            XCTAssertTrue(fetched.hasSameInstallationId(as: installation))
            guard let fetchedCreatedAt = fetched.createdAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = installation.createdAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)

            // Should be updated in memory
            XCTAssertEqual(Installation.current?.installationId, savedInstallationId)
            XCTAssertEqual(Installation.current?.customKey, installation.customKey)

            // Should be updated in Keychain
            guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainInstallation.currentInstallation?.installationId, savedInstallationId)
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testMigrateInstallationServerError() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Migrate Installation")

        try saveCurrentInstallation()
        MockURLProtocol.removeAll()

        setupObjcKeychainSDK(installationId: objcInstallationId)

        let serverError = ParseError(code: .objectNotFound, message: "Not found")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverError)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let publisher = Installation.migrateFromObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTAssertEqual(error, serverError)
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

    func testMigrateInstallationNoObjcKeychain() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Migrate Installation")

        try saveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard let installation = Installation.current,
            let savedObjectId = installation.objectId else {
                XCTFail("Should unwrap")
                return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        let publisher = Installation.migrateFromObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTAssertTrue(error.message.contains("find Installation"))
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

    func testMigrateInstallationNoCurrentInstallation() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Migrate Installation")

        setupObjcKeychainSDK(installationId: objcInstallationId)

        try ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        try KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        Installation.currentContainer.currentInstallation = nil

        let publisher = Installation.migrateFromObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTAssertTrue(error.message.contains("Current installation"))
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

    func testDeleteObjCKeychain() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Delete ObjC Installation")

        try saveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard let installation = Installation.current,
              let savedObjectId = installation.objectId,
              let savedInstallationId = installation.installationId else {
                XCTFail("Should unwrap")
                return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        setupObjcKeychainSDK(installationId: objcInstallationId)

        var installationOnServer = installation
        installationOnServer.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installationOnServer.customKey = "newValue"
        installationOnServer.installationId = objcInstallationId
        installationOnServer.channels = ["yo"]
        installationOnServer.deviceToken = "no"

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let publisher = Installation.deleteObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            // Should be updated in memory
            XCTAssertEqual(Installation.current?.installationId, savedInstallationId)
            XCTAssertEqual(Installation.current?.customKey, installation.customKey)

            // Should be updated in Keychain
            guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainInstallation.currentInstallation?.installationId, savedInstallationId)
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteObjCKeychainAlreadyMigrated() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Delete ObjC Installation")

        try saveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard let installation = Installation.current,
              let savedObjectId = installation.objectId,
              let savedInstallationId = installation.installationId else {
                XCTFail("Should unwrap")
                return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        setupObjcKeychainSDK(installationId: savedInstallationId)

        let publisher = Installation.deleteObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            // Should be updated in memory
            XCTAssertEqual(Installation.current?.installationId, savedInstallationId)
            XCTAssertEqual(Installation.current?.customKey, installation.customKey)

            // Should be updated in Keychain
            guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainInstallation.currentInstallation?.installationId, savedInstallationId)
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteObjCKeychainNoObjcKeychain() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Delete ObjC Installation")

        try saveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard let installation = Installation.current,
            let savedObjectId = installation.objectId else {
                XCTFail("Should unwrap")
                return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        let publisher = Installation.deleteObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTAssertTrue(error.message.contains("find Installation"))
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

    func testDeleteObjCKeychainNoCurrentInstallation() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Delete ObjC Installation")

        setupObjcKeychainSDK(installationId: objcInstallationId)

        try ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        try KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        Installation.currentContainer.currentInstallation = nil

        let publisher = Installation.deleteObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTAssertTrue(error.message.contains("Current installation"))
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
