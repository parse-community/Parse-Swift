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

        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        // provided by User
        var username: String?
        var email: String?
        var password: String?
        var authData: [String: [String: String]?]?
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
        @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
        func loginPublisher(authData: [String: String],
                            options: API.Options) -> Future<AuthenticatedUser, ParseError> {
            let error = ParseError(code: .unknownError, message: "Not implemented")
            return Future { promise in
                promise(.failure(error))
            }
        }

        @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
        func linkPublisher(authData: [String: String],
                           options: API.Options) -> Future<AuthenticatedUser, ParseError> {
            let error = ParseError(code: .unknownError, message: "Not implemented")
            return Future { promise in
                promise(.failure(error))
            }
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

    func testLinkCommand() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        let body = SignupLoginBody(authData: ["test": ["id": "yolo"]])

        let command = user.linkCommand(body: body)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNotNil(command.body)
        XCTAssertEqual(command.body?.authData, body.authData)
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
