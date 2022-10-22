//
//  ParseUserTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/21/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseUserTests: XCTestCase { // swiftlint:disable:this type_body_length

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

        // Your custom keys
        var customKey: String?

        //: Implement your own version of merge
        func merge(with object: Self) throws -> Self {
            var updated = try mergeParse(with: object)
            if updated.shouldRestoreKey(\.customKey,
                                         original: object) {
                updated.customKey = object.customKey
            }
            return updated
        }
    }

    struct UserDefaultMerge: ParseUser {

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

        // Your custom keys
        var customKey: String?
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
            self.emailVerified = false
        }

        func createUser() -> User {
            var user = User()
            user.objectId = objectId
            user.ACL = ACL
            user.customKey = customKey
            user.username = username
            user.email = email
            return user
        }
    }

    let loginUserName = "hello10"
    let loginPassword = "world"

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              primaryKey: "primaryKey",
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

    func testMerge() throws {
        // Signup current User
        XCTAssertNil(User.current?.objectId)
        try userSignUp()
        XCTAssertNotNil(User.current?.objectId)

        guard var original = User.current else {
            XCTFail("Should have unwrapped")
            return
        }
        original.objectId = "yolo"
        original.createdAt = Date()
        original.updatedAt = Date()
        original.authData = ["hello": ["world": "yolo"]]
        var acl = ParseACL()
        acl.publicRead = true
        original.ACL = acl

        var updated = original.mergeable
        updated.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())
        updated.email = "swift@parse.com"
        updated.username = "12345"
        updated.customKey = "newKey"
        let merged = try updated.merge(with: original)
        XCTAssertEqual(merged.customKey, updated.customKey)
        XCTAssertEqual(merged.email, updated.email)
        XCTAssertEqual(merged.emailVerified, original.emailVerified)
        XCTAssertEqual(merged.username, updated.username)
        XCTAssertEqual(merged.authData, original.authData)
        XCTAssertEqual(merged.ACL, original.ACL)
        XCTAssertEqual(merged.createdAt, original.createdAt)
        XCTAssertEqual(merged.updatedAt, updated.updatedAt)
    }

    func testMerge2() throws {
        // Signup current User
        XCTAssertNil(User.current?.objectId)
        try userSignUp()
        XCTAssertNotNil(User.current?.objectId)

        guard var original = User.current else {
            XCTFail("Should have unwrapped")
            return
        }
        original.objectId = "yolo"
        original.createdAt = Date()
        original.updatedAt = Date()
        var acl = ParseACL()
        acl.publicRead = true
        original.ACL = acl

        var updated = original.mergeable
        updated.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())
        updated.customKey = "newKey"
        let merged = try updated.merge(with: original)
        XCTAssertEqual(merged.customKey, updated.customKey)
        XCTAssertEqual(merged.email, original.email)
        XCTAssertEqual(merged.emailVerified, original.emailVerified)
        XCTAssertEqual(merged.username, original.username)
        XCTAssertEqual(merged.authData, original.authData)
        XCTAssertEqual(merged.ACL, original.ACL)
        XCTAssertEqual(merged.createdAt, original.createdAt)
        XCTAssertEqual(merged.updatedAt, updated.updatedAt)
    }

    func testMergeDefaultImplementation() throws {
        // Signup current User
        XCTAssertNil(User.current?.objectId)
        try userSignUp()
        XCTAssertNotNil(User.current?.objectId)

        guard let currentUser = User.current else {
            XCTFail("Should have unwrapped")
            return
        }
        var original = UserDefaultMerge()
        original.username = currentUser.username
        original.email = currentUser.email
        original.customKey = currentUser.customKey
        original.objectId = "yolo"
        original.createdAt = Date()
        original.updatedAt = Date()
        var acl = ParseACL()
        acl.publicRead = true
        original.ACL = acl

        var updated = original.set(\.customKey, to: "newKey")
        updated.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())
        original.customKey = updated.customKey
        original.updatedAt = updated.updatedAt
        var merged = try updated.merge(with: original)
        merged.originalData = nil
        // Get dates in correct format from ParseDecoding strategy
        let encoded = try ParseCoding.jsonEncoder().encode(original)
        original = try ParseCoding.jsonDecoder().decode(UserDefaultMerge.self, from: encoded)
        XCTAssertEqual(merged, original)
    }

    func testMergeDifferentObjectId() throws {
        var user = User()
        user.objectId = "yolo"
        var user2 = user
        user2.objectId = "nolo"
        XCTAssertThrowsError(try user2.merge(with: user))
    }

    func testFetchCommand() {
        var user = User()
        XCTAssertThrowsError(try user.fetchCommand(include: nil))
        let objectId = "yarr"
        user.objectId = objectId
        do {
            let command = try user.fetchCommand(include: nil)
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }

        let user2 = User()
        XCTAssertThrowsError(try user2.fetchCommand(include: nil))
    }

    func testFetchIncludeCommand() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        let includeExpected = ["include": "[\"yolo\", \"test\"]"]
        do {
            let command = try user.fetchCommand(include: ["yolo", "test"])
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertEqual(command.params?.keys.first, includeExpected.keys.first)
            if let value = command.params?.values.first,
                let includeValue = value {
                XCTAssertTrue(includeValue.contains("\"yolo\""))
            } else {
                XCTFail("Should have unwrapped value")
            }
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }

        let user2 = User()
        XCTAssertThrowsError(try user2.fetchCommand(include: nil))
    }

    func testFetch() { // swiftlint:disable:this function_body_length
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        var userOnServer = user
        userOnServer.createdAt = Date()
        userOnServer.updatedAt = userOnServer.createdAt
        userOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
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
            let fetched = try user.fetch(options: [.usePrimaryKey])
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
        testLogin()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        var userOnServer = user
        userOnServer.createdAt = User.current?.createdAt
        userOnServer.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)
        userOnServer.customKey = "newValue"

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
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
            let fetched = try user.fetch(options: [.usePrimaryKey])
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
            XCTAssertEqual(fetched.customKey, userOnServer.customKey)

            //Should be updated in memory
            XCTAssertEqual(User.current?.updatedAt, fetchedUpdatedAt)
            XCTAssertEqual(User.current?.customKey, userOnServer.customKey)

            //Should be updated in Keychain
            #if !os(Linux) && !os(Android) && !os(Windows)
            guard let keychainUser: CurrentUserContainer<BaseParseUser>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainUser.currentUser?.updatedAt, fetchedUpdatedAt)
            #endif

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetchAsyncAndUpdateCurrentUser() { // swiftlint:disable:this function_body_length
        XCTAssertNil(User.current?.objectId)
        testLogin()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        var userOnServer = user
        userOnServer.createdAt = User.current?.createdAt
        userOnServer.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)
        userOnServer.customKey = "newValue"

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
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
                    expectation1.fulfill()
                        return
                }
                guard let originalCreatedAt = user.createdAt,
                    let originalUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(fetched.ACL)
                XCTAssertEqual(User.current?.customKey, userOnServer.customKey)

                //Should be updated in memory
                XCTAssertEqual(User.current?.updatedAt, fetchedUpdatedAt)

                #if !os(Linux) && !os(Android) && !os(Windows)
                //Should be updated in Keychain
                guard let keychainUser: CurrentUserContainer<BaseParseUser>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                        XCTFail("Should get object from Keychain")
                        expectation1.fulfill()
                    return
                }
                XCTAssertEqual(keychainUser.currentUser?.updatedAt, fetchedUpdatedAt)
                #endif
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
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
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
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
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
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
    #endif

    func testSaveCommand() throws {
        let user = User()

        let command = try user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    func testSaveUpdateCommand() throws {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        let command = try user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    func testCreateCommand() throws {
        let user = User()

        let command = user.createCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    func testReplaceCommand() throws {
        var user = User()
        XCTAssertThrowsError(try user.replaceCommand())
        let objectId = "yarr"
        user.objectId = objectId

        let command = try user.replaceCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    func testUpdateCommand() throws {
        var user = User()
        XCTAssertThrowsError(try user.updateCommand())
        let objectId = "yarr"
        user.objectId = objectId

        let command = try user.updateCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PATCH)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    func userSignUp() throws {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        _ = try loginResponse.createUser().signup()
        MockURLProtocol.removeAll()
        guard let currentUser = User.current else {
            XCTFail("Should have a current user after signup")
            return
        }
        XCTAssertEqual(currentUser.objectId, loginResponse.objectId)
        XCTAssertEqual(currentUser.username, loginResponse.username)
        XCTAssertEqual(currentUser.email, loginResponse.email)
        XCTAssertEqual(currentUser.ACL, loginResponse.ACL)
        XCTAssertEqual(currentUser.customKey, loginResponse.customKey)
    }

    func testUpdateCommandUnmodifiedEmail() throws {
        try userSignUp()
        guard let user = User.current,
              let objectId = user.objectId else {
            XCTFail("Should have current user.")
            return
        }
        XCTAssertNotNil(user.email)
        let command = try user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertNil(command.body?.email)
    }

    func testUpdateCommandModifiedEmail() throws {
        try userSignUp()
        guard var user = User.current,
              let objectId = user.objectId else {
            XCTFail("Should have current user.")
            return
        }
        let email = "peace@parse.com"
        user.email = email
        XCTAssertNotNil(user.email)
        let command = try user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertEqual(command.body?.email, email)
    }

    func testUpdateCommandNotCurrentModifiedEmail() throws {
        try userSignUp()
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        let email = "peace@parse.com"
        user.email = email
        XCTAssertNotNil(user.email)
        let command = try user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertEqual(command.body?.email, email)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testUpdateCommandCurrentUserModifiedEmail() throws {
        try userSignUp()
        guard let user = User.current,
              let objectId = user.objectId else {
            XCTFail("Should have current user.")
            return
        }
        let email = "peace@parse.com"
        User.current?.email = email
        XCTAssertNotNil(User.current?.email)
        let command = try User.current?.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command?.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command?.method, API.Method.PUT)
        XCTAssertNil(command?.params)
        XCTAssertNotNil(command?.body)
        XCTAssertEqual(command?.body?.email, email)
    }

    func testUpdateCommandCurrentUserNotCurrentModifiedEmail() throws {
        try userSignUp()
        guard let user = User.current,
              let objectId = user.objectId else {
            XCTFail("Should have current user.")
            return
        }
        let email = "peace@parse.com"
        User.current?.email = email
        XCTAssertNotNil(User.current?.email)
        let command = try User.current?.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command?.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command?.method, API.Method.PUT)
        XCTAssertNil(command?.params)
        XCTAssertNotNil(command?.body)
        XCTAssertEqual(command?.body?.email, email)
    }
    #endif

    func testSaveAndUpdateCurrentUser() throws { // swiftlint:disable:this function_body_length
        XCTAssertNil(User.current?.objectId)
        try userSignUp()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }
        XCTAssertNotNil(user.email)
        var userOnServer = user
        userOnServer.createdAt = nil
        userOnServer.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
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
            let saved = try user.save(options: [.usePrimaryKey])
            XCTAssert(saved.hasSameObjectId(as: userOnServer))
            XCTAssertEqual(saved.email, user.email)
            guard let savedCreatedAt = saved.createdAt,
                let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, user.createdAt)
            XCTAssertEqual(savedUpdatedAt, userOnServer.updatedAt)
            XCTAssertNil(saved.ACL)

            //Should be updated in memory
            XCTAssertEqual(User.current?.updatedAt, savedUpdatedAt)
            XCTAssertEqual(User.current?.email, user.email)

            #if !os(Linux) && !os(Android) && !os(Windows)
            //Should be updated in Keychain
            guard let keychainUser: CurrentUserContainer<BaseParseUser>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainUser.currentUser?.updatedAt, savedUpdatedAt)
            XCTAssertEqual(keychainUser.currentUser?.email, user.email)
            #endif

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAndUpdateCurrentUserModifiedEmail() throws { // swiftlint:disable:this function_body_length
        XCTAssertNil(User.current?.objectId)
        try userSignUp()
        XCTAssertNotNil(User.current?.objectId)

        guard var user = User.current else {
            XCTFail("Should unwrap")
            return
        }
        user.email = "pease@parse.com"
        XCTAssertNotEqual(User.current?.email, user.email)
        var userOnServer = user
        userOnServer.createdAt = nil
        userOnServer.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
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
            let saved = try user.save(options: [.usePrimaryKey])
            XCTAssert(saved.hasSameObjectId(as: userOnServer))
            XCTAssertEqual(saved.email, user.email)
            guard let savedCreatedAt = saved.createdAt,
                let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, user.createdAt)
            XCTAssertEqual(savedUpdatedAt, userOnServer.updatedAt)
            XCTAssertNil(saved.ACL)

            //Should be updated in memory
            XCTAssertEqual(User.current?.updatedAt, savedUpdatedAt)
            XCTAssertEqual(User.current?.email, user.email)

            #if !os(Linux) && !os(Android) && !os(Windows)
            //Should be updated in Keychain
            guard let keychainUser: CurrentUserContainer<BaseParseUser>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainUser.currentUser?.updatedAt, savedUpdatedAt)
            XCTAssertEqual(keychainUser.currentUser?.email, user.email)
            #endif

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveMutableMergeCurrentUser() throws {
        // Signup current User
        XCTAssertNil(User.current?.objectId)
        try userSignUp()
        XCTAssertNotNil(User.current?.objectId)

        guard let original = User.current else {
            XCTFail("Should unwrap")
            return
        }
        var response = original.mergeable
        response.createdAt = nil
        response.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())

        let encoded: Data!
        do {
            encoded = try response.getEncoder().encode(response, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            response = try response.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        var updated = original.mergeable
        updated.customKey = "beast"
        updated.username = "mode"

        do {
            let saved = try updated.save()
            let expectation1 = XCTestExpectation(description: "Update installation1")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                guard let newCurrentUser = User.current else {
                    XCTFail("Should have a new current installation")
                    expectation1.fulfill()
                    return
                }
                XCTAssertTrue(saved.hasSameObjectId(as: newCurrentUser))
                XCTAssertTrue(saved.hasSameObjectId(as: response))
                XCTAssertEqual(saved.customKey, updated.customKey)
                XCTAssertEqual(saved.email, original.email)
                XCTAssertEqual(saved.username, updated.username)
                XCTAssertEqual(saved.emailVerified, original.emailVerified)
                XCTAssertEqual(saved.password, original.password)
                XCTAssertEqual(saved.authData, original.authData)
                XCTAssertEqual(saved.createdAt, original.createdAt)
                XCTAssertEqual(saved.updatedAt, response.updatedAt)
                XCTAssertNil(saved.originalData)
                XCTAssertEqual(saved.customKey, newCurrentUser.customKey)
                XCTAssertEqual(saved.email, newCurrentUser.email)
                XCTAssertEqual(saved.username, newCurrentUser.username)
                XCTAssertEqual(saved.emailVerified, newCurrentUser.emailVerified)
                XCTAssertEqual(saved.password, newCurrentUser.password)
                XCTAssertEqual(saved.authData, newCurrentUser.authData)
                XCTAssertEqual(saved.createdAt, newCurrentUser.createdAt)
                XCTAssertEqual(saved.updatedAt, newCurrentUser.updatedAt)
                expectation1.fulfill()
            }
            wait(for: [expectation1], timeout: 20.0)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAsyncAndUpdateCurrentUser() throws { // swiftlint:disable:this function_body_length
        XCTAssertNil(User.current?.objectId)
        try userSignUp()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }
        XCTAssertNotNil(user.email)
        var userOnServer = user
        userOnServer.createdAt = nil
        userOnServer.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
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
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: userOnServer))
                XCTAssertEqual(saved.email, user.email)
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                        return
                }
                XCTAssertEqual(savedCreatedAt, user.createdAt)
                XCTAssertEqual(savedUpdatedAt, userOnServer.updatedAt)
                XCTAssertNil(saved.ACL)

                //Should be updated in memory
                XCTAssertEqual(User.current?.updatedAt, savedUpdatedAt)
                XCTAssertEqual(User.current?.email, user.email)

                #if !os(Linux) && !os(Android) && !os(Windows)
                //Should be updated in Keychain
                guard let keychainUser: CurrentUserContainer<BaseParseUser>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                        XCTFail("Should get object from Keychain")
                    return
                }
                XCTAssertEqual(keychainUser.currentUser?.updatedAt, savedUpdatedAt)
                XCTAssertEqual(keychainUser.currentUser?.email, user.email)
                #endif

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveAsyncAndUpdateCurrentUserModifiedEmail() throws { // swiftlint:disable:this function_body_length
        XCTAssertNil(User.current?.objectId)
        try userSignUp()
        XCTAssertNotNil(User.current?.objectId)

        guard var user = User.current else {
            XCTFail("Should unwrap")
            return
        }
        user.email = "pease@parse.com"
        XCTAssertNotEqual(User.current?.email, user.email)
        var userOnServer = user
        userOnServer.createdAt = nil
        userOnServer.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
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
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: userOnServer))
                XCTAssertEqual(saved.email, user.email)
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                        return
                }
                XCTAssertEqual(savedCreatedAt, user.createdAt)
                XCTAssertEqual(savedUpdatedAt, userOnServer.updatedAt)
                XCTAssertNil(saved.ACL)

                //Should be updated in memory
                XCTAssertEqual(User.current?.updatedAt, savedUpdatedAt)
                XCTAssertEqual(User.current?.email, user.email)

                #if !os(Linux) && !os(Android) && !os(Windows)
                //Should be updated in Keychain
                guard let keychainUser: CurrentUserContainer<BaseParseUser>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                        XCTFail("Should get object from Keychain")
                    return
                }
                XCTAssertEqual(keychainUser.currentUser?.updatedAt, savedUpdatedAt)
                XCTAssertEqual(keychainUser.currentUser?.email, user.email)
                #endif

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUpdate() { // swiftlint:disable:this function_body_length
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
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
            guard let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            guard let originalUpdatedAt = user.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try user.save(options: [.usePrimaryKey])
            guard let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            guard let originalUpdatedAt = user.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveWithDefaultACL() throws { // swiftlint:disable:this function_body_length
        try userSignUp()
        guard let userObjectId = User.current?.objectId else {
            XCTFail("Should have objectId")
            return
        }
        let defaultACL = try ParseACL.setDefaultACL(ParseACL(),
                                                    withAccessForCurrentUser: true)

        let user = User()
        var userOnServer = user
        userOnServer.objectId = "hello"
        userOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
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
            let saved = try user.save(options: [.usePrimaryKey])
            XCTAssert(saved.hasSameObjectId(as: userOnServer))
            guard let savedCreatedAt = saved.createdAt,
                let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = userOnServer.createdAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, originalCreatedAt)
            XCTAssertEqual(savedUpdatedAt, originalCreatedAt)
            XCTAssertNotNil(saved.ACL)
            XCTAssertEqual(saved.ACL?.publicRead, defaultACL.publicRead)
            XCTAssertEqual(saved.ACL?.publicWrite, defaultACL.publicWrite)
            XCTAssertTrue(defaultACL.getReadAccess(objectId: userObjectId))
            XCTAssertTrue(defaultACL.getWriteAccess(objectId: userObjectId))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdateWithDefaultACL() throws { // swiftlint:disable:this function_body_length
        try userSignUp()
        _ = try ParseACL.setDefaultACL(ParseACL(),
                                                    withAccessForCurrentUser: true)
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
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
            guard let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            guard let originalUpdatedAt = user.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func updateAsync(user: User, userOnServer: User, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update user1")
        user.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                guard let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                guard let originalUpdatedAt = user.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Update user2")
        user.save(options: [.usePrimaryKey], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                guard let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation2.fulfill()
                    return
                }
                guard let originalUpdatedAt = user.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation2.fulfill()
                    return
                }

                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeUpdateAsync() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.updatedAt = Date()
        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
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
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.updatedAt = Date()
        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
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
    #endif

    func testSignupCommandWithBody() throws {
        let body = SignupLoginBody(username: "test", password: "user")
        let command = try User.signupCommand(body: body)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertEqual(command.body?.username, body.username)
        XCTAssertEqual(command.body?.password, body.password)
    }

    func testSignupCommandNoBody() throws {
        var user = User()
        user.username = "test"
        user.password = "user"
        user.customKey = "hello"
        let command = try user.signupCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertEqual(command.body?.username, "test")
        XCTAssertEqual(command.body?.password, "user")
        XCTAssertEqual(command.body?.customKey, "hello")
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
            XCTAssertNotNil(signedUp.email)
            XCTAssertNotNil(signedUp.emailVerified)
            XCTAssertNotNil(signedUp.username)
            XCTAssertNil(signedUp.password)
            XCTAssertNotNil(signedUp.objectId)
            XCTAssertNotNil(signedUp.sessionToken)
            XCTAssertNotNil(signedUp.customKey)
            XCTAssertNil(signedUp.ACL)

            guard let userFromKeychain = BaseParseUser.current else {
                XCTFail("Could not get CurrentUser from Keychain")
                return
            }

            XCTAssertNotNil(userFromKeychain.createdAt)
            XCTAssertNotNil(userFromKeychain.updatedAt)
            XCTAssertNotNil(userFromKeychain.email)
            XCTAssertNotNil(userFromKeychain.username)
            XCTAssertNil(userFromKeychain.password)
            XCTAssertNotNil(userFromKeychain.objectId)
            XCTAssertNotNil(userFromKeychain.sessionToken)
            XCTAssertNil(userFromKeychain.ACL)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUserSignUpNoBody() {
        var loginResponse = LoginSignupResponse()
        loginResponse.email = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            var user = User()
            user.username = loginUserName
            user.password = loginPassword
            user.customKey = "blah"
            let signedUp = try user.signup()
            XCTAssertNotNil(signedUp)
            XCTAssertNotNil(signedUp.createdAt)
            XCTAssertNotNil(signedUp.updatedAt)
            XCTAssertNil(signedUp.email)
            XCTAssertNotNil(signedUp.username)
            XCTAssertNil(signedUp.password)
            XCTAssertNotNil(signedUp.objectId)
            XCTAssertNotNil(signedUp.sessionToken)
            XCTAssertNotNil(signedUp.customKey)
            XCTAssertNil(signedUp.ACL)

            guard let userFromKeychain = BaseParseUser.current else {
                XCTFail("Could not get CurrentUser from Keychain")
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
                XCTAssertNotNil(signedUp.email)
                XCTAssertNotNil(signedUp.username)
                XCTAssertNil(signedUp.password)
                XCTAssertNotNil(signedUp.objectId)
                XCTAssertNotNil(signedUp.sessionToken)
                XCTAssertNotNil(signedUp.customKey)
                XCTAssertNil(signedUp.ACL)

                guard let userFromKeychain = BaseParseUser.current else {
                    XCTFail("Could not get CurrentUser from Keychain")
                    expectation1.fulfill()
                    return
                }

                XCTAssertNotNil(userFromKeychain.createdAt)
                XCTAssertNotNil(userFromKeychain.updatedAt)
                XCTAssertNotNil(userFromKeychain.email)
                XCTAssertNotNil(userFromKeychain.username)
                XCTAssertNil(userFromKeychain.password)
                XCTAssertNotNil(userFromKeychain.objectId)
                XCTAssertNotNil(userFromKeychain.sessionToken)
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

    func signUpAsyncNoBody(loginResponse: LoginSignupResponse, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Signup user1")
        var user = User()
        user.username = loginUserName
        user.password = loginPassword
        user.customKey = "blah"
        user.signup(callbackQueue: callbackQueue) { result in
            switch result {

            case .success(let signedUp):
                XCTAssertNotNil(signedUp.createdAt)
                XCTAssertNotNil(signedUp.updatedAt)
                XCTAssertNil(signedUp.email)
                XCTAssertNotNil(signedUp.username)
                XCTAssertNil(signedUp.password)
                XCTAssertNotNil(signedUp.objectId)
                XCTAssertNotNil(signedUp.sessionToken)
                XCTAssertNotNil(signedUp.customKey)
                XCTAssertNil(signedUp.ACL)

                guard let userFromKeychain = BaseParseUser.current else {
                    XCTFail("Could not get CurrentUser from Keychain")
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
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSignUpAsyncMainQueueNoBody() {
        var loginResponse = LoginSignupResponse()
        loginResponse.email = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.signUpAsyncNoBody(loginResponse: loginResponse, callbackQueue: .main)
    }

    func testLoginCommand() {
        let command = User.loginCommand(username: "test", password: "user")
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/login")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNotNil(command.body)
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
            XCTAssertNotNil(loggedIn.email)
            XCTAssertNotNil(loggedIn.username)
            XCTAssertNil(loggedIn.password)
            XCTAssertNotNil(loggedIn.objectId)
            XCTAssertNotNil(loggedIn.sessionToken)
            XCTAssertNotNil(loggedIn.customKey)
            XCTAssertNil(loggedIn.ACL)

            guard let userFromKeychain = BaseParseUser.current else {
                XCTFail("Could not get CurrentUser from Keychain")
                return
            }

            XCTAssertNotNil(userFromKeychain.createdAt)
            XCTAssertNotNil(userFromKeychain.updatedAt)
            XCTAssertNotNil(userFromKeychain.email)
            XCTAssertNotNil(userFromKeychain.username)
            XCTAssertNil(userFromKeychain.password)
            XCTAssertNotNil(userFromKeychain.objectId)
            XCTAssertNotNil(userFromKeychain.sessionToken)
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
                XCTAssertNotNil(loggedIn.email)
                XCTAssertNotNil(loggedIn.username)
                XCTAssertNil(loggedIn.password)
                XCTAssertNotNil(loggedIn.objectId)
                XCTAssertNotNil(loggedIn.sessionToken)
                XCTAssertNotNil(loggedIn.customKey)
                XCTAssertNil(loggedIn.ACL)

                guard let userFromKeychain = BaseParseUser.current else {
                    XCTFail("Could not get CurrentUser from Keychain")
                    expectation1.fulfill()
                    return
                }

                XCTAssertNotNil(userFromKeychain.createdAt)
                XCTAssertNotNil(userFromKeychain.updatedAt)
                XCTAssertNotNil(userFromKeychain.email)
                XCTAssertNotNil(userFromKeychain.username)
                XCTAssertNil(userFromKeychain.password)
                XCTAssertNotNil(userFromKeychain.objectId)
                XCTAssertNotNil(userFromKeychain.sessionToken)
                XCTAssertNil(userFromKeychain.ACL)
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

    func testLogutCommand() {
        let command = User.logoutCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/logout")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.body)
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
        let expectation1 = XCTestExpectation(description: "Logout user1")
        guard let oldInstallationId = BaseParseInstallation.current?.installationId else {
            XCTFail("Should have unwrapped")
            expectation1.fulfill()
            return
        }
        do {
            try User.logout()
            if let userFromKeychain = BaseParseUser.current {
                XCTFail("\(userFromKeychain) was not deleted from Keychain during logout")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if let installationFromKeychain = BaseParseInstallation.current {

                        if installationFromKeychain.installationId == oldInstallationId
                            || installationFromKeychain.installationId == nil {
                            XCTFail("""
                                "\(installationFromKeychain) was not deleted then created in
                                Keychain during logout
                            """)
                        }

                } else {
                    XCTFail("Should have a new installation")
                }
                expectation1.fulfill()
            }
        } catch {
            XCTFail(error.localizedDescription)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func logoutAsync(callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")

        guard let oldInstallationId = BaseParseInstallation.current?.installationId else {
            XCTFail("Should have unwrapped")
            expectation1.fulfill()
            return
        }

        User.logout(callbackQueue: callbackQueue) { result in

            switch result {

            case .success:
                if let userFromKeychain = BaseParseUser.current {
                    XCTFail("\(userFromKeychain) was not deleted from Keychain during logout")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if let installationFromMemory: CurrentInstallationContainer<BaseParseInstallation>
                        = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {

                            if installationFromMemory.installationId == oldInstallationId
                                || installationFromMemory.installationId == nil {
                                XCTFail("\(installationFromMemory) was not deleted & recreated in memory during logout")
                            }
                    } else {
                        XCTFail("Should have a new installation")
                    }

                    #if !os(Linux) && !os(Android) && !os(Windows)
                    if let installationFromKeychain: CurrentInstallationContainer<BaseParseInstallation>
                        = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                            if installationFromKeychain.installationId == oldInstallationId
                                || installationFromKeychain.installationId == nil {
                                // swiftlint:disable:next line_length
                                XCTFail("\(installationFromKeychain) was not deleted & recreated in Keychain during logout")
                            }
                    } else {
                        XCTFail("Should have a new installation")
                    }
                    #endif
                    expectation1.fulfill()
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation1.fulfill()
            }
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

    func testPasswordResetCommand() throws {
        let body = EmailBody(email: "hello@parse.org")
        let command = User.passwordResetCommand(email: body.email)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/requestPasswordReset")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertEqual(command.body?.email, body.email)
    }

    func testPasswordReset() {
        let response = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            try User.passwordReset(email: "hello@parse.org")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testPasswordResetError() {

        let parseError = ParseError(code: .internalServer, message: "Object not found")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(parseError)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        do {
            try User.passwordReset(email: "hello@parse.org")
            XCTFail("Should have thrown ParseError")
        } catch {
            if let error = error as? ParseError {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
        }
    }

    func passwordResetAsync(callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        User.passwordReset(email: "hello@parse.org", callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testPasswordResetMainQueue() {
        let response = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.passwordResetAsync(callbackQueue: .main)
    }

    func passwordResetAsyncError(parseError: ParseError, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        User.passwordReset(email: "hello@parse.org", callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testPasswordResetMainQueueError() {
        let parseError = ParseError(code: .internalServer, message: "Object not found")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.passwordResetAsyncError(parseError: parseError, callbackQueue: .main)
    }

    func testVerifyPasswordCommandPOST() throws {
        let username = "hello"
        let password = "world"
        let command = User.verifyPasswordCommand(username: username,
                                                 password: password,
                                                 method: .POST)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/verifyPassword")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertEqual(command.body?.username, username)
        XCTAssertEqual(command.body?.password, password)
        XCTAssertNil(command.params)
    }

    func testVerifyPasswordCommandGET() throws {
        let username = "hello"
        let password = "world"
        let params = ["username": username,
                      "password": password]
        let command = User.verifyPasswordCommand(username: username,
                                                 password: password,
                                                 method: .GET)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/verifyPassword")
        XCTAssertEqual(command.method, API.Method.GET)
        XCTAssertNil(command.body)
        XCTAssertEqual(command.params, params)
    }

    func testVerificationEmailRequestCommand() throws {
        let body = EmailBody(email: "hello@parse.org")
        let command = User.verificationEmailCommand(email: body.email)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/verificationEmailRequest")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertEqual(command.body?.email, body.email)
    }

    func testVerificationEmailRequestReset() {
        let response = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            try User.verificationEmail(email: "hello@parse.org")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testVerificationEmailRequestError() {

        let parseError = ParseError(code: .internalServer, message: "Object not found")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(parseError)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        do {
            try User.verificationEmail(email: "hello@parse.org")
            XCTFail("Should have thrown ParseError")
        } catch {
            if let error = error as? ParseError {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
        }
    }

    func verificationEmailAsync(callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        User.verificationEmail(email: "hello@parse.org", callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testVerificationEmailRequestMainQueue() {
        let response = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.verificationEmailAsync(callbackQueue: .main)
    }

    func verificationEmailAsyncError(parseError: ParseError, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        User.verificationEmail(email: "hello@parse.org", callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testVerificationEmailRequestMainQueueError() {
        let parseError = ParseError(code: .internalServer, message: "Object not found")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.verificationEmailAsyncError(parseError: parseError, callbackQueue: .main)
    }

    func testUserCustomValuesSavedToKeychain() {
        testLogin()
        let customField = "Changed"
        User.current?.customKey = customField
        User.saveCurrentContainerToKeychain()
        #if !os(Linux) && !os(Android) && !os(Windows)
        guard let keychainUser: CurrentUserContainer<User>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                XCTFail("Should get object from Keychain")
            return
        }
        XCTAssertEqual(keychainUser.currentUser?.customKey, customField)
        #endif
    }

    func testDeleteCommand() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        do {
            let command = try user.deleteCommand()
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
            XCTAssertEqual(command.method, API.Method.DELETE)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }

        let user2 = User()
        XCTAssertThrowsError(try user2.deleteCommand())
    }

    func testDeleteCurrent() {
        testLogin()
        let expectation1 = XCTestExpectation(description: "Delete user")
        guard let user = User.current else {
                XCTFail("Should unwrap dates")
            expectation1.fulfill()
                return
        }

        do {
            try user.delete(options: [])
            XCTAssertNil(User.current)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            try user.delete(options: [.usePrimaryKey])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDeleteCurrentAsyncMainQueue() {
        testLogin()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Delete installation1")
        guard let user = User.current else {
            XCTFail("Should unwrap")
            expectation1.fulfill()
            return
        }

        var userOnServer = user
        userOnServer.updatedAt = user.updatedAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        user.delete { result in
            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            XCTAssertNil(User.current)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    // swiftlint:disable:next function_body_length
    func testFetchAllCurrent() {
        testLogin()
        MockURLProtocol.removeAll()

        guard var user = User.current else {
            XCTFail("Should unwrap dates")
            return
        }

        user.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        user.customKey = "newValue"
        let userOnServer = QueryResponse<User>(results: [user], count: 1)

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(user)
            user = try user.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let fetched = try [user].fetchAll()
            fetched.forEach {
                switch $0 {
                case .success(let fetched):
                    XCTAssert(fetched.hasSameObjectId(as: user))
                    guard let fetchedCreatedAt = fetched.createdAt,
                        let fetchedUpdatedAt = fetched.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    guard let originalCreatedAt = user.createdAt,
                        let originalUpdatedAt = user.updatedAt,
                        let serverUpdatedAt = user.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                    XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                    XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                    XCTAssertEqual(User.current?.customKey, user.customKey)

                    //Should be updated in memory
                    guard let updatedCurrentDate = User.current?.updatedAt else {
                        XCTFail("Should unwrap current date")
                        return
                    }
                    XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                    #if !os(Linux) && !os(Android) && !os(Windows)
                    //Should be updated in Keychain
                    guard let keychainUser: CurrentUserContainer<BaseParseUser>
                        = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                        let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
                            XCTFail("Should get object from Keychain")
                        return
                    }
                    XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                    #endif
                case .failure(let error):
                    XCTFail("Should have fetched: \(error.localizedDescription)")
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length
    func testFetchAllAsyncMainQueueCurrent() {
        testLogin()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Fetch user1")
        guard var user = User.current else {
            XCTFail("Should unwrap")
            expectation1.fulfill()
            return
        }

        user.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        user.customKey = "newValue"
        let userOnServer = QueryResponse<User>(results: [user], count: 1)

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(user)
            user = try user.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        [user].fetchAll { results in
            switch results {

            case .success(let fetched):
                fetched.forEach {
                    switch $0 {
                    case .success(let fetched):
                        XCTAssert(fetched.hasSameObjectId(as: user))
                        guard let fetchedCreatedAt = fetched.createdAt,
                            let fetchedUpdatedAt = fetched.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation1.fulfill()
                                return
                        }
                        guard let originalCreatedAt = user.createdAt,
                            let originalUpdatedAt = user.updatedAt,
                            let serverUpdatedAt = user.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation1.fulfill()
                                return
                        }
                        XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                        XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                        XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                        XCTAssertEqual(User.current?.customKey, user.customKey)

                        //Should be updated in memory
                        guard let updatedCurrentDate = User.current?.updatedAt else {
                            XCTFail("Should unwrap current date")
                            expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                        #if !os(Linux) && !os(Android) && !os(Windows)
                        //Should be updated in Keychain
                        guard let keychainUser: CurrentUserContainer<BaseParseUser>
                            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                            let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
                                XCTFail("Should get object from Keychain")
                                expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                        #endif
                    case .failure(let error):
                        XCTFail("Should have fetched: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    // swiftlint:disable:next function_body_length
    func testSaveAllCurrent() {
        testLogin()
        MockURLProtocol.removeAll()

        guard var user = User.current else {
            XCTFail("Should unwrap dates")
            return
        }
        user.createdAt = nil
        var user2 = user
        user2.customKey = "oldValue"
        user.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        user.customKey = "newValue"
        let userOnServer = [BatchResponseItem<User>(success: user, error: nil),
                            BatchResponseItem<User>(success: user2, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(user)
            user = try user.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let saved = try [user].saveAll()
            saved.forEach {
                switch $0 {
                case .success(let saved):
                    XCTAssert(saved.hasSameObjectId(as: user))
                    guard let savedUpdatedAt = saved.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    guard let originalUpdatedAt = user.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertEqual(User.current?.customKey, user.customKey)

                    //Should be updated in memory
                    guard let updatedCurrentDate = User.current?.updatedAt else {
                        XCTFail("Should unwrap current date")
                        return
                    }
                    XCTAssertEqual(updatedCurrentDate, originalUpdatedAt)

                    #if !os(Linux) && !os(Android) && !os(Windows)
                    //Should be updated in Keychain
                    guard let keychainUser: CurrentUserContainer<BaseParseUser>
                        = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                        let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
                            XCTFail("Should get object from Keychain")
                        return
                    }
                    XCTAssertEqual(keychainUpdatedCurrentDate, originalUpdatedAt)
                    #endif
                case .failure(let error):
                    XCTFail("Should have fetched: \(error.localizedDescription)")
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try [user].saveAll(transaction: true)
            saved.forEach {
                switch $0 {
                case .success(let saved):
                    XCTAssert(saved.hasSameObjectId(as: user))
                    guard let savedUpdatedAt = saved.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    guard let originalUpdatedAt = user.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertEqual(User.current?.customKey, user.customKey)

                    //Should be updated in memory
                    guard let updatedCurrentDate = User.current?.updatedAt else {
                        XCTFail("Should unwrap current date")
                        return
                    }
                    XCTAssertEqual(updatedCurrentDate, originalUpdatedAt)

                    #if !os(Linux) && !os(Android) && !os(Windows)
                    //Should be updated in Keychain
                    guard let keychainUser: CurrentUserContainer<BaseParseUser>
                        = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                        let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
                            XCTFail("Should get object from Keychain")
                        return
                    }
                    XCTAssertEqual(keychainUpdatedCurrentDate, originalUpdatedAt)
                    #endif
                case .failure(let error):
                    XCTFail("Should have fetched: \(error.localizedDescription)")
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length
    func testSaveAllAsyncMainQueueCurrent() {
        testLogin()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Save user1")
        let expectation2 = XCTestExpectation(description: "Save user2")

        guard var user = User.current else {
            XCTFail("Should unwrap")
            expectation1.fulfill()
            expectation2.fulfill()
            return
        }
        user.createdAt = nil
        var user2 = user
        user2.customKey = "oldValue"
        user.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        user.customKey = "newValue"
        let userOnServer = [BatchResponseItem<User>(success: user, error: nil),
                            BatchResponseItem<User>(success: user2, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(user)
            user = try user.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            expectation2.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        [user].saveAll { results in
            switch results {

            case .success(let saved):
                saved.forEach {
                    switch $0 {
                    case .success(let saved):
                        XCTAssert(saved.hasSameObjectId(as: user))
                        guard let savedUpdatedAt = saved.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation1.fulfill()
                                return
                        }
                        guard let originalUpdatedAt = user.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation1.fulfill()
                                return
                        }
                        XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                        XCTAssertEqual(User.current?.customKey, user.customKey)

                        //Should be updated in memory
                        guard let updatedCurrentDate = User.current?.updatedAt else {
                            XCTFail("Should unwrap current date")
                            expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(updatedCurrentDate, originalUpdatedAt)

                        #if !os(Linux) && !os(Android) && !os(Windows)
                        //Should be updated in Keychain
                        guard let keychainUser: CurrentUserContainer<BaseParseUser>
                            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                            let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
                                XCTFail("Should get object from Keychain")
                                expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(keychainUpdatedCurrentDate, originalUpdatedAt)
                        #endif
                    case .failure(let error):
                        XCTFail("Should have fetched: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
            expectation1.fulfill()
        }

        [user].saveAll(transaction: true) { results in
            switch results {

            case .success(let saved):
                saved.forEach {
                    switch $0 {
                    case .success(let saved):
                        XCTAssert(saved.hasSameObjectId(as: user))
                        guard let savedUpdatedAt = saved.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation2.fulfill()
                                return
                        }
                        guard let originalUpdatedAt = user.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation2.fulfill()
                                return
                        }
                        XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                        XCTAssertEqual(User.current?.customKey, user.customKey)

                        //Should be updated in memory
                        guard let updatedCurrentDate = User.current?.updatedAt else {
                            XCTFail("Should unwrap current date")
                            expectation2.fulfill()
                            return
                        }
                        XCTAssertEqual(updatedCurrentDate, originalUpdatedAt)

                        #if !os(Linux) && !os(Android) && !os(Windows)
                        //Should be updated in Keychain
                        guard let keychainUser: CurrentUserContainer<BaseParseUser>
                            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                            let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
                                XCTFail("Should get object from Keychain")
                                expectation2.fulfill()
                            return
                        }
                        XCTAssertEqual(keychainUpdatedCurrentDate, originalUpdatedAt)
                        #endif
                    case .failure(let error):
                        XCTFail("Should have fetched: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testDeleteAllCurrent() {
        testLogin()
        MockURLProtocol.removeAll()

        guard let user = User.current else {
            XCTFail("Should unwrap dates")
            return
        }

        let userOnServer = [BatchResponseItem<NoBody>(success: NoBody(), error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let deleted = try [user].deleteAll()
            deleted.forEach {
                if case let .failure(error) = $0 {
                    XCTFail("Should have deleted: \(error.localizedDescription)")
                }
                XCTAssertNil(User.current)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let deleted = try [user].deleteAll(transaction: true)
            deleted.forEach {
                if case let .failure(error) = $0 {
                    XCTFail("Should have deleted: \(error.localizedDescription)")
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDeleteAllAsyncMainQueueCurrent() {
        testLogin()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Delete user1")
        let expectation2 = XCTestExpectation(description: "Delete user2")

        guard let user = User.current else {
            XCTFail("Should unwrap")
            expectation1.fulfill()
            expectation2.fulfill()
            return
        }

        let userOnServer = [BatchResponseItem<NoBody>(success: NoBody(), error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            expectation2.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        [user].deleteAll { results in
            switch results {

            case .success(let deleted):
                deleted.forEach {
                    if case let .failure(error) = $0 {
                        XCTFail("Should have deleted: \(error.localizedDescription)")
                    }
                    XCTAssertNil(User.current)
                }
            case .failure(let error):
                XCTFail("Should have deleted: \(error.localizedDescription)")
            }
            expectation1.fulfill()
        }

        [user].deleteAll(transaction: true) { results in
            switch results {

            case .success(let deleted):
                deleted.forEach {
                    if case let .failure(error) = $0 {
                        XCTFail("Should have deleted: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Should have deleted: \(error.localizedDescription)")
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testMeCommand() {
        var user = User()
        user.objectId = "me"
        do {
            let command = try user.meCommand(sessionToken: "yolo")
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/users/me")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }
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
            let become = try user.become(sessionToken: "newValue")
            XCTAssert(become.hasSameObjectId(as: userOnServer))
            guard let becomeUpdatedAt = become.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalUpdatedAt = user.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertGreaterThan(becomeUpdatedAt, originalUpdatedAt)
            XCTAssertNil(become.ACL)

            //Should be updated in memory
            XCTAssertEqual(User.current?.updatedAt, becomeUpdatedAt)

            //Should be updated in Keychain
            #if !os(Linux) && !os(Android) && !os(Windows)
            guard let keychainUser: CurrentUserContainer<BaseParseUser>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainUser.currentUser?.updatedAt, becomeUpdatedAt)
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
        user.become(sessionToken: "newValue") { result in

            switch result {
            case .success(let become):
                XCTAssert(become.hasSameObjectId(as: userOnServer))
                guard let becomeUpdatedAt = become.updatedAt else {
                        XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                        return
                }
                guard let originalUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                        return
                }
                XCTAssertGreaterThan(becomeUpdatedAt, originalUpdatedAt)
                XCTAssertNil(become.ACL)

                //Should be updated in memory
                XCTAssertEqual(User.current?.updatedAt, becomeUpdatedAt)

                #if !os(Linux) && !os(Android) && !os(Windows)
                //Should be updated in Keychain
                guard let keychainUser: CurrentUserContainer<BaseParseUser>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                        XCTFail("Should get object from Keychain")
                    expectation1.fulfill()
                    return
                }
                XCTAssertEqual(keychainUser.currentUser?.updatedAt, becomeUpdatedAt)
                #endif
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
// swiftlint:disable:this file_length
