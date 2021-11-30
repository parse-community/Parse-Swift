//
//  ParseAuthenticationTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/16/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift
#if canImport(Combine)
import Combine
#endif

class ParseAuthenticationTests: XCTestCase {

    struct User: ParseUser {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

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
        var sessionToken: String
        var updatedAt: Date?
        var ACL: ParseACL?

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

    struct TestAuth<AuthenticatedUser: ParseUser>: ParseAuthentication {
        static var __type: String { // swiftlint:disable:this identifier_name
            "test"
        }
        func login(authData: [String: String],
                   options: API.Options,
                   callbackQueue: DispatchQueue,
                   completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
            let error = ParseError(code: .unknownError, message: "Not implemented")
            completion(.failure(error))
        }

        func link(authData: [String: String],
                  options: API.Options,
                  callbackQueue: DispatchQueue,
                  completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
            let error = ParseError(code: .unknownError, message: "Not implemented")
            completion(.failure(error))
        }

        #if canImport(Combine)
        func loginPublisher(authData: [String: String],
                            options: API.Options) -> Future<AuthenticatedUser, ParseError> {
            let error = ParseError(code: .unknownError, message: "Not implemented")
            return Future { promise in
                promise(.failure(error))
            }
        }

        func linkPublisher(authData: [String: String],
                           options: API.Options) -> Future<AuthenticatedUser, ParseError> {
            let error = ParseError(code: .unknownError, message: "Not implemented")
            return Future { promise in
                promise(.failure(error))
            }
        }
        #endif

        #if swift(>=5.5) && canImport(_Concurrency)
        @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
        func login(authData: [String: String],
                   options: API.Options) async throws -> AuthenticatedUser {
            throw ParseError(code: .unknownError, message: "Not implemented")
        }

        @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
        func link(authData: [String: String],
                  options: API.Options) async throws -> AuthenticatedUser {
            throw ParseError(code: .unknownError, message: "Not implemented")
        }
        #endif
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

    func testLinkCommand() throws {
        let user = User()
        let body = SignupLoginBody(authData: ["test": ["id": "yolo"]])
        let command = user.linkCommand(body: body)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNotNil(command.body)
        XCTAssertEqual(command.body?.authData, body.authData)
    }

    func testLinkCommandParseBody() throws {
        var user = User()
        user.username = "hello"
        user.password = "world"
        let command = try user.linkCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNotNil(command.body)
        XCTAssertNil(command.body?.authData)
    }

    func testLinkCommandLoggedIn() throws {
        let user = try loginNormally()
        let body = SignupLoginBody(authData: ["test": ["id": "yolo"]])
        let command = user.linkCommand(body: body)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\("yarr")")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNotNil(command.body)
        XCTAssertEqual(command.body?.authData, body.authData)
    }

    func testLinkCommandNoBodyLoggedIn() throws {
        let user = try loginNormally()
        let command = try user.linkCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\("yarr")")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNotNil(command.body)
        XCTAssertNil(command.body?.authData)
    }

    func testIsLinkedWithString() throws {

        let expectedAuth = ["id": "yolo"]
        var user = User()
        let auth = TestAuth<User>()
        user.authData = [auth.__type: expectedAuth]
        XCTAssertEqual(user.authData, ["test": expectedAuth])
        XCTAssertTrue(user.isLinked(with: "test"))
    }

    func testAuthStrip() throws {

        let expectedAuth = ["id": "yolo"]
        var user = User()
        let auth = TestAuth<User>()
        user.authData = [auth.__type: expectedAuth]
        XCTAssertEqual(user.authData, ["test": expectedAuth])
        let strippedAuth = auth.strip(user)
        XCTAssertEqual(strippedAuth.authData, ["test": nil])
    }
}
