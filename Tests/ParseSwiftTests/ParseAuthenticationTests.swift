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

    struct LoginSignupResponse: ParseUser {

        var objectId: String?
        var createdAt: Date?
        var sessionToken: String
        var updatedAt: Date?
        var ACL: ParseACL?

        // provided by User
        var username: String?
        var email: String?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?

        init() {
            self.createdAt = Date()
            self.updatedAt = Date()
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
        #if !os(Linux)
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

    func testAuthStrip() throws {

        let expectedAuth = ["id": "yolo"]
        var user = User()
        user.authData = [user.anonymous.__type: expectedAuth]
        XCTAssertEqual(user.authData, ["anonymous": expectedAuth])
        let strippedAuth = user.anonymous.strip(user)
        XCTAssertEqual(strippedAuth.authData, ["anonymous": nil])

    }
}
