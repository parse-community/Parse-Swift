//
//  ParseMicrosoftTests.swift
//  ParseSwift
//
//  Created by DENGXUELIN on 5/13/26.
//  Copyright © 2026 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseMicrosoftTests: XCTestCase {
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
        let authData = ParseMicrosoft<User>
            .AuthenticationKeys.id.makeDictionary(code: "auth_code",
                                                  redirectURI: "https://example.com/callback")
        XCTAssertEqual(authData, ["code": "auth_code", "redirect_uri": "https://example.com/callback"])
    }

    func testAuthenticationWithOptionalKeys() throws {
        let authData = ParseMicrosoft<User>
            .AuthenticationKeys.id.makeDictionary(code: "auth_code",
                                                  redirectURI: "https://example.com/callback",
                                                  id: "testing")
        XCTAssertEqual(authData, ["id": "testing",
                                  "code": "auth_code",
                                  "redirect_uri": "https://example.com/callback"])
    }

    func testAuthenticationWithInsecureAuthKeys() throws {
        let authData = ParseMicrosoft<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")
        XCTAssertEqual(authData, ["id": "testing", "access_token": "access_token"])
    }

    func testVerifyMandatoryKeys() throws {
        let authData = ["code": "auth_code", "redirect_uri": "https://example.com/callback"]
        let insecureAuthData = ["id": "testing", "access_token": "access_token"]
        let authDataWrong = ["id": "testing", "hello": "test"]
        XCTAssertTrue(ParseMicrosoft<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authData))
        XCTAssertTrue(ParseMicrosoft<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: insecureAuthData))
        XCTAssertFalse(ParseMicrosoft<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataWrong))
    }

    func testLogin() throws {
        var serverResponse = LoginSignupResponse()

        let authData = ParseMicrosoft<User>
            .AuthenticationKeys.id.makeDictionary(code: "auth_code",
                                                  redirectURI: "https://example.com/callback")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.microsoft.__type: authData]
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

        User.microsoft.login(code: "auth_code", redirectURI: "https://example.com/callback") { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.microsoft.isLinked)

                //Test stripping
                user.microsoft.strip()
                XCTAssertFalse(user.microsoft.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginInsecureAuthMode() throws {
        var serverResponse = LoginSignupResponse()

        let authData = ParseMicrosoft<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.microsoft.__type: authData]
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

        User.microsoft.login(id: "testing", accessToken: "access_token") { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.microsoft.isLinked)

                //Test stripping
                user.microsoft.strip()
                XCTAssertFalse(user.microsoft.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginAuthData() throws {
        var serverResponse = LoginSignupResponse()

        let authData = ParseMicrosoft<User>
            .AuthenticationKeys.id.makeDictionary(code: "auth_code",
                                                  redirectURI: "https://example.com/callback",
                                                  id: "testing")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.microsoft.__type: authData]
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

        User.microsoft.login(authData: authData) { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.microsoft.isLinked)

                //Test stripping
                user.microsoft.strip()
                XCTAssertFalse(user.microsoft.isLinked)
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.microsoft.login(authData: ["hello": "world"]) { result in

            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("consisting of keys"))
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLinkLoggedInUserWithMicrosoft() throws {
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.microsoft.link(code: "auth_code", redirectURI: "https://example.com/callback") { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello10")
                XCTAssertNil(user.password)
                XCTAssertTrue(user.microsoft.isLinked)
                XCTAssertFalse(user.anonymous.isLinked)
                XCTAssertEqual(User.current?.sessionToken, "myToken")
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLinkLoggedInUserWithMicrosoftInsecureAuthMode() throws {
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.microsoft.link(id: "testing", accessToken: "access_token") { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello10")
                XCTAssertNil(user.password)
                XCTAssertTrue(user.microsoft.isLinked)
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

        let expectation1 = XCTestExpectation(description: "Login")

        let authData = ParseMicrosoft<User>
            .AuthenticationKeys.id.makeDictionary(code: "auth_code",
                                                  redirectURI: "https://example.com/callback")

        User.microsoft.link(authData: authData) { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello10")
                XCTAssertNil(user.password)
                XCTAssertTrue(user.microsoft.isLinked)
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.microsoft.link(authData: ["hello": "world"]) { result in

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

        let authData = ParseMicrosoft<User>
            .AuthenticationKeys.id.makeDictionary(code: "auth_code",
                                                  redirectURI: "https://example.com/callback")
        User.current?.authData = [User.microsoft.__type: authData]
        XCTAssertTrue(User.microsoft.isLinked)

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

        let expectation1 = XCTestExpectation(description: "Login")

        User.microsoft.unlink { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello10")
                XCTAssertNil(user.password)
                XCTAssertFalse(user.microsoft.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
