//
//  ParseAnonymousTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/16/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseAnonymousTests: XCTestCase {

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

    func testStrip() throws {

        let expectedAuth = ["id": "yolo"]
        var user = User()
        user.authData = [user.anonymous.__type: expectedAuth]
        XCTAssertEqual(user.authData, ["anonymous": expectedAuth])
        let strippedAuth = user.anonymous.strip(user)
        XCTAssertEqual(strippedAuth.authData, ["anonymous": nil])

    }

    func testLogin() throws {
        //: Convert the anonymous user to a real new user.
        var serverResponse = LoginSignupResponse()
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.anonymous.__type: nil]
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.anonymous.login { result in
            switch result {

            case .success(let user):
                print("Parse signup successful: \(user)")
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertFalse(user.anonymous.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testReplaceAnonymousWithUser() throws {
        let expectedAuth = ["id": "yolo"]
        var newUser = User()
        newUser.authData = [newUser.anonymous.__type: expectedAuth]
        newUser.username = "hello"
        newUser.password = "world"
        XCTAssertTrue(newUser.anonymous.isLinked(with: newUser))

        //: Convert the anonymous user to a real new user.
        var serverResponse = LoginSignupResponse()
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.anonymous.__type: nil]
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

        let expectation1 = XCTestExpectation(description: "Login")

        newUser.anonymous.login { result in
            switch result {

            case .success(let user):
                print("Parse signup successful: \(user)")
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertFalse(user.anonymous.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testReplaceAnonymousWithUsernameChange() throws {
        let expectedAuth = ["id": "yolo"]
        var user = try loginNormally()
        user.authData = [user.anonymous.__type: expectedAuth]
        User.current = user
        XCTAssertEqual(user, User.current)
        XCTAssertTrue(user.anonymous.isLinked)

        //Convert the anonymous user to a real new user.
        User.current?.username = "hello"
        User.current?.password = "world"
        User.current?.authData = [user.anonymous.__type: nil]
        var userOnServer = User.current!
        userOnServer.updatedAt = user.updatedAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.removeAll()
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation1 = XCTestExpectation(description: "Login")

        User.current?.signup { result in
            switch result {

            case .success(let user):
                print("Parse signup successful: \(user)")
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertFalse(user.anonymous.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
