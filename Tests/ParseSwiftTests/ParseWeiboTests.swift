//
//  ParseWeiboTests.swift
//  ParseSwift
//
//  Created by Moe Kanan on 5/12/26.
//  Copyright © 2026 Parse Community. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseWeiboTests: XCTestCase {
    struct User: ParseUser {
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?
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
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?
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
        let secureAuthData = ParseWeibo<User>
            .AuthenticationKeys.makeDictionary(code: "authorization-code",
                                               redirectURI: "https://example.com/callback")
        XCTAssertEqual(secureAuthData, [
            "code": "authorization-code",
            "redirect_uri": "https://example.com/callback"
        ])

        let insecureAuthData = ParseWeibo<User>
            .AuthenticationKeys.makeDictionary(id: "testing",
                                               accessToken: "access-token")
        XCTAssertEqual(insecureAuthData, [
            "id": "testing",
            "access_token": "access-token"
        ])
    }

    func testVerifyMandatoryKeys() throws {
        let secureAuthData = ["code": "authorization-code",
                              "redirect_uri": "https://example.com/callback"]
        let insecureAuthData = ["id": "testing",
                                "access_token": "access-token"]
        let authDataWrong = ["code": "authorization-code"]

        XCTAssertTrue(ParseWeibo<User>.AuthenticationKeys.verifyMandatoryKeys(authData: secureAuthData))
        XCTAssertTrue(ParseWeibo<User>.AuthenticationKeys.verifyMandatoryKeys(authData: insecureAuthData))
        XCTAssertFalse(ParseWeibo<User>.AuthenticationKeys.verifyMandatoryKeys(authData: authDataWrong))
    }

    func testLogin() throws {
        var serverResponse = LoginSignupResponse()
        let authData = ParseWeibo<User>
            .AuthenticationKeys.makeDictionary(code: "authorization-code",
                                               redirectURI: "https://example.com/callback")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.weibo.__type: authData]
        serverResponse.createdAt = Date()
        serverResponse.updatedAt = serverResponse.createdAt?.addingTimeInterval(+300)

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation1 = XCTestExpectation(description: "Login")

        User.weibo.login(code: "authorization-code",
                         redirectURI: "https://example.com/callback") { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.weibo.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginWithInsecureAuthData() throws {
        var serverResponse = LoginSignupResponse()
        let authData = ParseWeibo<User>
            .AuthenticationKeys.makeDictionary(id: "testing",
                                               accessToken: "access-token")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.weibo.__type: authData]
        serverResponse.createdAt = Date()
        serverResponse.updatedAt = serverResponse.createdAt?.addingTimeInterval(+300)

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation1 = XCTestExpectation(description: "Login")

        User.weibo.login(id: "testing",
                         accessToken: "access-token") { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.weibo.isLinked)
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

        User.weibo.login(authData: ["code": "authorization-code"]) { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("consisting of keys"))
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLinkLoggedInUserWithWeibo() throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        serverResponse.sessionToken = nil

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation1 = XCTestExpectation(description: "Login")

        User.weibo.link(code: "authorization-code",
                        redirectURI: "https://example.com/callback") { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello10")
                XCTAssertNil(user.password)
                XCTAssertTrue(user.weibo.isLinked)
                XCTAssertFalse(user.anonymous.isLinked)
                XCTAssertEqual(User.current?.sessionToken, "myToken")
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
