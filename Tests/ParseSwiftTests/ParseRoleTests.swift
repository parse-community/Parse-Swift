//
//  ParseRoleTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/18/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseRoleTests: XCTestCase {
    struct GameScore: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int
        var members = [String]()
        var levels: [String]?

        //custom initializers
        init() {
            self.points = 5
        }

        init(points: Int) {
            self.points = points
        }
    }

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
    }

    struct Role<RoleUser: ParseUser>: ParseRole {

        // required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // provided by Role
        var name: String?

        // custom
        var title: String?

        func merge(with object: Self) throws -> Self {
            var updated = try mergeParse(with: object)
            if updated.shouldRestoreKey(\.title,
                                         original: object) {
                updated.title = object.title
            }
            return updated
        }
    }

    struct Level: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var level: Int
        var members = [String]()

        //custom initializers
        init() {
            self.level = 5
        }

        init(level: Int) {
            self.level = level
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

    func testName() throws {
        let role1 = try Role<User>(name: "Hello9_- ")
        let role2 = try Role<User>(name: "Hello10_- ", acl: ParseACL())
        let roles = [role1: "hello",
                     role2: "world"]
        XCTAssertEqual(role1, role1)
        XCTAssertNotEqual(role1, role2)
        XCTAssertEqual(roles[role1], "hello")
        XCTAssertEqual(roles[role2], "world")
        XCTAssertThrowsError(try Role<User>(name: "Hello9!"))
        XCTAssertThrowsError(try Role<User>(name: "Hello10!", acl: ParseACL()))
    }

    func testEndPoint() throws {
        var role = try Role<User>(name: "Administrator")
        XCTAssertEqual(role.endpoint.urlComponent, "/roles")
        role.objectId = "me"
        XCTAssertEqual(role.endpoint.urlComponent, "/roles/me")
    }

    func testSaveUpdateCommandParseObjectMutable() throws {
        var role = try Role<User>(name: "Administrator")
        let className = role.className
        let objectId = "yarr"
        role.objectId = objectId
        role.createdAt = Date()
        role.updatedAt = role.createdAt

        let command = try role.mergeable.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)

        var empty = role.mergeable
        empty.title = "hello"
        let command2 = try empty.saveCommand()
        guard let body2 = command2.body else {
            XCTFail("Should be able to unwrap")
            return
        }
        let expected2 = "{\"title\":\"hello\"}"
        let encoded2 = try ParseCoding.parseEncoder()
            .encode(body2, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
    }

    func testUserAddIncorrectClassKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"
        guard let userRoles = role.users else {
            XCTFail("Should have unwrapped")
            return
        }

        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try userRoles.add("users", objects: [level]))
    }

    func testUserAddIncorrectKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"
        guard let userRoles = role.users else {
            XCTFail("Should have unwrapped")
            return
        }

        var user = User()
        user.objectId = "heel"
        XCTAssertThrowsError(try userRoles.add("level", objects: [user]))
    }

    func testUserAddOperation() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        XCTAssertNil(role.users) // Should not produce a relation without an objectId.
        role.objectId = "yolo"
        guard let userRoles = role.users else {
            XCTFail("Should have unwrapped")
            return
        }
        let expected = "{\"__type\":\"Relation\",\"className\":\"_User\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(userRoles)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
        XCTAssertEqual(userRoles.key, "users")

        var user = User()
        user.objectId = "heel"
        let operation = try userRoles.add([user])

        // swiftlint:disable:next line_length
        let expected2 = "{\"users\":{\"__op\":\"AddRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"_User\",\"objectId\":\"heel\"}]}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(operation)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
    }

    func testUserAddOperationNoKey() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"
        guard var userRoles = role.users else {
            XCTFail("Should have unwrapped")
            return
        }
        userRoles.key = nil
        let expected = "{\"__type\":\"Relation\",\"className\":\"_User\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(userRoles)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
        XCTAssertNil(userRoles.key)

        var user = User()
        user.objectId = "heel"
        let operation = try userRoles.add([user])

        // swiftlint:disable:next line_length
        let expected2 = "{\"users\":{\"__op\":\"AddRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"_User\",\"objectId\":\"heel\"}]}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(operation)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
    }

    func testUserRemoveIncorrectClassKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"
        guard let userRoles = role.users else {
            XCTFail("Should have unwrapped")
            return
        }

        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try userRoles.remove("users", objects: [level]))
    }

    func testUserRemoveIncorrectKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"
        guard let userRoles = role.users else {
            XCTFail("Should have unwrapped")
            return
        }

        var user = User()
        user.objectId = "heel"
        XCTAssertThrowsError(try userRoles.remove("level", objects: [user]))
    }

    func testUserRemoveOperation() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"
        guard let userRoles = role.users else {
            XCTFail("Should have unwrapped")
            return
        }
        let expected = "{\"__type\":\"Relation\",\"className\":\"_User\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(userRoles)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
        XCTAssertEqual(userRoles.key, "users")

        var user = User()
        user.objectId = "heel"
        let operation = try userRoles.remove([user])

        // swiftlint:disable:next line_length
        let expected2 = "{\"users\":{\"__op\":\"RemoveRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"_User\",\"objectId\":\"heel\"}]}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(operation)
        let decoded2 = try XCTUnwrap(try XCTUnwrap(String(data: encoded2, encoding: .utf8)))
        XCTAssertEqual(decoded2, expected2)
    }

    func testUserRemoveOperationNoKey() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"
        guard var userRoles = role.users else {
            XCTFail("Should have unwrapped")
            return
        }
        userRoles.key = nil
        let expected = "{\"__type\":\"Relation\",\"className\":\"_User\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(userRoles)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
        XCTAssertNil(userRoles.key)

        var user = User()
        user.objectId = "heel"
        let operation = try userRoles.remove([user])

        // swiftlint:disable:next line_length
        let expected2 = "{\"users\":{\"__op\":\"RemoveRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"_User\",\"objectId\":\"heel\"}]}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(operation)
        let decoded2 = try XCTUnwrap(try XCTUnwrap(String(data: encoded2, encoding: .utf8)))
        XCTAssertEqual(decoded2, expected2)
    }

    func testRoleAddIncorrectClassKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"
        guard let roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }

        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try roles.add("roles", objects: [level]))
    }

    func testRoleAddIncorrectKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"
        guard let roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        XCTAssertThrowsError(try roles.add("level", objects: [newRole]))
    }

    func testRoleAddOperation() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        XCTAssertNil(role.roles) // Should not produce a relation without an objectId.
        role.objectId = "yolo"
        guard let roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }
        let expected = "{\"__type\":\"Relation\",\"className\":\"_Role\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(roles)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
        XCTAssertEqual(roles.key, "roles")

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        let operation = try roles.add([newRole])

        // swiftlint:disable:next line_length
        let expected2 = "{\"roles\":{\"__op\":\"AddRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"_Role\",\"objectId\":\"heel\"}]}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(operation)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
    }

    func testRoleAddOperationSaveSynchronous() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.createdAt = Date()
        role.updatedAt = Date()
        XCTAssertNil(role.roles) // Should not produce a relation without an objectId.
        role.objectId = "yolo"
        guard let roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        let operation = try roles.add([newRole])

        var serverResponse = role
        serverResponse.createdAt = nil
        serverResponse.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
            //Get dates in correct format from ParseDecoding strategy
            serverResponse = try serverResponse.getDecoder().decode(Role<User>.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let updatedRole = try operation.save()
        XCTAssertEqual(updatedRole.updatedAt, serverResponse.updatedAt)
        XCTAssertTrue(updatedRole.hasSameObjectId(as: serverResponse))
    }

    func testRoleUpdateMergeSynchronous() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.createdAt = Date()
        role.updatedAt = Date()
        role.title = "hello"
        XCTAssertNil(role.roles) // Should not produce a relation without an objectId.
        role.objectId = "yolo"
        guard role.roles != nil else {
            XCTFail("Should have unwrapped")
            return
        }

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"

        var serverResponse = role
        serverResponse.createdAt = nil
        serverResponse.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
            //Get dates in correct format from ParseDecoding strategy
            serverResponse = try serverResponse.getDecoder().decode(Role<User>.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        var changedRole = role
            .set(\.title, to: "peace")
        let updatedRole = try changedRole.save()
        XCTAssertEqual(updatedRole.updatedAt, serverResponse.updatedAt)
        XCTAssertEqual(updatedRole.name, serverResponse.name)
        XCTAssertEqual(updatedRole.title, changedRole.title)
        XCTAssertTrue(updatedRole.hasSameObjectId(as: serverResponse))
    }

    func testRoleAddOperationSaveSynchronousError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.createdAt = Date()
        role.updatedAt = Date()
        XCTAssertNil(role.roles) // Should not produce a relation without an objectId.
        role.objectId = "yolo"
        guard let roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        var operation = try roles.add([newRole])
        operation.target.objectId = nil

        do {
            _ = try operation.save()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn([.missingObjectId]))
        }
    }

    func testRoleAddOperationSaveSynchronousCustomObjectId() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        Parse.configuration.isRequiringCustomObjectIds = true
        var role = try Role<User>(name: "Administrator", acl: acl)
        role.createdAt = Date()
        role.updatedAt = Date()
        XCTAssertNil(role.roles) // Should not produce a relation without an objectId.
        role.objectId = "yolo"
        guard let roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        let operation = try roles.add([newRole])

        var serverResponse = role
        serverResponse.createdAt = nil
        serverResponse.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
            //Get dates in correct format from ParseDecoding strategy
            serverResponse = try serverResponse.getDecoder().decode(Role<User>.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let updatedRole = try operation.save()
        XCTAssertEqual(updatedRole.updatedAt, serverResponse.updatedAt)
        XCTAssertTrue(updatedRole.hasSameObjectId(as: serverResponse))
    }

    func testRoleAddOperationSaveSynchronousCustomObjectIdError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        Parse.configuration.isRequiringCustomObjectIds = true
        var role = try Role<User>(name: "Administrator", acl: acl)
        role.createdAt = Date()
        role.updatedAt = Date()
        XCTAssertNil(role.roles) // Should not produce a relation without an objectId.
        role.objectId = "yolo"
        guard let roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        var operation = try roles.add([newRole])
        operation.target.objectId = nil

        do {
            _ = try operation.save()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn([.missingObjectId]))
        }
    }

    func testRoleAddOperationSaveAsynchronous() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.createdAt = Date()
        role.updatedAt = Date()
        XCTAssertNil(role.roles) // Should not produce a relation without an objectId.
        role.objectId = "yolo"
        guard let roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        let operation = try roles.add([newRole])

        var serverResponse = role
        serverResponse.createdAt = nil
        serverResponse.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
            //Get dates in correct format from ParseDecoding strategy
            serverResponse = try serverResponse.getDecoder().decode(Role<User>.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation1 = XCTestExpectation(description: "Save object1")
        operation.save { result in
            switch result {
            case .success(let updatedRole):
                XCTAssertEqual(updatedRole.updatedAt, serverResponse.updatedAt)
                XCTAssertTrue(updatedRole.hasSameObjectId(as: serverResponse))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testRoleAddOperationSaveAsynchronousError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        Parse.configuration.isRequiringCustomObjectIds = true
        var role = try Role<User>(name: "Administrator", acl: acl)
        role.createdAt = Date()
        role.updatedAt = Date()
        XCTAssertNil(role.roles) // Should not produce a relation without an objectId.
        role.objectId = "yolo"
        guard let roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        var operation = try roles.add([newRole])
        operation.target.objectId = nil

        let expectation1 = XCTestExpectation(description: "Save object1")
        operation.save { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                XCTAssertEqual(error.code, .missingObjectId)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testRoleAddOperationSaveAsynchronousCustomObjectId() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        Parse.configuration.isRequiringCustomObjectIds = true
        XCTAssertEqual(Parse.configuration.isAllowingCustomObjectIds,
                       Parse.configuration.isRequiringCustomObjectIds)
        var role = try Role<User>(name: "Administrator", acl: acl)
        role.createdAt = Date()
        role.updatedAt = Date()
        XCTAssertNil(role.roles) // Should not produce a relation without an objectId.
        role.objectId = "yolo"
        guard let roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        let operation = try roles.add([newRole])

        var serverResponse = role
        serverResponse.createdAt = nil
        serverResponse.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
            //Get dates in correct format from ParseDecoding strategy
            serverResponse = try serverResponse.getDecoder().decode(Role<User>.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation1 = XCTestExpectation(description: "Save object1")
        operation.save { result in
            switch result {
            case .success(let updatedRole):
                XCTAssertEqual(updatedRole.updatedAt, serverResponse.updatedAt)
                XCTAssertTrue(updatedRole.hasSameObjectId(as: serverResponse))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testRoleAddOperationSaveAsynchronousCustomObjectIdError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.createdAt = Date()
        role.updatedAt = Date()
        XCTAssertNil(role.roles) // Should not produce a relation without an objectId.
        role.objectId = "yolo"
        guard let roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        var operation = try roles.add([newRole])
        operation.target.objectId = nil

        let expectation1 = XCTestExpectation(description: "Save object1")
        operation.save { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                XCTAssertEqual(error.code, .missingObjectId)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testRoleAddOperationNoKey() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"
        guard var roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }
        roles.key = nil
        let expected = "{\"__type\":\"Relation\",\"className\":\"_Role\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(roles)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
        XCTAssertNil(roles.key)

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        let operation = try roles.add([newRole])

        // swiftlint:disable:next line_length
        let expected2 = "{\"roles\":{\"__op\":\"AddRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"_Role\",\"objectId\":\"heel\"}]}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(operation)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
    }

    func testRoleRemoveIncorrectClassKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"
        guard let roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }

        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try roles.remove("users", objects: [level]))
    }

    func testRoleRemoveIncorrectKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"
        guard let roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }

        var user = User()
        user.objectId = "heel"
        XCTAssertThrowsError(try roles.remove("level", objects: [user]))
    }

    func testRoleRemoveOperation() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"
        guard let roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }
        let expected = "{\"__type\":\"Relation\",\"className\":\"_Role\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(roles)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
        XCTAssertEqual(roles.key, "roles")

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        let operation = try roles.remove([newRole])

        // swiftlint:disable:next line_length
        let expected2 = "{\"roles\":{\"__op\":\"RemoveRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"_Role\",\"objectId\":\"heel\"}]}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(operation)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
    }

    func testRoleRemoveOperationNoKey() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"
        guard var roles = role.roles else {
            XCTFail("Should have unwrapped")
            return
        }
        roles.key = nil
        let expected = "{\"__type\":\"Relation\",\"className\":\"_Role\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(roles)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
        XCTAssertNil(roles.key)

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        let operation = try roles.remove([newRole])

        // swiftlint:disable:next line_length
        let expected2 = "{\"roles\":{\"__op\":\"RemoveRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"_Role\",\"objectId\":\"heel\"}]}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(operation)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
    }

    func testUserQuery() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var user = User()
        user.objectId = "heel"

        var userRoles = try Role<User>(name: "Administrator", acl: acl)
        XCTAssertThrowsError(try userRoles.queryUsers())
        userRoles.objectId = "yolo"
        let query = try userRoles.queryUsers()

        // swiftlint:disable:next line_length
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"$relatedTo\":{\"key\":\"users\",\"object\":{\"__type\":\"Pointer\",\"className\":\"_Role\",\"objectId\":\"yolo\"}}}}"
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRoleQuery() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        XCTAssertThrowsError(try role.queryRoles())
        role.objectId = "yolo"

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        let query: Query<Role> = try role.queryRoles()

        // swiftlint:disable:next line_length
        let expected2 = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"$relatedTo\":{\"key\":\"roles\",\"object\":{\"__type\":\"Pointer\",\"className\":\"_Role\",\"objectId\":\"yolo\"}}}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(query)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
    }
}
