//
//  ParseAuthenticationAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(_Concurrency) && !os(Linux) && !os(Android)
import Foundation
import XCTest
@testable import ParseSwift
import Combine

class ParseAuthenticationAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length
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

        #if canImport(_Concurrency)
        func login(authData: [String: String],
                   options: API.Options) async throws -> AuthenticatedUser {
            throw ParseError(code: .unknownError, message: "Not implemented")
        }

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
        #if !os(Linux) && !os(Android)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    @MainActor
    func testLogin() async throws {

        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        let type = TestAuth<User>.__type
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [type: authData]
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

        let user = try await User.login(type, authData: ["id": "yolo"])
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertEqual(user.password, "world")
        XCTAssertEqual(user.authData, serverResponse.authData)
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

    @MainActor
    func testLink() async throws {

        _ = try loginNormally()
        MockURLProtocol.removeAll()

        let type = TestAuth<User>.__type
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

        let user = try await User.link(type, authData: ["id": "yolo"])
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "parse")
        XCTAssertNil(user.password)
    }
}
#endif
