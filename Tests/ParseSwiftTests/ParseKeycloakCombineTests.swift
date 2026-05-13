//
//  ParseKeycloakCombineTests.swift
//  ParseSwift
//
//  Created by Parse Community on 5/13/26.
//  Copyright (c) 2026 Parse Community. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class ParseKeycloakCombineTests: XCTestCase { // swiftlint:disable:this type_body_length

    /// Minimal user model used by the Combine Keycloak authentication tests.
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

    /// Mock login response that mirrors the server payload returned by Parse.
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

        /// Creates a populated response used by mocked login and link requests.
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

    /// Configures ParseSwift with the local test server before each test.
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

    /// Clears mocked network handlers and persisted Parse state after each test.
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    /// Logs in a baseline user for link and unlink publisher coverage.
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

    /// Verifies the Keycloak login publisher with id and access token credentials.
    func testLogin() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        var serverResponse = LoginSignupResponse()
        let authData = ParseKeycloak<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "accessToken")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [User.keycloak.__type: authData]
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

        let publisher = User.keycloak.loginPublisher(id: "testing",
                                                     accessToken: "accessToken")
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { user in

            XCTAssertEqual(user, User.current)
            XCTAssertEqual(user, userOnServer)
            XCTAssertEqual(user.username, "hello")
            XCTAssertEqual(user.password, "world")
            XCTAssertTrue(User.keycloak.isLinked(with: user))
        })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    /// Verifies the Keycloak login publisher with a prepared authData dictionary.
    func testLoginAuthData() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        var serverResponse = LoginSignupResponse()
        let authData = ParseKeycloak<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "accessToken")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [User.keycloak.__type: authData]
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

        let publisher = User.keycloak.loginPublisher(authData: authData)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { user in

            XCTAssertEqual(user, User.current)
            XCTAssertEqual(user, userOnServer)
            XCTAssertEqual(user.username, "hello")
            XCTAssertEqual(user.password, "world")
            XCTAssertTrue(User.keycloak.isLinked(with: user))
        })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    /// Verifies the Keycloak link publisher with id and access token credentials.
    func testLink() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        _ = try loginNormally()
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

        let publisher = User.keycloak.linkPublisher(id: "testing",
                                                    accessToken: "accessToken")
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { user in
            XCTAssertEqual(user, User.current)
            XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
            XCTAssertEqual(user.username, "hello10")
            XCTAssertNil(user.password)
            XCTAssertTrue(User.keycloak.isLinked(with: user))
        })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    /// Verifies the Keycloak link publisher with a prepared authData dictionary.
    func testLinkAuthData() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        _ = try loginNormally()
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

        let authData = ParseKeycloak<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "accessToken")

        let publisher = User.keycloak.linkPublisher(authData: authData)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { user in
            XCTAssertEqual(user, User.current)
            XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
            XCTAssertEqual(user.username, "hello10")
            XCTAssertNil(user.password)
            XCTAssertTrue(User.keycloak.isLinked(with: user))
        })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    /// Verifies the Keycloak unlink publisher removes the provider from the current user.
    func testUnlink() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        _ = try loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParseKeycloak<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "this")
        User.current?.authData = [User.keycloak.__type: authData]
        XCTAssertTrue(User.keycloak.isLinked)

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

        let publisher = User.keycloak.unlinkPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { user in
            XCTAssertEqual(user, User.current)
            XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
            XCTAssertEqual(user.username, "hello10")
            XCTAssertNil(user.password)
            XCTAssertFalse(User.keycloak.isLinked(with: user))
        })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }
}
#endif
