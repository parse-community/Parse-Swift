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
    }

    struct Session<SessionUser: ParseUser>: ParseSession {

        var sessionToken: String
        var user: ParseSessionTests.User
        var restricted: Bool?
        var createdWith: [String: String]
        var installationId: String
        var expiresAt: Date

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
                              testing: false) // Set to false for codecov

    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testFetchCommand() throws {
        var session = Session<User>()
        session.objectId = "me"
        do {
            let command = try session.fetchCommand(include: nil)
            XCTAssertNotNil(command)
            //Generates this component because fetchCommand is at the Objective protocol level
            XCTAssertEqual(command.path.urlComponent, "/classes/_Session/me")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
            XCTAssertNil(command.data)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testEndPoint() throws {
        var session = Session<User>()
        session.objectId = "me"
        //This endpoint is at the ParseSession level
        XCTAssertEqual(session.endpoint.urlComponent, "/sessions/me")
    }

    func testURLSession() throws {
        let session = URLSession.parse
        XCTAssertNotNil(session.configuration.urlCache)
        XCTAssertEqual(session.configuration.requestCachePolicy, ParseSwift.configuration.requestCachePolicy)
        guard let headers = session.configuration.httpAdditionalHeaders as? [String: String]? else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(headers, ParseSwift.configuration.httpAdditionalHeaders)
    }
}
