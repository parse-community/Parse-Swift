//
//  ParseJanrainCombineTests.swift
//  ParseSwift
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class ParseJanrainCombineTests: XCTestCase {
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

    func mockLoginResponse(authType: String,
                           authData: [String: String],
                           username: String = "hello") throws -> User {
        var serverResponse = LoginSignupResponse()
        serverResponse.username = username
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [authType: authData]
        serverResponse.createdAt = Date()
        serverResponse.updatedAt = serverResponse.createdAt?.addingTimeInterval(+300)

        let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        let userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)

        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        return userOnServer
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

    func testJanrainCaptureLoginPublisher() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Login")
        let authData = ["id": "testing", "access_token": "access_token"]
        let userOnServer = try mockLoginResponse(authType: User.janrainCapture.__type,
                                                 authData: authData)

        let publisher = User.janrainCapture.loginPublisher(id: "testing",
                                                           accessToken: "access_token")
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()
            }, receiveValue: { user in
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertTrue(user.janrainCapture.isLinked)
            })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainEngageLoginPublisher() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Login")
        let authData = ["id": "testing", "auth_token": "auth_token"]
        let userOnServer = try mockLoginResponse(authType: User.janrainEngage.__type,
                                                 authData: authData)

        let publisher = User.janrainEngage.loginPublisher(id: "testing",
                                                          authToken: "auth_token")
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()
            }, receiveValue: { user in
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertTrue(user.janrainEngage.isLinked)
            })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainCaptureLinkPublisher() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Link")

        _ = try loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        let userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let publisher = User.janrainCapture.linkPublisher(id: "testing",
                                                          accessToken: "access_token")
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()
            }, receiveValue: { user in
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertTrue(user.janrainCapture.isLinked)
                XCTAssertFalse(user.anonymous.isLinked)
            })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainEngageLinkPublisher() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Link")

        _ = try loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        let userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let publisher = User.janrainEngage.linkPublisher(id: "testing",
                                                         authToken: "auth_token")
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()
            }, receiveValue: { user in
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertTrue(user.janrainEngage.isLinked)
                XCTAssertFalse(user.anonymous.isLinked)
            })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainCaptureUnlinkPublisher() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Unlink")

        _ = try loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParseJanrainCapture<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")
        User.current?.authData = [User.janrainCapture.__type: authData]
        XCTAssertTrue(User.janrainCapture.isLinked)

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        let userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let publisher = User.janrainCapture.unlinkPublisher()
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()
            }, receiveValue: { user in
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertFalse(user.janrainCapture.isLinked)
            })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainEngageUnlinkPublisher() throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Unlink")

        _ = try loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParseJanrainEngage<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  authToken: "auth_token")
        User.current?.authData = [User.janrainEngage.__type: authData]
        XCTAssertTrue(User.janrainEngage.isLinked)

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        let userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let publisher = User.janrainEngage.unlinkPublisher()
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()
            }, receiveValue: { user in
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertFalse(user.janrainEngage.isLinked)
            })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }
}

#endif
