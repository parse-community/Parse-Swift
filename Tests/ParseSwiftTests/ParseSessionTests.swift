//
//  ParseSessionTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/17/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

import XCTest
@testable import ParseSwift

class ParseSessionTests: XCTestCase {

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

    struct Session<SessionUser: ParseUser>: ParseSession {

        var sessionToken: String
        var user: ParseSessionTests.User
        var restricted: Bool?
        var createdWith: [String: String]
        var installationId: String
        var expiresAt: Date
        var originalData: Data?

        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        init() {
            sessionToken = "hello"
            user = User()
            restricted = false
            createdWith = ["yolo": "yaw"]
            installationId = "yes"
            expiresAt = Date()
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
                              isTesting: false) // Set to false for codecov

    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testFetchCommand() throws {
        var session = Session<User>()
        XCTAssertThrowsError(try session.fetchCommand(include: nil))
        session.objectId = "me"
        do {
            let command = try session.fetchCommand(include: nil)
            XCTAssertNotNil(command)
            //Generates this component because fetchCommand is at the Objective protocol level
            XCTAssertEqual(command.path.urlComponent, "/classes/_Session/me")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testEndPoint() throws {
        var session = Session<User>()
        XCTAssertEqual(session.endpoint.urlComponent, "/sessions")
        session.objectId = "me"
        XCTAssertEqual(session.endpoint.urlComponent, "/sessions/me")
    }
}
