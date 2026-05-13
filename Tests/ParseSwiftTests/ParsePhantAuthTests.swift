//
//  ParsePhantAuthTests.swift
//  ParseSwift
//
//  Created by DENGXUELIN on 05/13/26.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParsePhantAuthTests: XCTestCase {
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

    func testAuthenticationKeys() throws {
        let authData = ParsePhantAuth<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")
        XCTAssertEqual(authData, ["id": "testing", "access_token": "access_token"])
    }

    func testVerifyMandatoryKeys() throws {
        let authData = ["id": "testing", "access_token": "access_token"]
        let authDataWrong = ["id": "testing", "hello": "test"]
        XCTAssertTrue(ParsePhantAuth<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authData))
        XCTAssertFalse(ParsePhantAuth<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataWrong))
    }

    func testLogin() throws {
        var serverResponse = LoginSignupResponse()

        let authData = ParsePhantAuth<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.phantauth.__type: authData]
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

        let expectation1 = XCTestExpectation(description: "Login with PhantAuth")

        User.phantauth.login(id: "testing", accessToken: "access_token") { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.phantauth.isLinked)

                //Test stripping
                user.phantauth.strip()
                XCTAssertFalse(user.phantauth.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginAuthData() throws {
        var serverResponse = LoginSignupResponse()

        let authData = ParsePhantAuth<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.phantauth.__type: authData]
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

        let expectation1 = XCTestExpectation(description: "Login with PhantAuth auth data")

        User.phantauth.login(authData: authData) { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.phantauth.isLinked)

                //Test stripping
                user.phantauth.strip()
                XCTAssertFalse(user.phantauth.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginWrongKeys() throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Reject invalid PhantAuth login auth data")

        User.phantauth.login(authData: ["hello": "world"]) { result in

            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("consisting of keys"))
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func loginAnonymousUser() throws {
        let authData = ["id": "yolo"]

        //: Convert the anonymous user to a real new user.
        var serverResponse = LoginSignupResponse()
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

        let user = try User.anonymous.login()
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertEqual(user.password, "world")
        XCTAssertTrue(user.anonymous.isLinked)
    }

    func testReplaceAnonymousWithPhantAuth() throws {
        try loginAnonymousUser()
        MockURLProtocol.removeAll()

        let authData = ParsePhantAuth<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")

        var serverResponse = LoginSignupResponse()
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.phantauth.__type: authData,
                                   serverResponse.anonymous.__type: nil]
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

        let expectation1 = XCTestExpectation(description: "Replace anonymous with PhantAuth")

        User.phantauth.login(id: "testing", accessToken: "access_token") { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.authData, userOnServer.authData)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.phantauth.isLinked)
                XCTAssertFalse(user.anonymous.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testReplaceAnonymousWithLinkedPhantAuth() throws {
        try loginAnonymousUser()
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

        let expectation1 = XCTestExpectation(description: "Link PhantAuth after anonymous")

        User.phantauth.link(id: "testing", accessToken: "access_token") { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.phantauth.isLinked)
                XCTAssertFalse(user.anonymous.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLinkLoggedInUserWithPhantAuth() throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.sessionToken = nil
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

        let expectation1 = XCTestExpectation(description: "Link PhantAuth")

        User.phantauth.link(id: "testing", accessToken: "access_token") { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello10")
                XCTAssertNil(user.password)
                XCTAssertTrue(user.phantauth.isLinked)
                XCTAssertFalse(user.anonymous.isLinked)
                XCTAssertEqual(User.current?.sessionToken, "myToken")
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLinkLoggedInAuthData() throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.sessionToken = nil
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

        let expectation1 = XCTestExpectation(description: "Link PhantAuth auth data")

        let authData = ParsePhantAuth<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")

        User.phantauth.link(authData: authData) { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello10")
                XCTAssertNil(user.password)
                XCTAssertTrue(user.phantauth.isLinked)
                XCTAssertFalse(user.anonymous.isLinked)
                XCTAssertEqual(User.current?.sessionToken, "myToken")
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLinkLoggedInUserWrongKeys() throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Reject invalid PhantAuth link auth data")

        User.phantauth.link(authData: ["hello": "world"]) { result in

            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("consisting of keys"))
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUnlink() throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParsePhantAuth<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")
        User.current?.authData = [User.phantauth.__type: authData]
        XCTAssertTrue(User.phantauth.isLinked)

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

        let expectation1 = XCTestExpectation(description: "Unlink PhantAuth")

        User.phantauth.unlink { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello10")
                XCTAssertNil(user.password)
                XCTAssertFalse(user.phantauth.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
