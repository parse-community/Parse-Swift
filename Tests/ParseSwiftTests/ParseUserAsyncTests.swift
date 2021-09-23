//
//  ParseUserAsyncTests.swift
//  ParseUserAsyncTests
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency)
import Foundation
import XCTest
@testable import ParseSwift

@available(macOS 12.0, iOS 15.0, macCatalyst 15.0, watchOS 9.0, tvOS 15.0, *)
class ParseUserAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length

    struct User: ParseUser {

        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        // provided by User
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

        // provided by User
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
                              masterKey: "masterKey",
                              serverURL: url,
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
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
            XCTFail("Couldn't get CurrentUser from Keychain")
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
            XCTFail("Couldn't get CurrentUser from Keychain")
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

        let signedUp = try await user.become(sessionToken: serverResponse.sessionToken)
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
            XCTFail("Couldn't get CurrentUser from Keychain")
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
            XCTFail("\(userFromKeychain) wasn't deleted from Keychain during logout")
        }

        if let installationFromMemory: CurrentInstallationContainer<BaseParseInstallation>
            = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
            if installationFromMemory.installationId == oldInstallationId
                || installationFromMemory.installationId == nil {
                XCTFail("\(installationFromMemory) wasn't deleted and recreated in memory during logout")
            }
        } else {
            XCTFail("Should have a new installation")
        }

        #if !os(Linux) && !os(Android)
        if let installationFromKeychain: CurrentInstallationContainer<BaseParseInstallation>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
            if installationFromKeychain.installationId == oldInstallationId
                || installationFromKeychain.installationId == nil {
                XCTFail("\(installationFromKeychain) wasn't deleted & recreated in Keychain during logout")
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

        _ = try await User.logout()
        if let userFromKeychain = BaseParseUser.current {
            XCTFail("\(userFromKeychain) wasn't deleted from Keychain during logout")
        }

        if let installationFromMemory: CurrentInstallationContainer<BaseParseInstallation>
            = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                if installationFromMemory.installationId == oldInstallationId
                    || installationFromMemory.installationId == nil {
                    XCTFail("\(installationFromMemory) wasn't deleted & recreated in memory during logout")
                }
        } else {
            XCTFail("Should have a new installation")
        }

        #if !os(Linux) && !os(Android)
        if let installationFromKeychain: CurrentInstallationContainer<BaseParseInstallation>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                if installationFromKeychain.installationId == oldInstallationId
                    || installationFromKeychain.installationId == nil {
                    XCTFail("\(installationFromKeychain) wasn't deleted & recreated in Keychain during logout")
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
            XCTFail("Couldn't get CurrentUser from Keychain")
            return
        }

        XCTAssertEqual(userFromKeychain.objectId, serverResponse.objectId)
    }

    @MainActor
    func testSave() async throws {
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

        let saved = try await user.save()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)

        guard let userFromKeychain = BaseParseUser.current else {
            XCTFail("Couldn't get CurrentUser from Keychain")
            return
        }

        XCTAssertEqual(userFromKeychain.objectId, serverResponse.objectId)
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
            XCTFail("Couldn't get CurrentUser from Keychain")
        }
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

                #if !os(Linux) && !os(Android)
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
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = user.createdAt,
                    let originalUpdatedAt = user.updatedAt,
                    let serverUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(savedUpdatedAt, serverUpdatedAt)
                XCTAssertEqual(User.current?.customKey, user.customKey)

                //Should be updated in memory
                guard let updatedCurrentDate = User.current?.updatedAt else {
                    XCTFail("Should unwrap current date")
                    return
                }
                XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                #if !os(Linux) && !os(Android)
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
