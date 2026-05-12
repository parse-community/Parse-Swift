//
//  ParseJanrainTests.swift
//  ParseSwift
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseJanrainTests: XCTestCase { // swiftlint:disable:this type_body_length
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

    func testJanrainCaptureAuthenticationKeys() throws {
        let authData = ParseJanrainCapture<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")
        XCTAssertEqual(authData, ["id": "testing", "access_token": "access_token"])
        XCTAssertEqual(User.janrainCapture.__type, "janraincapture")
    }

    func testJanrainEngageAuthenticationKeys() throws {
        let authData = ParseJanrainEngage<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  authToken: "auth_token")
        XCTAssertEqual(authData, ["id": "testing", "auth_token": "auth_token"])
        XCTAssertEqual(User.janrainEngage.__type, "janrainengage")
    }

    func testVerifyMandatoryKeys() throws {
        let captureAuthData = ["id": "testing", "access_token": "access_token"]
        let captureWrong = ["id": "testing", "auth_token": "auth_token"]
        XCTAssertTrue(ParseJanrainCapture<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: captureAuthData))
        XCTAssertFalse(ParseJanrainCapture<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: captureWrong))

        let engageAuthData = ["id": "testing", "auth_token": "auth_token"]
        let engageWrong = ["id": "testing", "access_token": "access_token"]
        XCTAssertTrue(ParseJanrainEngage<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: engageAuthData))
        XCTAssertFalse(ParseJanrainEngage<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: engageWrong))
    }

    func testJanrainCaptureLogin() throws {
        let authData = ParseJanrainCapture<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")
        let userOnServer = try mockLoginResponse(authType: User.janrainCapture.__type,
                                                 authData: authData)
        let expectation1 = XCTestExpectation(description: "Login")

        User.janrainCapture.login(id: "testing", accessToken: "access_token") { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.janrainCapture.isLinked)
                user.janrainCapture.strip()
                XCTAssertFalse(user.janrainCapture.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainEngageLogin() throws {
        let authData = ParseJanrainEngage<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  authToken: "auth_token")
        let userOnServer = try mockLoginResponse(authType: User.janrainEngage.__type,
                                                 authData: authData)
        let expectation1 = XCTestExpectation(description: "Login")

        User.janrainEngage.login(id: "testing", authToken: "auth_token") { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.janrainEngage.isLinked)
                user.janrainEngage.strip()
                XCTAssertFalse(user.janrainEngage.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainCaptureLoginAuthData() throws {
        let authData = ["id": "testing", "access_token": "access_token"]
        let userOnServer = try mockLoginResponse(authType: User.janrainCapture.__type,
                                                 authData: authData)
        let expectation1 = XCTestExpectation(description: "Login")

        User.janrainCapture.login(authData: authData) { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertTrue(user.janrainCapture.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainEngageLoginAuthData() throws {
        let authData = ["id": "testing", "auth_token": "auth_token"]
        let userOnServer = try mockLoginResponse(authType: User.janrainEngage.__type,
                                                 authData: authData)
        let expectation1 = XCTestExpectation(description: "Login")

        User.janrainEngage.login(authData: authData) { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertTrue(user.janrainEngage.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainCaptureLoginWrongKeys() throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Login")
        User.janrainCapture.login(authData: ["id": "testing", "auth_token": "auth_token"]) { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("access_token"))
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainEngageLoginWrongKeys() throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Login")
        User.janrainEngage.login(authData: ["id": "testing", "access_token": "access_token"]) { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("auth_token"))
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainCaptureLink() throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        let userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        let expectation1 = XCTestExpectation(description: "Link")

        User.janrainCapture.link(id: "testing", accessToken: "access_token") { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello10")
                XCTAssertNil(user.password)
                XCTAssertTrue(user.janrainCapture.isLinked)
                XCTAssertFalse(user.anonymous.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainEngageLink() throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        let userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        let expectation1 = XCTestExpectation(description: "Link")

        User.janrainEngage.link(id: "testing", authToken: "auth_token") { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello10")
                XCTAssertNil(user.password)
                XCTAssertTrue(user.janrainEngage.isLinked)
                XCTAssertFalse(user.anonymous.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainCaptureLinkAuthData() throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        let userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        let authData = ParseJanrainCapture<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")
        let expectation1 = XCTestExpectation(description: "Link")

        User.janrainCapture.link(authData: authData) { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertTrue(user.janrainCapture.isLinked)
                XCTAssertFalse(user.anonymous.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainEngageLinkAuthData() throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        let userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        let authData = ParseJanrainEngage<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  authToken: "auth_token")
        let expectation1 = XCTestExpectation(description: "Link")

        User.janrainEngage.link(authData: authData) { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertTrue(user.janrainEngage.isLinked)
                XCTAssertFalse(user.anonymous.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainCaptureLinkWrongKeys() throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Link")
        User.janrainCapture.link(authData: ["id": "testing", "auth_token": "auth_token"]) { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("access_token"))
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainEngageLinkWrongKeys() throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Link")
        User.janrainEngage.link(authData: ["id": "testing", "access_token": "access_token"]) { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("auth_token"))
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainCaptureUnlink() throws {
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
        let expectation1 = XCTestExpectation(description: "Unlink")

        User.janrainCapture.unlink { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertFalse(user.janrainCapture.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testJanrainEngageUnlink() throws {
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
        let expectation1 = XCTestExpectation(description: "Unlink")

        User.janrainEngage.unlink { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertFalse(user.janrainEngage.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
