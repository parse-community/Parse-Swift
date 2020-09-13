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

    struct User: ParseUser {
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

    struct LoginSignupResponse: ParseUser {
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
        try? KeychainStore.shared.deleteAll()
        try? ParseStorage.shared.deleteAll()
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

    func testFetch() { // swiftlint:disable:this function_body_length
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        var userOnServer = user
        userOnServer.createdAt = Date()
        userOnServer.updatedAt = Date()
        userOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder(skipKeys: false).encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let fetched = try user.fetch()
            XCTAssert(fetched.hasSameObjectId(as: userOnServer))
            guard let fetchedCreatedAt = fetched.createdAt,
                let fetchedUpdatedAt = fetched.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = userOnServer.createdAt,
                let originalUpdatedAt = userOnServer.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let fetched = try user.fetch(options: [.useMasterKey])
            XCTAssert(fetched.hasSameObjectId(as: userOnServer))
            guard let fetchedCreatedAt = fetched.createdAt,
                let fetchedUpdatedAt = fetched.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = userOnServer.createdAt,
                let originalUpdatedAt = userOnServer.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetchAndUpdateCurrentUser() { // swiftlint:disable:this function_body_length
        XCTAssertNil(User.current?.objectId)
        testUserLogin()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        var userOnServer = user
        userOnServer.createdAt = User.current?.createdAt
        userOnServer.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder(skipKeys: false).encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let fetched = try user.fetch(options: [.useMasterKey])
            XCTAssert(fetched.hasSameObjectId(as: userOnServer))
            guard let fetchedCreatedAt = fetched.createdAt,
                let fetchedUpdatedAt = fetched.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = user.createdAt,
                let originalUpdatedAt = user.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertGreaterThan(fetchedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(fetched.ACL)

            //Should be updated in memory
            XCTAssertEqual(User.current?.updatedAt, fetchedUpdatedAt)

            //Shold be updated in Keychain
            guard let keychainUser: CurrentUserContainer<BaseParseUser>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainUser.currentUser?.updatedAt, fetchedUpdatedAt)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetchAsyncAndUpdateCurrentUser() { // swiftlint:disable:this function_body_length
        XCTAssertNil(User.current?.objectId)
        testUserLogin()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        var userOnServer = user
        userOnServer.createdAt = User.current?.createdAt
        userOnServer.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder(skipKeys: false).encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation1 = XCTestExpectation(description: "Fetch user1")
        user.fetch(options: [], callbackQueue: .global(qos: .background)) { result in

            switch result {
            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: userOnServer))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = user.createdAt,
                    let originalUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(fetched.ACL)

                //Should be updated in memory
                XCTAssertEqual(User.current?.updatedAt, fetchedUpdatedAt)

                //Shold be updated in Keychain
                guard let keychainUser: CurrentUserContainer<BaseParseUser>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                        XCTFail("Should get object from Keychain")
                    return
                }
                XCTAssertEqual(keychainUser.currentUser?.updatedAt, fetchedUpdatedAt)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    // swiftlint:disable:next function_body_length
    func fetchAsync(user: User, userOnServer: User) {

        let expectation1 = XCTestExpectation(description: "Fetch user1")
        user.fetch(options: [], callbackQueue: .global(qos: .background)) { result in

            switch result {

            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: userOnServer))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                guard let originalCreatedAt = userOnServer.createdAt,
                    let originalUpdatedAt = userOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(fetched.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Fetch user2")
        user.fetch(options: [.sessionToken("")], callbackQueue: .global(qos: .background)) { result in

            switch result {

            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: userOnServer))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                guard let originalCreatedAt = userOnServer.createdAt,
                    let originalUpdatedAt = userOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(fetched.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
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
        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder(skipKeys: false).encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
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

    func testSaveAndUpdateCurrentUser() { // swiftlint:disable:this function_body_length
        XCTAssertNil(User.current?.objectId)
        testUserLogin()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        var userOnServer = user
        userOnServer.createdAt = User.current?.createdAt
        userOnServer.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder(skipKeys: false).encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let fetched = try user.save(options: [.useMasterKey])
            XCTAssert(fetched.hasSameObjectId(as: userOnServer))
            guard let fetchedCreatedAt = fetched.createdAt,
                let fetchedUpdatedAt = fetched.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = user.createdAt,
                let originalUpdatedAt = user.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertGreaterThan(fetchedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(fetched.ACL)

            //Should be updated in memory
            XCTAssertEqual(User.current?.updatedAt, fetchedUpdatedAt)

            //Shold be updated in Keychain
            guard let keychainUser: CurrentUserContainer<BaseParseUser>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainUser.currentUser?.updatedAt, fetchedUpdatedAt)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAsyncAndUpdateCurrentUser() { // swiftlint:disable:this function_body_length
        XCTAssertNil(User.current?.objectId)
        testUserLogin()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        var userOnServer = user
        userOnServer.createdAt = User.current?.createdAt
        userOnServer.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder(skipKeys: false).encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation1 = XCTestExpectation(description: "Fetch user1")
        user.save(options: [], callbackQueue: .global(qos: .background)) { result in

            switch result {
            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: userOnServer))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = user.createdAt,
                    let originalUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(fetched.ACL)

                //Should be updated in memory
                XCTAssertEqual(User.current?.updatedAt, fetchedUpdatedAt)

                //Shold be updated in Keychain
                guard let keychainUser: CurrentUserContainer<BaseParseUser>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                        XCTFail("Should get object from Keychain")
                    return
                }
                XCTAssertEqual(keychainUser.currentUser?.updatedAt, fetchedUpdatedAt)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
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

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder(skipKeys: false).encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
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

    // swiftlint:disable:next function_body_length
    func updateAsync(user: User, userOnServer: User, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update user1")
        user.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
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
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Update user2")
        user.save(options: [.useMasterKey], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                guard let originalCreatedAt = user.createdAt,
                    let originalUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
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
        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder(skipKeys: false).encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
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
        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder(skipKeys: false).encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        self.updateAsync(user: user, userOnServer: userOnServer, callbackQueue: .main)
    }

    func testUserSignUp() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder(skipKeys: false).encode(loginResponse)
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

            guard let userFromKeychain = BaseParseUser.current else {
                XCTFail("Couldn't get CurrentUser from Keychain")
                return
            }

            XCTAssertNotNil(userFromKeychain.createdAt)
            XCTAssertNotNil(userFromKeychain.updatedAt)
            XCTAssertNotNil(userFromKeychain.email)
            XCTAssertNotNil(userFromKeychain.username)
            XCTAssertNotNil(userFromKeychain.password)
            XCTAssertNotNil(userFromKeychain.objectId)
            XCTAssertNotNil(userFromKeychain.sessionToken)
            XCTAssertNil(userFromKeychain.ACL)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func signUpAsync(loginResponse: LoginSignupResponse, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Signup user1")
        User.signup(username: loginResponse.username!, password: loginResponse.password!,
                    callbackQueue: callbackQueue) { result in
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

                guard let userFromKeychain = BaseParseUser.current else {
                    XCTFail("Couldn't get CurrentUser from Keychain")
                    return
                }

                XCTAssertNotNil(userFromKeychain.createdAt)
                XCTAssertNotNil(userFromKeychain.updatedAt)
                XCTAssertNotNil(userFromKeychain.email)
                XCTAssertNotNil(userFromKeychain.username)
                XCTAssertNotNil(userFromKeychain.password)
                XCTAssertNotNil(userFromKeychain.objectId)
                XCTAssertNotNil(userFromKeychain.sessionToken)
                XCTAssertNil(userFromKeychain.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testSignUpAsyncMainQueue() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder(skipKeys: false).encode(loginResponse)
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
                let encoded = try loginResponse.getEncoder(skipKeys: false).encode(loginResponse)
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

            guard let userFromKeychain = BaseParseUser.current else {
                XCTFail("Couldn't get CurrentUser from Keychain")
                return
            }

            XCTAssertNotNil(userFromKeychain.createdAt)
            XCTAssertNotNil(userFromKeychain.updatedAt)
            XCTAssertNotNil(userFromKeychain.email)
            XCTAssertNotNil(userFromKeychain.username)
            XCTAssertNotNil(userFromKeychain.password)
            XCTAssertNotNil(userFromKeychain.objectId)
            XCTAssertNotNil(userFromKeychain.sessionToken)
            XCTAssertNil(userFromKeychain.ACL)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func userLoginAsync(loginResponse: LoginSignupResponse, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Login user")
        User.login(username: loginResponse.username!, password: loginResponse.password!,
                   callbackQueue: callbackQueue) { result in

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

                guard let userFromKeychain = BaseParseUser.current else {
                    XCTFail("Couldn't get CurrentUser from Keychain")
                    return
                }

                XCTAssertNotNil(userFromKeychain.createdAt)
                XCTAssertNotNil(userFromKeychain.updatedAt)
                XCTAssertNotNil(userFromKeychain.email)
                XCTAssertNotNil(userFromKeychain.username)
                XCTAssertNotNil(userFromKeychain.password)
                XCTAssertNotNil(userFromKeychain.objectId)
                XCTAssertNotNil(userFromKeychain.sessionToken)
                XCTAssertNil(userFromKeychain.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testLoginAsyncMainQueue() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder(skipKeys: false).encode(loginResponse)
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
                let encoded = try loginResponse.getEncoder(skipKeys: false).encode(loginResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            try User.logout()
            if let userFromKeychain = BaseParseUser.current {
                XCTFail("\(userFromKeychain) wasn't deleted from Keychain during logout")
                return
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func logoutAsync(callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        User.logout(callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let success):
                XCTAssertTrue(success)
                if let userFromKeychain = BaseParseUser.current {
                    XCTFail("\(userFromKeychain) wasn't deleted from Keychain during logout")
                    expectation1.fulfill()
                    return
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testLogoutAsyncMainQueue() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder(skipKeys: false).encode(loginResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.logoutAsync(callbackQueue: .main)
    }

    func testUserCustomValuesNotSavedToKeychain() {
        testUserLogin()
        User.current?.customKey = "Changed"
        User.saveCurrentContainerToKeychain()
        guard let keychainUser: CurrentUserContainer<User>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                XCTFail("Should get object from Keychain")
            return
        }
        XCTAssertNil(keychainUser.currentUser?.customKey)
    }
} // swiftlint:disable:this file_length
