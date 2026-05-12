//
//  ParseJanrainAsyncTests.swift
//  ParseSwift
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseJanrainAsyncTests: XCTestCase {
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

    func loginNormally() async throws -> User {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        return try await User.login(username: "parse", password: "user")
    }

    @MainActor
    func testJanrainCaptureLogin() async throws {
        let authData = ["id": "testing", "access_token": "access_token"]
        let userOnServer = try mockLoginResponse(authType: User.janrainCapture.__type,
                                                 authData: authData)

        let user = try await User.janrainCapture.login(id: "testing",
                                                       accessToken: "access_token")
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertEqual(user.password, "world")
        XCTAssertTrue(user.janrainCapture.isLinked)
    }

    @MainActor
    func testJanrainEngageLogin() async throws {
        let authData = ["id": "testing", "auth_token": "auth_token"]
        let userOnServer = try mockLoginResponse(authType: User.janrainEngage.__type,
                                                 authData: authData)

        let user = try await User.janrainEngage.login(id: "testing",
                                                      authToken: "auth_token")
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertEqual(user.password, "world")
        XCTAssertTrue(user.janrainEngage.isLinked)
    }

    @MainActor
    func testJanrainCaptureLink() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        let userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let user = try await User.janrainCapture.link(id: "testing",
                                                      accessToken: "access_token")
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertTrue(user.janrainCapture.isLinked)
        XCTAssertFalse(user.anonymous.isLinked)
    }

    @MainActor
    func testJanrainEngageLink() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        let userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let user = try await User.janrainEngage.link(id: "testing",
                                                     authToken: "auth_token")
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertTrue(user.janrainEngage.isLinked)
        XCTAssertFalse(user.anonymous.isLinked)
    }

    @MainActor
    func testJanrainCaptureUnlink() async throws {
        _ = try await loginNormally()
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

        let user = try await User.janrainCapture.unlink()
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertFalse(user.janrainCapture.isLinked)
    }

    @MainActor
    func testJanrainEngageUnlink() async throws {
        _ = try await loginNormally()
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

        let user = try await User.janrainEngage.unlink()
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertFalse(user.janrainEngage.isLinked)
    }
}
#endif
