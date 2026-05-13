//
//  ParseKeycloakTests.swift
//  ParseSwift
//
//  Created by Parse Community on 5/13/26.
//  Copyright (c) 2026 Parse Community. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseKeycloakTests: XCTestCase { // swiftlint:disable:this type_body_length
    /// Minimal user model used by the Keycloak authentication tests.
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
    }

    /// Mock login response that mirrors the server payload returned by Parse.
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

        /// Creates a populated response used by mocked login and link requests.
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

    /// Configures ParseSwift with the local test server before each test.
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

    /// Clears mocked network handlers and persisted Parse state after each test.
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    /// Logs in a baseline user for link and unlink test coverage.
    func loginNormally() throws -> User {
        let loginResponse = LoginSignupResponse()

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

    /// Verifies the Keycloak authData dictionary uses the expected server keys.
    func testAuthenticationKeys() throws {
        let authData = ParseKeycloak<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "that")
        XCTAssertEqual(authData, ["id": "testing", "access_token": "that"])
    }

    /// Verifies Keycloak authData validation rejects missing mandatory keys.
    func testVerifyMandatoryKeys() throws {
        let authData = ["id": "testing", "access_token": "this"]
        let authDataIdOnly = ["id": "testing"]
        let authDataTokenOnly = ["access_token": "this"]
        let authDataWrong = ["hello": "test"]
        let authDataEmpty = [String: String]()

        XCTAssertTrue(ParseKeycloak<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authData))
        XCTAssertFalse(ParseKeycloak<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataIdOnly))
        XCTAssertFalse(ParseKeycloak<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataTokenOnly))
        XCTAssertFalse(ParseKeycloak<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataWrong))
        XCTAssertFalse(ParseKeycloak<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataEmpty))
    }

#if compiler(>=5.5.2) && canImport(_Concurrency)
    @MainActor
    /// Verifies async Keycloak login with id and access token credentials.
    func testLogin() async throws {

        var serverResponse = LoginSignupResponse()
        let authData = ParseKeycloak<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "accessToken")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [User.keycloak.__type: authData]
        serverResponse.createdAt = Date()
        serverResponse.updatedAt = serverResponse.createdAt?.addingTimeInterval(+300)

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let user = try await User.keycloak.login(id: "testing",
                                                 accessToken: "accessToken")
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertEqual(user.password, "world")
        XCTAssertTrue(User.keycloak.isLinked(with: user))
    }

    @MainActor
    /// Verifies async Keycloak login with a prepared authData dictionary.
    func testLoginAuthData() async throws {

        var serverResponse = LoginSignupResponse()
        let authData = ParseKeycloak<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "accessToken")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [User.keycloak.__type: authData]
        serverResponse.createdAt = Date()
        serverResponse.updatedAt = serverResponse.createdAt?.addingTimeInterval(+300)

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let user = try await User.keycloak.login(authData: authData)
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertEqual(user.password, "world")
        XCTAssertTrue(User.keycloak.isLinked(with: user))
    }

    @MainActor
    /// Verifies async Keycloak login rejects malformed authData.
    func testLoginAuthDataBadAuth() async throws {
        do {
            _ = try await User.keycloak.login(authData: ["id": "testing",
                                                         "bad": "token"])
            XCTFail("Should have thrown")
        } catch {
            guard let parseError = error.containedIn([.unknownError]) else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("consisting of keys"))
        }
    }

    @MainActor
    /// Verifies async Keycloak linking with id and access token credentials.
    func testLink() async throws {

        _ = try loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let user = try await User.keycloak.link(id: "testing",
                                                accessToken: "accessToken")
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertTrue(User.keycloak.isLinked(with: user))
        XCTAssertFalse(user.anonymous.isLinked)
    }

    @MainActor
    /// Verifies async Keycloak linking with a prepared authData dictionary.
    func testLinkLoggedInAuthData() async throws {

        _ = try loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        serverResponse.sessionToken = nil

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let authData = ParseKeycloak<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "accessToken")

        let user = try await User.keycloak.link(authData: authData)
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertTrue(User.keycloak.isLinked(with: user))
        XCTAssertFalse(user.anonymous.isLinked)
    }

    @MainActor
    /// Verifies async Keycloak linking rejects malformed authData.
    func testLinkLoggedInUserWrongKeys() async throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()
        do {
            _ = try await User.keycloak.link(authData: ["hello": "world"])
            XCTFail("Should have thrown")
        } catch {
            guard let parseError = error.containedIn([.unknownError]) else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("consisting of keys"))
        }
    }

    @MainActor
    /// Verifies async Keycloak unlink removes the provider from the current user.
    func testUnlink() async throws {

        _ = try loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParseKeycloak<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "this")
        User.current?.authData = [User.keycloak.__type: authData]
        XCTAssertTrue(User.keycloak.isLinked)

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let user = try await User.keycloak.unlink()
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertFalse(User.keycloak.isLinked(with: user))
    }
#endif
}
