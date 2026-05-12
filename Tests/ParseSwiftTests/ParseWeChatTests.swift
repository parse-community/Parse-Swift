//
//  ParseWeChatTests.swift
//  ParseSwift
//
//  Created by Parse Community on 5/13/26.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseWeChatTests: XCTestCase { // swiftlint:disable:this type_body_length
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

    func loginAnonymousUser() throws {
        let authData = ["id": "yolo"]

        //: Convert the anonymous user to a real new user.
        var serverResponse = LoginSignupResponse()
        serverResponse.username = "hello"
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
        XCTAssertNil(user.password)
        XCTAssertTrue(user.anonymous.isLinked)
    }

    func testAuthenticationKeys() throws {
        let authData = ParseWeChat<User>
            .AuthenticationKeys.code.makeDictionary(code: "authCode")
        XCTAssertEqual(authData, ["code": "authCode"])

        let legacyAuthData = ParseWeChat<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "accessToken")
        XCTAssertEqual(legacyAuthData, ["id": "testing", "access_token": "accessToken"])
    }

    func testVerifyMandatoryKeys() throws {
        let authData = ["code": "authCode"]
        let legacyAuthData = ["id": "testing", "access_token": "accessToken"]
        let missingAccessToken = ["id": "testing"]
        let emptyAuthData = [String: String]()

        XCTAssertTrue(ParseWeChat<User>
                        .AuthenticationKeys.code.verifyMandatoryKeys(authData: authData))
        XCTAssertTrue(ParseWeChat<User>
                        .AuthenticationKeys.code.verifyMandatoryKeys(authData: legacyAuthData))
        XCTAssertFalse(ParseWeChat<User>
                        .AuthenticationKeys.code.verifyMandatoryKeys(authData: missingAccessToken))
        XCTAssertFalse(ParseWeChat<User>
                        .AuthenticationKeys.code.verifyMandatoryKeys(authData: emptyAuthData))
    }

    func testCallbackLogin() throws {

        var serverResponse = LoginSignupResponse()
        let authData = ParseWeChat<User>.AuthenticationKeys.code.makeDictionary(code: "authCode")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.wechat.__type: authData]
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

        User.wechat.login(code: "authCode") { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.wechat.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testCallbackLoginAuthData() throws {

        var serverResponse = LoginSignupResponse()
        let authData = ParseWeChat<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing", accessToken: "accessToken")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.wechat.__type: authData]
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

        User.wechat.login(authData: authData) { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.wechat.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testCallbackLink() throws {

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

        let expectation1 = XCTestExpectation(description: "Link")

        User.wechat.link(code: "authCode") { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello10")
                XCTAssertNil(user.password)
                XCTAssertTrue(user.wechat.isLinked)
                XCTAssertFalse(user.anonymous.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

#if compiler(>=5.5.2) && canImport(_Concurrency)
    @MainActor
    func testLogin() async throws {

        var serverResponse = LoginSignupResponse()
        let authData = ParseWeChat<User>.AuthenticationKeys.code.makeDictionary(code: "authCode")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.wechat.__type: authData]
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

        let user = try await User.wechat.login(code: "authCode")
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertEqual(user.password, "world")
        XCTAssertTrue(user.wechat.isLinked)
    }

    @MainActor
    func testLoginAuthData() async throws {

        var serverResponse = LoginSignupResponse()
        let authData = ParseWeChat<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing", accessToken: "accessToken")
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.wechat.__type: authData]
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

        let user = try await User.wechat.login(authData: authData)
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertEqual(user.password, "world")
        XCTAssertTrue(user.wechat.isLinked)
    }

    @MainActor
    func testLoginAuthDataBadAuth() async throws {
        do {
            _ = try await User.wechat.login(authData: ["id": "testing"])
            XCTFail("Should have returned error")
        } catch {
            guard let parseError = error.containedIn([.unknownError]) else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("authData"))
        }
    }

    @MainActor
    func testReplaceAnonymousWithLoggedIn() async throws {
        try loginAnonymousUser()
        MockURLProtocol.removeAll()
        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        serverResponse.password = nil

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

        let user = try await User.wechat.login(code: "authCode")
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertTrue(user.wechat.isLinked)
        XCTAssertFalse(user.anonymous.isLinked)
    }

    @MainActor
    func testReplaceAnonymousWithLinked() async throws {
        try loginAnonymousUser()
        MockURLProtocol.removeAll()
        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        serverResponse.password = nil

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

        let user = try await User.wechat.link(code: "authCode")
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertTrue(user.wechat.isLinked)
        XCTAssertFalse(user.anonymous.isLinked)
    }

    @MainActor
    func testLink() async throws {

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

        let user = try await User.wechat.link(code: "authCode")
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertTrue(user.wechat.isLinked)
        XCTAssertFalse(user.anonymous.isLinked)
    }

    @MainActor
    func testLinkLoggedInAuthData() async throws {

        _ = try loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        serverResponse.sessionToken = nil

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

        let authData = ParseWeChat<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing", accessToken: "accessToken")

        let user = try await User.wechat.link(authData: authData)
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertTrue(user.wechat.isLinked)
        XCTAssertFalse(user.anonymous.isLinked)
    }

    @MainActor
    func testLinkLoggedInUserWrongKeys() async throws {
        _ = try loginNormally()
        MockURLProtocol.removeAll()
        do {
            _ = try await User.wechat.link(authData: ["hello": "world"])
            XCTFail("Should have returned error")
        } catch {
            guard let parseError = error.containedIn([.unknownError]) else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("authData"))
        }
    }

    @MainActor
    func testUnlink() async throws {

        _ = try loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParseWeChat<User>
            .AuthenticationKeys.code.makeDictionary(code: "authCode")
        User.current?.authData = [User.wechat.__type: authData]
        XCTAssertTrue(User.wechat.isLinked)

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

        let user = try await User.wechat.unlink()
        XCTAssertEqual(user, User.current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertFalse(user.wechat.isLinked)
    }
#endif
}
