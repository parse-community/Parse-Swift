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
        var sessionToken: String
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

    struct UpdateSessionTokenResponse: Codable {
        var updatedAt: Date
        let sessionToken: String?
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              primaryKey: "primaryKey",
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

    func testStrip() throws {

        let expectedAuth = ["id": "yolo"]
        var user = User()
        user.authData = [user.anonymous.__type: expectedAuth]
        XCTAssertEqual(user.authData, ["anonymous": expectedAuth])
        let strippedAuth = user.anonymous.strip(user)
        XCTAssertEqual(strippedAuth.authData, ["anonymous": nil])

    }

    func testAuthenticationKeys() throws {
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        XCTAssertEqual(Array(authData.keys), ["id"])
        XCTAssertNotNil(authData["id"])
        XCTAssertNotEqual(authData["id"], "")
        XCTAssertNotEqual(authData["id"], "12345")
    }

    func testLogin() throws {
        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.password = "world"
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

        let login1 = try User.anonymous.login()
        XCTAssertEqual(login1, User.current)
        XCTAssertEqual(login1, userOnServer)
        XCTAssertEqual(login1.username, "hello")
        XCTAssertEqual(login1.password, "world")
        XCTAssertTrue(login1.anonymous.isLinked)
    }

    func testLoginAuthData() throws {
        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.password = "world"
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

        let login1 = try User.anonymous.login(authData: .init())
        XCTAssertEqual(login1, User.current)
        XCTAssertEqual(login1, userOnServer)
        XCTAssertEqual(login1.username, "hello")
        XCTAssertEqual(login1.password, "world")
        XCTAssertTrue(login1.anonymous.isLinked)
    }

    func testLoginAsync() throws {
        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.password = "world"
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.anonymous.login { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.anonymous.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginAuthDataAsync() throws {
        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.password = "world"
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.anonymous.login(authData: .init()) { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.anonymous.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testReplaceAnonymousUser() throws {
        try testLogin()
        guard let user = User.current,
              let updatedAt = user.updatedAt else {
            XCTFail("Shold have unwrapped")
            return
        }
        XCTAssertTrue(user.anonymous.isLinked)

        var response = UpdateSessionTokenResponse(updatedAt: updatedAt.addingTimeInterval(+300),
            sessionToken: "blast")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
            //Get dates in correct format from ParseDecoding strategy
            response = try ParseCoding.jsonDecoder().decode(UpdateSessionTokenResponse.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.removeAll()
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation1 = XCTestExpectation(description: "Login")

        var current = User.current
        current?.username = "hello"
        current?.password = "world"
        current?.signup { result in
            switch result {

            case .success(let user):
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

    func testReplaceAnonymousUserBody() throws {
        try testLogin()
        guard let user = User.current,
              let updatedAt = user.updatedAt else {
            XCTFail("Shold have unwrapped")
            return
        }
        XCTAssertTrue(user.anonymous.isLinked)

        var response = UpdateSessionTokenResponse(updatedAt: updatedAt.addingTimeInterval(+300),
            sessionToken: "blast")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
            //Get dates in correct format from ParseDecoding strategy
            response = try ParseCoding.jsonDecoder().decode(UpdateSessionTokenResponse.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.removeAll()
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation1 = XCTestExpectation(description: "Login")

        User.signup(username: "hello",
                    password: "world") { result in
            switch result {

            case .success(let user):
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

    func testReplaceAnonymousUserSync() throws {
        try testLogin()
        guard let user = User.current,
              let updatedAt = user.updatedAt else {
            XCTFail("Shold have unwrapped")
            return
        }
        XCTAssertTrue(user.anonymous.isLinked)

        var response = UpdateSessionTokenResponse(updatedAt: updatedAt.addingTimeInterval(+300),
            sessionToken: "blast")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
            //Get dates in correct format from ParseDecoding strategy
            response = try ParseCoding.jsonDecoder().decode(UpdateSessionTokenResponse.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.removeAll()
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        User.current?.username = "hello"
        User.current?.password = "world"
        guard let signedInUser = try User.current?.signup() else {
            XCTFail("Shouuld have unwrapped")
            return
        }
        XCTAssertEqual(signedInUser, User.current)
        XCTAssertEqual(signedInUser.username, "hello")
        XCTAssertEqual(signedInUser.password, "world")
        XCTAssertFalse(signedInUser.anonymous.isLinked)
    }

    func testReplaceAnonymousUserBodySync() throws {
        try testLogin()
        guard let user = User.current,
              let updatedAt = user.updatedAt else {
            XCTFail("Shold have unwrapped")
            return
        }
        XCTAssertTrue(user.anonymous.isLinked)

        var response = UpdateSessionTokenResponse(updatedAt: updatedAt.addingTimeInterval(+300),
            sessionToken: "blast")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
            //Get dates in correct format from ParseDecoding strategy
            response = try ParseCoding.jsonDecoder().decode(UpdateSessionTokenResponse.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.removeAll()
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let signedInUser = try User.signup(username: "hello",
                                           password: "world")
        XCTAssertEqual(signedInUser, User.current)
        XCTAssertEqual(signedInUser.username, "hello")
        XCTAssertEqual(signedInUser.password, "world")
        XCTAssertFalse(signedInUser.anonymous.isLinked)
    }

    func testCantReplaceAnonymousWithDifferentUser() throws {
        try testLogin()
        guard let user = User.current else {
            XCTFail("Shold have unwrapped")
            return
        }
        XCTAssertTrue(user.anonymous.isLinked)

        let expectation1 = XCTestExpectation(description: "SignUp")
        var differentUser = User()
        differentUser.objectId = "nope"
        differentUser.username = "shouldnot"
        differentUser.password = "work"
        differentUser.signup { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error.code, .otherCause)
                XCTAssertTrue(error.message.contains("different"))
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testCantReplaceAnonymousWithDifferentUserSync() throws {
        try testLogin()
        guard let user = User.current else {
            XCTFail("Shold have unwrapped")
            return
        }
        XCTAssertTrue(user.anonymous.isLinked)

        var differentUser = User()
        differentUser.objectId = "nope"
        differentUser.username = "shouldnot"
        differentUser.password = "work"
        XCTAssertThrowsError(try differentUser.signup())
    }

    func testReplaceAnonymousWithBecome() throws { // swiftlint:disable:this function_body_length
        XCTAssertNil(User.current?.objectId)
        try testLogin()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)
        XCTAssertTrue(User.anonymous.isLinked)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        var serverResponse = LoginSignupResponse()
        serverResponse.createdAt = User.current?.createdAt
        serverResponse.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"
        serverResponse.password = "this"

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

        let expectation1 = XCTestExpectation(description: "Fetch user1")
        user.become(sessionToken: "newValue") { result in

            switch result {
            case .success(let become):
                XCTAssert(become.hasSameObjectId(as: userOnServer))
                guard let becomeCreatedAt = become.createdAt,
                    let becomeUpdatedAt = become.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = user.createdAt,
                    let originalUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(becomeCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(becomeUpdatedAt, originalUpdatedAt)
                XCTAssertNil(become.ACL)

                //Should be updated in memory
                XCTAssertEqual(User.current?.updatedAt, becomeUpdatedAt)
                XCTAssertFalse(User.anonymous.isLinked)

                #if !os(Linux) && !os(Android) && !os(Windows)
                //Should be updated in Keychain
                guard let keychainUser: CurrentUserContainer<BaseParseUser>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                        XCTFail("Should get object from Keychain")
                    return
                }
                XCTAssertEqual(keychainUser.currentUser?.updatedAt, becomeUpdatedAt)
                #endif
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLink() throws {

        let expectation1 = XCTestExpectation(description: "Fetch user1")
        User.anonymous.link(authData: .init()) { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error.message, "Not supported")
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
