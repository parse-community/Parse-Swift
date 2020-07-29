//
//  ParseUserCommandTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/21/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseUserCommandTests: XCTestCase { // swiftlint:disable:this type_body_length

    struct User: ParseSwift.UserType {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ACL?

        // provided by User
        var username: String?
        var email: String?
        var password: String?

        // Your custom keys
        var customKey: String?
    }

    struct LoginSignupResponse: ParseSwift.UserType {
        var objectId: String?
        var createdAt: Date?
        var sessionToken: String
        var updatedAt: Date?
        var ACL: ACL?

        // provided by User
        var username: String?
        var email: String?
        var password: String?

        // Your custom keys
        var customKey: String?

        init() {
            self.createdAt = Date()
            self.updatedAt = Date()
            self.objectId = "yarr"
            self.ACL = nil
            self.customKey = "blah"
            self.sessionToken = "myToken"
            self.username = "hello10"
            self.password = "world"
            self.email = "hello@parse.com"
        }
    }

    override func setUp() {
        super.setUp()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url)
    }

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.removeAll()
    }

    func testFetchCommand() {
        var user = User()
        let className = user.className
        let objectId = "yarr"
        user.objectId = objectId
        do {
            let command = try user.fetchCommand()
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
            XCTAssertNil(command.data)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetch() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        var userOnServer = user
        userOnServer.createdAt = Date()
        userOnServer.updatedAt = Date()
        userOnServer.ACL = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try userOnServer.getEncoderWithoutSkippingKeys().encode(userOnServer)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let fetched = try user.fetch()
            XCTAssertNotNil(fetched)
            XCTAssertNotNil(fetched.createdAt)
            XCTAssertNotNil(fetched.updatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let fetched = try user.fetch(options: [.useMasterKey])
            XCTAssertNotNil(fetched)
            XCTAssertNotNil(fetched.createdAt)
            XCTAssertNotNil(fetched.updatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func fetchAsync(user: User, userOnServer: User) {

        let expectation1 = XCTestExpectation(description: "Fetch user1")
        user.fetch(options: [], callbackQueue: .global(qos: .background)) { result in
            expectation1.fulfill()

            switch result {

            case .success(let fetched):
                XCTAssertNotNil(fetched.createdAt)
                XCTAssertNotNil(fetched.updatedAt)
                XCTAssertNil(fetched.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        }

        let expectation2 = XCTestExpectation(description: "Fetch user2")
        user.fetch(options: [.useMasterKey], callbackQueue: .global(qos: .background)) { result in
            expectation2.fulfill()

            switch result {

            case .success(let fetched):
                XCTAssertNotNil(fetched.createdAt)
                XCTAssertNotNil(fetched.updatedAt)
                XCTAssertNil(fetched.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expectation1, expectation2], timeout: 10.0)
    }

    func testThreadSafeFetchAsync() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        var userOnServer = user
        userOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        userOnServer.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        userOnServer.ACL = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try userOnServer.getEncoderWithoutSkippingKeys().encode(userOnServer)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            self.fetchAsync(user: user, userOnServer: userOnServer)
        }
    }

    func testSaveCommand() {
        let user = User()
        let className = user.className

        let command = user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertNotNil(command.data)
    }

    func testUpdateCommand() {
        var user = User()
        let className = user.className
        let objectId = "yarr"
        user.objectId = objectId

        let command = user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertNotNil(command.data)
    }

    func testUpdate() { // swiftlint:disable:this function_body_length
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        user.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.updatedAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try userOnServer.getEncoderWithoutSkippingKeys().encode(userOnServer)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let saved = try user.save()
            guard let savedCreatedAt = saved.createdAt,
                let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = user.createdAt,
                let originalUpdatedAt = user.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, originalCreatedAt)
            XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try user.save(options: [.useMasterKey])
            guard let savedCreatedAt = saved.createdAt,
                let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = user.createdAt,
                let originalUpdatedAt = user.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, originalCreatedAt)
            XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func updateAsync(user: User, userOnServer: User, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update user1")
        user.save(options: [], callbackQueue: callbackQueue) { result in
            expectation1.fulfill()

            switch result {

            case .success(let saved):
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = user.createdAt,
                    let originalUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        }

        let expectation2 = XCTestExpectation(description: "Update user2")
        user.save(options: [.useMasterKey], callbackQueue: callbackQueue) { result in
            expectation2.fulfill()

            switch result {

            case .success(let saved):
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = user.createdAt,
                    let originalUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        }
        wait(for: [expectation1, expectation2], timeout: 10.0)
    }

    func testThreadSafeUpdateAsync() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        user.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.updatedAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try userOnServer.getEncoderWithoutSkippingKeys().encode(userOnServer)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            self.updateAsync(user: user, userOnServer: userOnServer, callbackQueue: .global(qos: .background))
        }
    }

    func testUpdateAsyncMainQueue() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        user.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.updatedAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try userOnServer.getEncoderWithoutSkippingKeys().encode(userOnServer)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.updateAsync(user: user, userOnServer: userOnServer, callbackQueue: .main)
    }

    func testUserSignUp() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoderWithoutSkippingKeys().encode(loginResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
           let signedUp = try User.signup(username: loginResponse.username!, password: loginResponse.password!)
            XCTAssertNotNil(signedUp)
            XCTAssertNotNil(signedUp.createdAt)
            XCTAssertNotNil(signedUp.updatedAt)
            XCTAssertNotNil(signedUp.email)
            XCTAssertNotNil(signedUp.username)
            XCTAssertNotNil(signedUp.password)
            XCTAssertNotNil(signedUp.objectId)
            XCTAssertNotNil(signedUp.sessionToken)
            XCTAssertNotNil(signedUp.customKey)
            XCTAssertNil(signedUp.ACL)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func signUpAsync(loginResponse: LoginSignupResponse, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Signup user1")
        User.signup(username: loginResponse.username!, password: loginResponse.password!,
                    callbackQueue: callbackQueue) { result in
            expectation1.fulfill()

            switch result {

            case .success(let signedUp):
                XCTAssertNotNil(signedUp.createdAt)
                XCTAssertNotNil(signedUp.updatedAt)
                XCTAssertNotNil(signedUp.email)
                XCTAssertNotNil(signedUp.username)
                XCTAssertNotNil(signedUp.password)
                XCTAssertNotNil(signedUp.objectId)
                XCTAssertNotNil(signedUp.sessionToken)
                XCTAssertNotNil(signedUp.customKey)
                XCTAssertNil(signedUp.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testThreadSafeSignUpAsync() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoderWithoutSkippingKeys().encode(loginResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            self.signUpAsync(loginResponse: loginResponse, callbackQueue: .global(qos: .background))
        }
    }

    func testSignUpAsyncMainQueue() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoderWithoutSkippingKeys().encode(loginResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.signUpAsync(loginResponse: loginResponse, callbackQueue: .main)
    }

    func testUserLogin() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoderWithoutSkippingKeys().encode(loginResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
           let loggedIn = try User.login(username: loginResponse.username!, password: loginResponse.password!)
            XCTAssertNotNil(loggedIn)
            XCTAssertNotNil(loggedIn.createdAt)
            XCTAssertNotNil(loggedIn.updatedAt)
            XCTAssertNotNil(loggedIn.email)
            XCTAssertNotNil(loggedIn.username)
            XCTAssertNotNil(loggedIn.password)
            XCTAssertNotNil(loggedIn.objectId)
            XCTAssertNotNil(loggedIn.sessionToken)
            XCTAssertNotNil(loggedIn.customKey)
            XCTAssertNil(loggedIn.ACL)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func userLoginAsync(loginResponse: LoginSignupResponse, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Login user")
        User.login(username: loginResponse.username!, password: loginResponse.password!,
                   callbackQueue: callbackQueue) { result in
            expectation1.fulfill()

            switch result {

            case .success(let loggedIn):
                XCTAssertNotNil(loggedIn.createdAt)
                XCTAssertNotNil(loggedIn.updatedAt)
                XCTAssertNotNil(loggedIn.email)
                XCTAssertNotNil(loggedIn.username)
                XCTAssertNotNil(loggedIn.password)
                XCTAssertNotNil(loggedIn.objectId)
                XCTAssertNotNil(loggedIn.sessionToken)
                XCTAssertNotNil(loggedIn.customKey)
                XCTAssertNil(loggedIn.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testThreadSafeLoginAsync() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoderWithoutSkippingKeys().encode(loginResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            self.userLoginAsync(loginResponse: loginResponse, callbackQueue: .global(qos: .background))
        }
    }

    func testLoginAsyncMainQueue() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoderWithoutSkippingKeys().encode(loginResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.userLoginAsync(loginResponse: loginResponse, callbackQueue: .main)
    }

    func testUserLogout() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoderWithoutSkippingKeys().encode(loginResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            try User.logout()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func logoutAsync(callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        User.logout(callbackQueue: callbackQueue) { result in
            expectation1.fulfill()

            switch result {

            case .success(let success):
                XCTAssertTrue(success)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testThreadSafeLogoutAsync() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoderWithoutSkippingKeys().encode(loginResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            self.logoutAsync(callbackQueue: .global(qos: .background))
        }
    }

    func testLogoutAsyncMainQueue() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoderWithoutSkippingKeys().encode(loginResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.logoutAsync(callbackQueue: .main)
    }
} // swiftlint:disable:this file_length
