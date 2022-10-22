//
//  ParseUserAsyncTests.swift
//  ParseUserAsyncTests
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseUserAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length

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

    struct UserDefaultMerge: ParseUser {

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

    let loginUserName = "hello10"
    let loginPassword = "world"

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
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testOriginalDataNeverSavesToKeychain() async throws {
        // Signup current User
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        User.current?.originalData = Data()
        let original = User.current
        User.saveCurrentContainerToKeychain()

        let expectation1 = XCTestExpectation(description: "Original installation1")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let original = original,
                let saved = User.current else {
                XCTFail("Should have a new current installation")
                expectation1.fulfill()
                return
            }
            XCTAssertTrue(saved.hasSameObjectId(as: original))
            XCTAssertNotNil(original.originalData)
            XCTAssertNil(saved.originalData)
            XCTAssertEqual(saved.customKey, original.customKey)
            XCTAssertEqual(saved.email, original.email)
            XCTAssertEqual(saved.username, original.username)
            XCTAssertEqual(saved.emailVerified, original.emailVerified)
            XCTAssertEqual(saved.password, original.password)
            XCTAssertEqual(saved.authData, original.authData)
            XCTAssertEqual(saved.createdAt, original.createdAt)
            XCTAssertEqual(saved.updatedAt, original.updatedAt)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    @MainActor
    func testSignup() async throws {
        let loginResponse = LoginSignupResponse()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let signedUp = try await User.signup(username: loginUserName, password: loginUserName)
        XCTAssertNotNil(signedUp)
        XCTAssertNotNil(signedUp.createdAt)
        XCTAssertNotNil(signedUp.updatedAt)
        XCTAssertNotNil(signedUp.email)
        XCTAssertNotNil(signedUp.username)
        XCTAssertNil(signedUp.password)
        XCTAssertNotNil(signedUp.objectId)
        XCTAssertNotNil(signedUp.sessionToken)
        XCTAssertNotNil(signedUp.customKey)
        XCTAssertNil(signedUp.ACL)

        guard let userFromKeychain = BaseParseUser.current else {
            XCTFail("Could not get CurrentUser from Keychain")
            return
        }

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        XCTAssertNotNil(userFromKeychain.sessionToken)
        XCTAssertNil(userFromKeychain.ACL)
    }

    @MainActor
    func testSignupInstance() async throws {
        let loginResponse = LoginSignupResponse()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        var user = User()
        user.username = loginUserName
        user.password = loginPassword
        user.email = "parse@parse.com"
        user.customKey = "blah"
        let signedUp = try await user.signup()
        XCTAssertNotNil(signedUp)
        XCTAssertNotNil(signedUp.createdAt)
        XCTAssertNotNil(signedUp.updatedAt)
        XCTAssertNotNil(signedUp.email)
        XCTAssertNotNil(signedUp.username)
        XCTAssertNil(signedUp.password)
        XCTAssertNotNil(signedUp.objectId)
        XCTAssertNotNil(signedUp.sessionToken)
        XCTAssertNotNil(signedUp.customKey)
        XCTAssertNil(signedUp.ACL)

        guard let userFromKeychain = BaseParseUser.current else {
            XCTFail("Could not get CurrentUser from Keychain")
            return
        }

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        XCTAssertNotNil(userFromKeychain.sessionToken)
        XCTAssertNil(userFromKeychain.ACL)
    }

    @MainActor
    func testLogin() async throws {
        let loginResponse = LoginSignupResponse()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let signedUp = try await User.login(username: loginUserName, password: loginUserName)
        XCTAssertNotNil(signedUp)
        XCTAssertNotNil(signedUp.createdAt)
        XCTAssertNotNil(signedUp.updatedAt)
        XCTAssertNotNil(signedUp.email)
        XCTAssertNotNil(signedUp.username)
        XCTAssertNil(signedUp.password)
        XCTAssertNotNil(signedUp.objectId)
        XCTAssertNotNil(signedUp.sessionToken)
        XCTAssertNotNil(signedUp.customKey)
        XCTAssertNil(signedUp.ACL)

        guard let userFromKeychain = BaseParseUser.current else {
            XCTFail("Could not get CurrentUser from Keychain")
            return
        }

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        XCTAssertNotNil(userFromKeychain.sessionToken)
        XCTAssertNil(userFromKeychain.ACL)
    }

    func login() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            _ = try User.login(username: loginUserName, password: loginPassword)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testBecome() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        guard let sessionToken = serverResponse.sessionToken else {
            XCTFail("Should have unwrapped")
            return
        }
        let signedUp = try await user.become(sessionToken: sessionToken)
        XCTAssertNotNil(signedUp)
        XCTAssertNotNil(signedUp.updatedAt)
        XCTAssertNotNil(signedUp.email)
        XCTAssertNotNil(signedUp.username)
        XCTAssertNil(signedUp.password)
        XCTAssertNotNil(signedUp.objectId)
        XCTAssertNotNil(signedUp.sessionToken)
        XCTAssertNotNil(signedUp.customKey)
        XCTAssertNil(signedUp.ACL)

        guard let userFromKeychain = BaseParseUser.current else {
            XCTFail("Could not get CurrentUser from Keychain")
            return
        }

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        XCTAssertNotNil(userFromKeychain.sessionToken)
        XCTAssertNil(userFromKeychain.ACL)
    }

    @MainActor
    func testLogout() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        let serverResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        guard let oldInstallationId = BaseParseInstallation.current?.installationId else {
            XCTFail("Should have unwrapped")
            return
        }

        _ = try await User.logout()

        if let userFromKeychain = BaseParseUser.current {
            XCTFail("\(userFromKeychain) was not deleted from Keychain during logout")
        }

        if let installationFromMemory: CurrentInstallationContainer<BaseParseInstallation>
            = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
            if installationFromMemory.installationId == oldInstallationId
                || installationFromMemory.installationId == nil {
                XCTFail("\(installationFromMemory) was not deleted and recreated in memory during logout")
            }
        } else {
            XCTFail("Should have a new installation")
        }

        #if !os(Linux) && !os(Android) && !os(Windows)
        if let installationFromKeychain: CurrentInstallationContainer<BaseParseInstallation>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
            if installationFromKeychain.installationId == oldInstallationId
                || installationFromKeychain.installationId == nil {
                XCTFail("\(installationFromKeychain) was not deleted & recreated in Keychain during logout")
            }
        } else {
            XCTFail("Should have a new installation")
        }
        #endif
    }

    @MainActor
    func testLogoutError() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        let serverResponse = ParseError(code: .internalServer, message: "Object not found")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        guard let oldInstallationId = BaseParseInstallation.current?.installationId else {
            XCTFail("Should have unwrapped")
            return
        }

        do {
            _ = try await User.logout()
            XCTFail("Should have thrown error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.message, serverResponse.message)
        }

        if let userFromKeychain = BaseParseUser.current {
            XCTFail("\(userFromKeychain) was not deleted from Keychain during logout")
        }

        if let installationFromMemory: CurrentInstallationContainer<BaseParseInstallation>
            = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                if installationFromMemory.installationId == oldInstallationId
                    || installationFromMemory.installationId == nil {
                    XCTFail("\(installationFromMemory) was not deleted & recreated in memory during logout")
                }
        } else {
            XCTFail("Should have a new installation")
        }

        #if !os(Linux) && !os(Android) && !os(Windows)
        if let installationFromKeychain: CurrentInstallationContainer<BaseParseInstallation>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                if installationFromKeychain.installationId == oldInstallationId
                    || installationFromKeychain.installationId == nil {
                    XCTFail("\(installationFromKeychain) was not deleted & recreated in Keychain during logout")
                }
        } else {
            XCTFail("Should have a new installation")
        }
        #endif

    }

    @MainActor
    func testPasswordReset() async throws {
        let serverResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        _ = try await User.passwordReset(email: "hello@parse.org")
    }

    @MainActor
    func testPasswordResetError() async throws {
        let parseError = ParseError(code: .internalServer, message: "Object not found")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            try await User.passwordReset(email: "hello@parse.org")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.code, parseError.code)
        }
    }

    @MainActor
    func testVerifyPasswordLoggedIn() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        var serverResponse = LoginSignupResponse()
        serverResponse.sessionToken = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let currentUser = try await User.verifyPassword(password: "world", usingPost: true)
        XCTAssertNotNil(currentUser)
        XCTAssertNotNil(currentUser.createdAt)
        XCTAssertNotNil(currentUser.updatedAt)
        XCTAssertNotNil(currentUser.email)
        XCTAssertNotNil(currentUser.username)
        XCTAssertNil(currentUser.password)
        XCTAssertNotNil(currentUser.objectId)
        XCTAssertNotNil(currentUser.sessionToken)
        XCTAssertNotNil(currentUser.customKey)
        XCTAssertNil(currentUser.ACL)

        guard let userFromKeychain = BaseParseUser.current else {
            XCTFail("Could not get CurrentUser from Keychain")
            return
        }

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        XCTAssertNotNil(userFromKeychain.sessionToken)
        XCTAssertNil(userFromKeychain.ACL)
    }

    func testVerifyPasswordLoggedInGET() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        var serverResponse = LoginSignupResponse()
        serverResponse.sessionToken = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let currentUser = try await User.verifyPassword(password: "world", usingPost: false)
        XCTAssertNotNil(currentUser)
        XCTAssertNotNil(currentUser.createdAt)
        XCTAssertNotNil(currentUser.updatedAt)
        XCTAssertNotNil(currentUser.email)
        XCTAssertNotNil(currentUser.username)
        XCTAssertNil(currentUser.password)
        XCTAssertNotNil(currentUser.objectId)
        XCTAssertNotNil(currentUser.sessionToken)
        XCTAssertNotNil(currentUser.customKey)
        XCTAssertNil(currentUser.ACL)

        guard let userFromKeychain = BaseParseUser.current else {
            XCTFail("Could not get CurrentUser from Keychain")
            return
        }

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        XCTAssertNotNil(userFromKeychain.sessionToken)
        XCTAssertNil(userFromKeychain.ACL)
    }

    @MainActor
    func testVerifyPasswordNotLoggedIn() async throws {
        let serverResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let currentUser = try await User.verifyPassword(password: "world")
        XCTAssertNotNil(currentUser)
        XCTAssertNotNil(currentUser.createdAt)
        XCTAssertNotNil(currentUser.updatedAt)
        XCTAssertNotNil(currentUser.email)
        XCTAssertNotNil(currentUser.username)
        XCTAssertNil(currentUser.password)
        XCTAssertNotNil(currentUser.objectId)
        XCTAssertNotNil(currentUser.sessionToken)
        XCTAssertNotNil(currentUser.customKey)
        XCTAssertNil(currentUser.ACL)

        guard let userFromKeychain = BaseParseUser.current else {
            XCTFail("Could not get CurrentUser from Keychain")
            return
        }

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        XCTAssertNotNil(userFromKeychain.sessionToken)
        XCTAssertNil(userFromKeychain.ACL)
    }

    @MainActor
    func testVerifyPasswordLoggedInError() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        let parseError = ParseError(code: .userWithEmailNotFound,
                                    message: "User email is not verified.")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            _ = try await User.verifyPassword(password: "blue")
            XCTFail("Should have thrown error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.code, parseError.code)
        }
    }

    @MainActor
    func testVerificationEmail() async throws {
        let serverResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        _ = try await User.verificationEmail(email: "hello@parse.org")
    }

    @MainActor
    func testVerificationEmailError() async throws {
        let parseError = ParseError(code: .internalServer, message: "Object not found")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            _ = try await User.verificationEmail(email: "hello@parse.org")
            XCTFail("Should have thrown error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.code, parseError.code)
        }
    }

    @MainActor
    func testFetch() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        var serverResponse = LoginSignupResponse()
        serverResponse.createdAt = User.current?.createdAt
        serverResponse.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let fetched = try await user.fetch()
        XCTAssertEqual(fetched.objectId, serverResponse.objectId)

        guard let userFromKeychain = BaseParseUser.current else {
            XCTFail("Could not get CurrentUser from Keychain")
            return
        }

        XCTAssertEqual(userFromKeychain.objectId, serverResponse.objectId)
    }

    @MainActor
    func testSaveCurrent() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard var user = User.current else {
            XCTFail("Should unwrap")
            return
        }
        user.username = "stop"

        var serverResponse = user
        serverResponse.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let saved = try await user.save()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)

        guard let userFromKeychain = BaseParseUser.current else {
            XCTFail("Could not get CurrentUser from Keychain")
            return
        }

        XCTAssertEqual(userFromKeychain.objectId, serverResponse.objectId)
    }

    @MainActor
    func testSave() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        var user = User()
        user.username = "stop"

        var serverResponse = user
        serverResponse.objectId = "yolo"
        serverResponse.createdAt = User.current?.createdAt

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let saved = try await user.save()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)
    }

    @MainActor
    func testCreate() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        var user = User()
        user.username = "stop"

        var serverResponse = user
        serverResponse.objectId = "yolo"
        serverResponse.createdAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try serverResponse.getDecoder().decode(User.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let saved = try await user.create()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)
        XCTAssertEqual(saved.createdAt, serverResponse.createdAt)
        XCTAssertEqual(saved.updatedAt, serverResponse.createdAt)
    }

    @MainActor
    func testReplaceCreate() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var serverResponse = user
        serverResponse.createdAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try serverResponse.getDecoder().decode(User.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let saved = try await user.replace()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)
        XCTAssertEqual(saved.createdAt, serverResponse.createdAt)
        XCTAssertEqual(saved.updatedAt, serverResponse.createdAt)
    }

    @MainActor
    func testReplaceUpdate() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var serverResponse = user
        serverResponse.updatedAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try serverResponse.getDecoder().decode(User.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let saved = try await user.replace()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)
        XCTAssertEqual(saved.updatedAt, serverResponse.updatedAt)
    }

    @MainActor
    func testReplaceClientMissingObjectId() async throws {
        var user = User()
        user.customKey = "123"
        do {
            _ = try await user.replace()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertEqual(parseError.code, .missingObjectId)
        }
    }

    @MainActor
    func testUpdate() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var serverResponse = user
        serverResponse.updatedAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try serverResponse.getDecoder().decode(User.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let saved = try await user.update()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)
        XCTAssertEqual(saved.updatedAt, serverResponse.updatedAt)
    }

    @MainActor
    func testUpdateDefaultMerge() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        var user = UserDefaultMerge()
        user.username = "stop"
        user.objectId = "yolo"

        var serverResponse = user
        serverResponse.updatedAt = Date()
        serverResponse.customKey = "be"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try serverResponse.getDecoder().decode(UserDefaultMerge.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        user = user.set(\.customKey, to: "be")
        let saved = try await user.update()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)
        XCTAssertEqual(saved.updatedAt, serverResponse.updatedAt)
    }

    @MainActor
    func testUpdateClientMissingObjectId() async throws {
        var user = User()
        user.customKey = "123"
        do {
            _ = try await user.update()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertEqual(parseError.code, .missingObjectId)
        }
    }

    func testUpdateMutableMergeCurrentUser() async throws {
        // Signup current User
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let original = User.current else {
            XCTFail("Should unwrap")
            return
        }
        var originalResponse = original.mergeable
        originalResponse.createdAt = nil
        originalResponse.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())

        let encoded: Data!
        do {
            encoded = try originalResponse.getEncoder().encode(originalResponse, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            originalResponse = try originalResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        let response = originalResponse
        var originalUpdated = original.mergeable
        originalUpdated.customKey = "beast"
        originalUpdated.username = "mode"
        let updated = originalUpdated

        do {
            let saved = try await updated.update()
            let expectation1 = XCTestExpectation(description: "Update installation1")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                guard let newCurrentUser = User.current else {
                    XCTFail("Should have a new current installation")
                    expectation1.fulfill()
                    return
                }
                XCTAssertTrue(saved.hasSameObjectId(as: newCurrentUser))
                XCTAssertTrue(saved.hasSameObjectId(as: response))
                XCTAssertEqual(saved.customKey, updated.customKey)
                XCTAssertEqual(saved.email, original.email)
                XCTAssertEqual(saved.username, updated.username)
                XCTAssertEqual(saved.emailVerified, original.emailVerified)
                XCTAssertEqual(saved.password, original.password)
                XCTAssertEqual(saved.authData, original.authData)
                XCTAssertEqual(saved.createdAt, original.createdAt)
                XCTAssertEqual(saved.updatedAt, response.updatedAt)
                XCTAssertNil(saved.originalData)
                XCTAssertEqual(saved.customKey, newCurrentUser.customKey)
                XCTAssertEqual(saved.email, newCurrentUser.email)
                XCTAssertEqual(saved.username, newCurrentUser.username)
                XCTAssertEqual(saved.emailVerified, newCurrentUser.emailVerified)
                XCTAssertEqual(saved.password, newCurrentUser.password)
                XCTAssertEqual(saved.authData, newCurrentUser.authData)
                XCTAssertEqual(saved.createdAt, newCurrentUser.createdAt)
                XCTAssertEqual(saved.updatedAt, newCurrentUser.updatedAt)
                expectation1.fulfill()
            }
            wait(for: [expectation1], timeout: 20.0)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdateMutableMergeCurrentUserDefault() async throws {
        // Signup current User
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(UserDefault.current?.objectId)

        guard let original = UserDefault.current else {
            XCTFail("Should unwrap")
            return
        }
        var originalResponse = original.mergeable
        originalResponse.createdAt = nil
        originalResponse.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())

        let encoded: Data!
        do {
            encoded = try originalResponse.getEncoder().encode(originalResponse, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            originalResponse = try originalResponse.getDecoder().decode(UserDefault.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        let response = originalResponse
        var originalUpdated = original.mergeable
        originalUpdated.username = "mode"
        let updated = originalUpdated

        do {
            let saved = try await updated.update()
            let expectation1 = XCTestExpectation(description: "Update installation1")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                guard let newCurrentUser = User.current else {
                    XCTFail("Should have a new current installation")
                    expectation1.fulfill()
                    return
                }
                XCTAssertTrue(saved.hasSameObjectId(as: newCurrentUser))
                XCTAssertTrue(saved.hasSameObjectId(as: response))
                XCTAssertEqual(saved.email, original.email)
                XCTAssertEqual(saved.username, updated.username)
                XCTAssertEqual(saved.emailVerified, original.emailVerified)
                XCTAssertEqual(saved.password, original.password)
                XCTAssertEqual(saved.authData, original.authData)
                XCTAssertEqual(saved.createdAt, original.createdAt)
                XCTAssertEqual(saved.updatedAt, response.updatedAt)
                XCTAssertNil(saved.originalData)
                XCTAssertEqual(saved.email, newCurrentUser.email)
                XCTAssertEqual(saved.username, newCurrentUser.username)
                XCTAssertEqual(saved.emailVerified, newCurrentUser.emailVerified)
                XCTAssertEqual(saved.password, newCurrentUser.password)
                XCTAssertEqual(saved.authData, newCurrentUser.authData)
                XCTAssertEqual(saved.createdAt, newCurrentUser.createdAt)
                XCTAssertEqual(saved.updatedAt, newCurrentUser.updatedAt)
                expectation1.fulfill()
            }
            wait(for: [expectation1], timeout: 20.0)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testDelete() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        let serverResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        _ = try await user.delete()
        if BaseParseUser.current != nil {
            XCTFail("Could not get CurrentUser from Keychain")
        }
    }

    @MainActor
    func testDeleteError() async throws {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        let serverResponse = ParseError(code: .objectNotFound, message: "Not found")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        do {
            _ = try await user.delete()
            XCTFail("Should have thrown error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.message, serverResponse.message)
        }
        XCTAssertNotNil(BaseParseUser.current)
    }

    @MainActor
    func testFetchAll() async throws {
        login()
        MockURLProtocol.removeAll()
        let expectation1 = XCTestExpectation(description: "Fetch")

        guard var user = User.current else {
                XCTFail("Should unwrap dates")
            expectation1.fulfill()
                return
        }

        user.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        user.customKey = "newValue"
        let userOnServer = QueryResponse<User>(results: [user], count: 1)

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(user)
            user = try user.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let fetched = try await [user].fetchAll()
        fetched.forEach {
            switch $0 {
            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: user))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                guard let originalCreatedAt = user.createdAt,
                    let originalUpdatedAt = user.updatedAt,
                    let serverUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                XCTAssertEqual(User.current?.customKey, user.customKey)

                //Should be updated in memory
                guard let updatedCurrentDate = User.current?.updatedAt else {
                    XCTFail("Should unwrap current date")
                    expectation1.fulfill()
                    return
                }
                XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                #if !os(Linux) && !os(Android) && !os(Windows)
                //Should be updated in Keychain
                guard let keychainUser: CurrentUserContainer<BaseParseUser>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                    let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
                        XCTFail("Should get object from Keychain")
                        expectation1.fulfill()
                    return
                }
                XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                #endif
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testSaveAll() async throws {
        login()
        MockURLProtocol.removeAll()

        guard var user = User.current else {
            XCTFail("Should unwrap dates")
            return
        }
        user.createdAt = nil
        user.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        user.customKey = "newValue"
        let userOnServer = [BatchResponseItem<User>(success: user, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(user)
            user = try user.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let saved = try await [user].saveAll()
        saved.forEach {
            switch $0 {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: user))
                guard let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalUpdatedAt = user.updatedAt,
                    let serverUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(savedUpdatedAt, serverUpdatedAt)
                XCTAssertEqual(User.current?.customKey, user.customKey)

                //Should be updated in memory
                guard let updatedCurrentDate = User.current?.updatedAt else {
                    XCTFail("Should unwrap current date")
                    return
                }
                XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                #if !os(Linux) && !os(Android) && !os(Windows)
                //Should be updated in Keychain
                guard let keychainUser: CurrentUserContainer<BaseParseUser>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                    let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
                        XCTFail("Should get object from Keychain")
                    return
                }
                XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                #endif
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testCreateAll() async throws {
        login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"

        var userOnServer = user
        userOnServer.objectId = "yolo"
        userOnServer.createdAt = Date()

        let serverResponse = [BatchResponseItem<User>(success: userOnServer, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(userOnServer)
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let saved = try await [user].createAll()
        saved.forEach {
            switch $0 {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: userOnServer))
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = userOnServer.createdAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertEqual(savedUpdatedAt, originalCreatedAt)

            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testReplaceAllCreate() async throws {
        login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var userOnServer = user
        userOnServer.createdAt = Date()

        let serverResponse = [BatchResponseItem<User>(success: userOnServer, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(userOnServer)
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let saved = try await [user].replaceAll()
        saved.forEach {
            switch $0 {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: userOnServer))
                XCTAssertEqual(saved.createdAt, userOnServer.createdAt)
                XCTAssertEqual(saved.updatedAt, userOnServer.createdAt)
                XCTAssertEqual(saved.username, userOnServer.username)

            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testReplaceAllUpdate() async throws {
        login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var userOnServer = user
        userOnServer.updatedAt = Date()

        let serverResponse = [BatchResponseItem<User>(success: userOnServer, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(userOnServer)
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let saved = try await [user].replaceAll()
        saved.forEach {
            switch $0 {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: userOnServer))
                guard let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalUpdatedAt = userOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(saved.username, userOnServer.username)

            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testUpdateAll() async throws {
        login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var userOnServer = user
        userOnServer.updatedAt = Date()

        let serverResponse = [BatchResponseItem<User>(success: userOnServer, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(userOnServer)
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let saved = try await [user].updateAll()
        saved.forEach {
            switch $0 {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: userOnServer))
                guard let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalUpdatedAt = userOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(saved.username, userOnServer.username)

            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testDeleteAll() async throws {
        login()
        MockURLProtocol.removeAll()

        guard let user = User.current else {
            XCTFail("Should unwrap dates")
            return
        }

        let userOnServer = [BatchResponseItem<NoBody>(success: NoBody(), error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        try await [user].deleteAll()
            .forEach {
                if case let .failure(error) = $0 {
                    XCTFail("Should have deleted: \(error.localizedDescription)")
                }
        }
    }
}

#endif
