//
//  ParseQQTests.swift
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

class ParseQQTests: XCTestCase { // swiftlint:disable:this type_body_length
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
        #endif
        try ParseStorage.shared.deleteAll()
    }

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

    func loginAnonymousUser() throws {
        let authData = ["id": "yolo"]

        //: Convert the anonymous user to a real new user.
        var serverResponse = LoginSignupResponse()
        serverResponse.username = "hello"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.anonymous.__type: authData]
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

        let user = try User.anonymous.login()
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertTrue(user.anonymous.isLinked)
    }

    func testAuthenticationKeys() throws {
        let secureAuthData = ParseQQ<User>
            .AuthenticationKeys.code.makeDictionary(code: "validCode",
                                                    redirectURI: "https://example.com/callback")
        XCTAssertEqual(secureAuthData,
                       ["code": "validCode",
                        "redirect_uri": "https://example.com/callback"])

        let insecureAuthData = ParseQQ<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "that")
        XCTAssertEqual(insecureAuthData, ["id": "testing", "access_token": "that"])
    }

    func testVerifyMandatoryKeys() throws {
        let secureAuthData = ["code": "validCode", "redirect_uri": "https://example.com/callback"]
        let insecureAuthData = ["id": "testing", "access_token": "this"]
        let authDataCodeOnly = ["code": "validCode"]
        let authDataRedirectOnly = ["redirect_uri": "https://example.com/callback"]
        let authDataIdOnly = ["id": "testing"]
        let authDataTokenOnly = ["access_token": "this"]
        let authDataWrong = ["hello": "test"]

        XCTAssertTrue(ParseQQ<User>
                        .AuthenticationKeys.code.verifyMandatoryKeys(authData: secureAuthData))
        XCTAssertTrue(ParseQQ<User>
                        .AuthenticationKeys.code.verifyMandatoryKeys(authData: insecureAuthData))
        XCTAssertFalse(ParseQQ<User>
                        .AuthenticationKeys.code.verifyMandatoryKeys(authData: authDataCodeOnly))
        XCTAssertFalse(ParseQQ<User>
                        .AuthenticationKeys.code.verifyMandatoryKeys(authData: authDataRedirectOnly))
        XCTAssertFalse(ParseQQ<User>
                        .AuthenticationKeys.code.verifyMandatoryKeys(authData: authDataIdOnly))
        XCTAssertFalse(ParseQQ<User>
                        .AuthenticationKeys.code.verifyMandatoryKeys(authData: authDataTokenOnly))
        XCTAssertFalse(ParseQQ<User>
                        .AuthenticationKeys.code.verifyMandatoryKeys(authData: authDataWrong))
    }

#if compiler(>=5.5.2) && canImport(_Concurrency)
    @MainActor
    func testLogin() async throws {

        var serverResponse = LoginSignupResponse()
        let authData = ParseQQ<User>
            .AuthenticationKeys.code.makeDictionary(code: "validCode",
                                                    redirectURI: "https://example.com/callback")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.qq.__type: authData]
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

        let user = try await User.qq.login(code: "validCode",
                                           redirectURI: "https://example.com/callback")
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertEqual(user.password, "world")
        XCTAssertTrue(user.qq.isLinked)
    }

    @MainActor
    func testLoginAuthData() async throws {

        var serverResponse = LoginSignupResponse()
        let authData = ParseQQ<User>
            .AuthenticationKeys.code.makeDictionary(code: "validCode",
                                                    redirectURI: "https://example.com/callback")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.qq.__type: authData]
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

        let user = try await User.qq.login(authData: (["code": "validCode",
                                                       "redirect_uri": "https://example.com/callback"]))
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertEqual(user.password, "world")
        XCTAssertTrue(user.qq.isLinked)
    }

    @MainActor
    func testLoginInsecureAuthData() async throws {

        var serverResponse = LoginSignupResponse()
        let authData = ParseQQ<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "this")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.qq.__type: authData]
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

        let user = try await User.qq.login(authData: (["id": "testing",
                                                       "access_token": "this"]))
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertEqual(user.password, "world")
        XCTAssertTrue(user.qq.isLinked)
    }

    @MainActor
    func testLoginAuthDataBadAuth() async throws {
        do {
            _ = try await User.qq.login(authData: (["code": "validCode",
                                                   "bad": "token"]))
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
    func testReplaceAnonymousWithLoggedIn() async throws {
        try loginAnonymousUser()
        MockURLProtocol.removeAll()
        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        serverResponse.password = nil

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

        let user = try await User.qq.login(code: "validCode",
                                           redirectURI: "https://example.com/callback")
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertTrue(user.qq.isLinked)
        XCTAssertFalse(user.anonymous.isLinked)
    }

    @MainActor
    func testReplaceAnonymousWithLinked() async throws {
        try loginAnonymousUser()
        MockURLProtocol.removeAll()
        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        serverResponse.password = nil

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

        let user = try await User.qq.link(code: "validCode",
                                          redirectURI: "https://example.com/callback")
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertTrue(user.qq.isLinked)
        XCTAssertFalse(user.anonymous.isLinked)
    }

    @MainActor
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

        let user = try await User.qq.link(code: "validCode",
                                          redirectURI: "https://example.com/callback")
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertTrue(user.qq.isLinked)
        XCTAssertFalse(user.anonymous.isLinked)
    }

    @MainActor
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

        let authData = ParseQQ<User>
            .AuthenticationKeys.code.makeDictionary(code: "validCode",
                                                    redirectURI: "https://example.com/callback")

        let user = try await User.qq.link(authData: authData)
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertTrue(user.qq.isLinked)
        XCTAssertFalse(user.anonymous.isLinked)
    }

    @MainActor
    func testLinkLoggedInUserWrongKeys() async throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()
        do {
            _ = try await User.qq.link(authData: ["hello": "world"])
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
    func testUnlink() async throws {

        _ = try loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParseQQ<User>
            .AuthenticationKeys.code.makeDictionary(code: "validCode",
                                                    redirectURI: "https://example.com/callback")
        User.current?.authData = [User.qq.__type: authData]
        XCTAssertTrue(User.qq.isLinked)

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

        let user = try await User.qq.unlink()
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertFalse(user.qq.isLinked)
    }
#endif
}
