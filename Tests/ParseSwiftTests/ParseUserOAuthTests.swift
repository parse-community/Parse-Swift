//
//  ParseUserOAuthTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 3/12/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseUserOAuthTests: XCTestCase { // swiftlint:disable:this type_body_length

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

        // Your custom keys
        var customKey: String?
    }

    struct LoginSignupResponse: ParseUser {

        var objectId: String?
        var createdAt: Date?
        var sessionToken: String
        var updatedAt: Date?
        var ACL: ParseACL?
        var refreshToken: String?
        var expiresAt: Date?

        // provided by User
        var username: String?
        var email: String?
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
            self.sessionToken = "myToken"
            self.refreshToken = "yolo"
            self.expiresAt = date
            self.username = "hello10"
        }

        private enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
            case createdAt, objectId, updatedAt, username
            case sessionToken, refreshToken
            case expiresAt = "expires_in"
        }
    }
    let loginUserName = "hello10"
    let loginPassword = "world"

    override func setUp() {
        super.setUp()
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
        super.tearDown()
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

    func testRefreshCommand() throws {
        _ = try loginNormally()
        let body = RefreshBody(refreshToken: "yolo")
        do {
            let command = try User.refreshCommand()
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/refresh")
            XCTAssertEqual(command.method, API.Method.POST)
            XCTAssertNil(command.params)
            XCTAssertEqual(command.body?.refreshToken, body.refreshToken)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testRevokeCommand() throws {
        _ = try loginNormally()
        let body = RefreshBody(refreshToken: "yolo")
        let command = User.revokeCommand(refreshToken: "yolo")
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/revoke")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertEqual(command.body?.refreshToken, body.refreshToken)
    }

    func testUserSignUp() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
           let signedUp = try User.signup(username: loginUserName, password: loginPassword)
            XCTAssertNotNil(signedUp)
            XCTAssertNotNil(signedUp.createdAt)
            XCTAssertNotNil(signedUp.updatedAt)
            XCTAssertNotNil(signedUp.username)
            XCTAssertNil(signedUp.password)
            XCTAssertNil(signedUp.email)
            XCTAssertNotNil(signedUp.objectId)
            XCTAssertNotNil(signedUp.sessionToken)
            XCTAssertNotNil(signedUp.refreshToken)
            XCTAssertNotNil(signedUp.expiresAt)
            XCTAssertNil(signedUp.ACL)

            guard let userFromKeychain = BaseParseUser.current else {
                XCTFail("Couldn't get CurrentUser from Keychain")
                return
            }

            XCTAssertNotNil(userFromKeychain.createdAt)
            XCTAssertNotNil(userFromKeychain.updatedAt)
            XCTAssertNil(userFromKeychain.email)
            XCTAssertNotNil(userFromKeychain.username)
            XCTAssertNil(userFromKeychain.password)
            XCTAssertNotNil(userFromKeychain.objectId)
            XCTAssertNotNil(userFromKeychain.sessionToken)
            XCTAssertNotNil(userFromKeychain.refreshToken)
            XCTAssertNotNil(userFromKeychain.expiresAt)
            XCTAssertNil(userFromKeychain.ACL)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func signUpAsync(loginResponse: LoginSignupResponse, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Signup user1")
        User.signup(username: loginUserName, password: loginPassword,
                    callbackQueue: callbackQueue) { result in
            switch result {

            case .success(let signedUp):
                XCTAssertNotNil(signedUp.createdAt)
                XCTAssertNotNil(signedUp.updatedAt)
                XCTAssertNil(signedUp.email)
                XCTAssertNotNil(signedUp.username)
                XCTAssertNil(signedUp.password)
                XCTAssertNotNil(signedUp.objectId)
                XCTAssertNotNil(signedUp.sessionToken)
                XCTAssertNotNil(signedUp.refreshToken)
                XCTAssertNotNil(signedUp.expiresAt)
                XCTAssertNil(signedUp.ACL)

                guard let userFromKeychain = BaseParseUser.current else {
                    XCTFail("Couldn't get CurrentUser from Keychain")
                    expectation1.fulfill()
                    return
                }

                XCTAssertNotNil(userFromKeychain.createdAt)
                XCTAssertNotNil(userFromKeychain.updatedAt)
                XCTAssertNotNil(userFromKeychain.username)
                XCTAssertNil(userFromKeychain.email)
                XCTAssertNil(userFromKeychain.password)
                XCTAssertNotNil(userFromKeychain.objectId)
                XCTAssertNotNil(userFromKeychain.sessionToken)
                XCTAssertNotNil(userFromKeychain.refreshToken)
                XCTAssertNotNil(userFromKeychain.expiresAt)
                XCTAssertNil(userFromKeychain.ACL)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSignUpAsyncMainQueue() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.signUpAsync(loginResponse: loginResponse, callbackQueue: .main)
    }

    func testLogin() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let loggedIn = try User.login(username: loginUserName, password: loginPassword)
            XCTAssertNotNil(loggedIn)
            XCTAssertNotNil(loggedIn.createdAt)
            XCTAssertNotNil(loggedIn.updatedAt)
            XCTAssertNil(loggedIn.email)
            XCTAssertNotNil(loggedIn.username)
            XCTAssertNil(loggedIn.password)
            XCTAssertNotNil(loggedIn.objectId)
            XCTAssertNotNil(loggedIn.sessionToken)
            XCTAssertNotNil(loggedIn.refreshToken)
            XCTAssertNotNil(loggedIn.expiresAt)
            XCTAssertNil(loggedIn.ACL)

            guard let userFromKeychain = BaseParseUser.current else {
                XCTFail("Couldn't get CurrentUser from Keychain")
                return
            }

            XCTAssertNotNil(userFromKeychain.createdAt)
            XCTAssertNotNil(userFromKeychain.updatedAt)
            XCTAssertNotNil(userFromKeychain.username)
            XCTAssertNil(userFromKeychain.email)
            XCTAssertNil(userFromKeychain.password)
            XCTAssertNotNil(userFromKeychain.objectId)
            XCTAssertNotNil(userFromKeychain.sessionToken)
            XCTAssertNotNil(userFromKeychain.refreshToken)
            XCTAssertNotNil(userFromKeychain.expiresAt)
            XCTAssertNil(userFromKeychain.ACL)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func loginAsync(loginResponse: LoginSignupResponse, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Login user")
        User.login(username: loginUserName, password: loginPassword,
                   callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let loggedIn):
                XCTAssertNotNil(loggedIn.createdAt)
                XCTAssertNotNil(loggedIn.updatedAt)
                XCTAssertNil(loggedIn.email)
                XCTAssertNotNil(loggedIn.username)
                XCTAssertNil(loggedIn.password)
                XCTAssertNotNil(loggedIn.objectId)
                XCTAssertNotNil(loggedIn.sessionToken)
                XCTAssertNotNil(loggedIn.refreshToken)
                XCTAssertNotNil(loggedIn.expiresAt)
                XCTAssertNil(loggedIn.ACL)

                guard let userFromKeychain = BaseParseUser.current else {
                    XCTFail("Couldn't get CurrentUser from Keychain")
                    expectation1.fulfill()
                    return
                }

                XCTAssertNotNil(userFromKeychain.createdAt)
                XCTAssertNotNil(userFromKeychain.updatedAt)
                XCTAssertNil(userFromKeychain.email)
                XCTAssertNotNil(userFromKeychain.username)
                XCTAssertNil(userFromKeychain.password)
                XCTAssertNotNil(userFromKeychain.objectId)
                XCTAssertNotNil(userFromKeychain.sessionToken)
                XCTAssertNil(userFromKeychain.ACL)
                XCTAssertNotNil(userFromKeychain.refreshToken)
                XCTAssertNotNil(userFromKeychain.expiresAt)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginAsyncMainQueue() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.loginAsync(loginResponse: loginResponse, callbackQueue: .main)
    }

    func testRefresh() {
        testLogin()
        MockURLProtocol.removeAll()

        var refreshResponse = LoginSignupResponse()
        refreshResponse.sessionToken = "hello"
        refreshResponse.refreshToken = "world"
        refreshResponse.expiresAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(refreshResponse)
                //Get dates in correct format from ParseDecoding strategy
                refreshResponse = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let user = try User.refresh()
            guard let sessionToken = user.sessionToken,
                  let refreshToken = user.refreshToken,
                  let expiresAt = user.expiresAt else {
                XCTFail("Should unwrap all values")
                return
            }
            XCTAssertEqual(sessionToken, refreshResponse.sessionToken)
            XCTAssertEqual(refreshToken, refreshResponse.refreshToken)
            XCTAssertEqual(expiresAt, refreshResponse.expiresAt)
            XCTAssertNotNil(user.createdAt)
            XCTAssertNotNil(user.updatedAt)
            XCTAssertNil(user.email)
            XCTAssertNotNil(user.username)
            XCTAssertNil(user.password)
            XCTAssertNotNil(user.objectId)
            XCTAssertNil(user.ACL)

            guard let userFromKeychain = BaseParseUser.current,
                  let sessionTokenFromKeychain = user.sessionToken,
                  let refreshTokenFromKeychain = user.refreshToken,
                  let expiresAtFromKeychain = user.expiresAt else {
                XCTFail("Couldn't get CurrentUser from Keychain")
                return
            }
            XCTAssertEqual(sessionTokenFromKeychain, refreshResponse.sessionToken)
            XCTAssertEqual(refreshTokenFromKeychain, refreshResponse.refreshToken)
            XCTAssertEqual(expiresAtFromKeychain, refreshResponse.expiresAt)
            XCTAssertNotNil(userFromKeychain.createdAt)
            XCTAssertNotNil(userFromKeychain.updatedAt)
            XCTAssertNil(userFromKeychain.email)
            XCTAssertNotNil(userFromKeychain.username)
            XCTAssertNil(userFromKeychain.password)
            XCTAssertNotNil(userFromKeychain.objectId)
            XCTAssertNil(userFromKeychain.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func refreshAsync(refreshResponse: LoginSignupResponse, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        User.refresh(callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let user):
                guard let sessionToken = user.sessionToken,
                      let refreshToken = user.refreshToken,
                      let expiresAt = user.expiresAt else {
                    XCTFail("Should unwrap all values")
                    return
                }
                XCTAssertEqual(sessionToken, refreshResponse.sessionToken)
                XCTAssertEqual(refreshToken, refreshResponse.refreshToken)
                XCTAssertEqual(expiresAt, refreshResponse.expiresAt)
                XCTAssertNotNil(user.createdAt)
                XCTAssertNotNil(user.updatedAt)
                XCTAssertNil(user.email)
                XCTAssertNotNil(user.username)
                XCTAssertNil(user.password)
                XCTAssertNotNil(user.objectId)
                XCTAssertNil(user.ACL)

                guard let userFromKeychain = BaseParseUser.current,
                      let sessionTokenFromKeychain = user.sessionToken,
                      let refreshTokenFromKeychain = user.refreshToken,
                      let expiresAtFromKeychain = user.expiresAt else {
                    XCTFail("Couldn't get CurrentUser from Keychain")
                    return
                }
                XCTAssertEqual(sessionTokenFromKeychain, refreshResponse.sessionToken)
                XCTAssertEqual(refreshTokenFromKeychain, refreshResponse.refreshToken)
                XCTAssertEqual(expiresAtFromKeychain, refreshResponse.expiresAt)
                XCTAssertNotNil(userFromKeychain.createdAt)
                XCTAssertNotNil(userFromKeychain.updatedAt)
                XCTAssertNil(userFromKeychain.email)
                XCTAssertNotNil(userFromKeychain.username)
                XCTAssertNil(userFromKeychain.password)
                XCTAssertNotNil(userFromKeychain.objectId)
                XCTAssertNil(userFromKeychain.ACL)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testRefreshAsyncMainQueue() throws {
        testLogin()
        MockURLProtocol.removeAll()

        var refreshResponse = LoginSignupResponse()
        refreshResponse.sessionToken = "hello"
        refreshResponse.refreshToken = "world"
        refreshResponse.expiresAt = Date()

        let encoded = try ParseCoding.jsonEncoder().encode(refreshResponse)
        //Get dates in correct format from ParseDecoding strategy
        refreshResponse = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: encoded)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        self.refreshAsync(refreshResponse: refreshResponse, callbackQueue: .main)
    }

    func testLogout() {
        testLogin()
        MockURLProtocol.removeAll()

        let logoutResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(logoutResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            try User.logout()
            if let userFromKeychain = BaseParseUser.current {
                XCTFail("\(userFromKeychain) wasn't deleted from Keychain during logout")
            }

            if let installationFromKeychain = BaseParseInstallation.current {
                XCTFail("\(installationFromKeychain) wasn't deleted from Keychain during logout")
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func logoutAsync(callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        User.logout(callbackQueue: callbackQueue) { result in

            switch result {

            case .success:
                if let userFromKeychain = BaseParseUser.current {
                    XCTFail("\(userFromKeychain) wasn't deleted from Keychain during logout")
                }

                if let installationFromMemory: CurrentInstallationContainer<BaseParseInstallation>
                    = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                    XCTFail("\(installationFromMemory) wasn't deleted from memory during logout")
                }

                #if !os(Linux)
                if let installationFromKeychain: CurrentInstallationContainer<BaseParseInstallation>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                    XCTFail("\(installationFromKeychain) wasn't deleted from Keychain during logout")
                }
                #endif

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLogoutAsyncMainQueue() {
        testLogin()
        MockURLProtocol.removeAll()

        let logoutResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(logoutResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.logoutAsync(callbackQueue: .main)
    }

    func testBecome() { // swiftlint:disable:this function_body_length
        testLogin()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        var serverResponse = LoginSignupResponse()
        serverResponse.createdAt = User.current?.createdAt
        serverResponse.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"

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

        do {
            let become = try user.become(sessionToken: "newValue",
                                         refreshToken: "yolo",
                                         expiresAt: Date())
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
            XCTAssertNotNil(become.sessionToken)
            XCTAssertNotNil(become.refreshToken)
            XCTAssertNotNil(become.expiresAt)

            //Should be updated in memory
            XCTAssertEqual(User.current?.updatedAt, becomeUpdatedAt)

            //Should be updated in Keychain
            #if !os(Linux)
            guard let keychainUser: CurrentUserContainer<BaseParseUser>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainUser.currentUser?.updatedAt, becomeUpdatedAt)
            XCTAssertNotNil(keychainUser.sessionToken)
            XCTAssertNotNil(keychainUser.refreshToken)
            XCTAssertNotNil(keychainUser.expiresAt)
            #endif

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBecomeAsync() { // swiftlint:disable:this function_body_length
        XCTAssertNil(User.current?.objectId)
        testLogin()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

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
        user.become(sessionToken: "newValue",
                    refreshToken: "yolo",
                    expiresAt: Date()) { result in

            switch result {
            case .success(let become):
                XCTAssert(become.hasSameObjectId(as: userOnServer))
                guard let becomeCreatedAt = become.createdAt,
                    let becomeUpdatedAt = become.updatedAt else {
                        XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                        return
                }
                guard let originalCreatedAt = user.createdAt,
                    let originalUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                        return
                }
                XCTAssertEqual(becomeCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(becomeUpdatedAt, originalUpdatedAt)
                XCTAssertNil(become.ACL)
                XCTAssertNotNil(become.sessionToken)
                XCTAssertNotNil(become.refreshToken)
                XCTAssertNotNil(become.expiresAt)

                //Should be updated in memory
                XCTAssertEqual(User.current?.updatedAt, becomeUpdatedAt)

                #if !os(Linux)
                //Should be updated in Keychain
                guard let keychainUser: CurrentUserContainer<BaseParseUser>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                        XCTFail("Should get object from Keychain")
                    expectation1.fulfill()
                    return
                }
                XCTAssertEqual(keychainUser.currentUser?.updatedAt, becomeUpdatedAt)
                XCTAssertNotNil(keychainUser.sessionToken)
                XCTAssertNotNil(keychainUser.refreshToken)
                XCTAssertNotNil(keychainUser.expiresAt)
                #endif
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
