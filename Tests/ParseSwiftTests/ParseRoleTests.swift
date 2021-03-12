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
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: Int
        var members = [String]()
        var levels: [String]?

        //custom initializers
        init(score: Int) {
            self.score = score
        }
    }

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

    struct Role<RoleUser: ParseUser>: ParseRole {

        // required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        // provided by Role
        var name: String

        init() {
            self.name = "roleMe"
        }
    }

    struct Level: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var level: Int
        var members = [String]()

        //custom initializers
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
                              masterKey: "masterKey",
                              serverURL: url,
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testName() throws {
        XCTAssertNoThrow(try Role<User>(name: "Hello9_- "))
        XCTAssertThrowsError(try Role<User>(name: "Hello9!"))
        XCTAssertNoThrow(try Role<User>(name: "Hello9_- ", acl: ParseACL()))
        XCTAssertThrowsError(try Role<User>(name: "Hello9!", acl: ParseACL()))
    }

    func testEndPoint() throws {
        var role = try Role<User>(name: "Administrator")
        role.objectId = "me"
        //This endpoint is at the ParseRole level
        XCTAssertEqual(role.endpoint.urlComponent, "/roles/me")
    }

    func testUserAddIncorrectClassKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        let role = try Role<User>(name: "Administrator", acl: acl)
        let userRoles = role.users

        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try userRoles.add("users", objects: [level]))
    }

    func testUserAddIncorrectKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        let role = try Role<User>(name: "Administrator", acl: acl)
        let userRoles = role.users

        var user = User()
        user.objectId = "heel"
        XCTAssertThrowsError(try userRoles.add("level", objects: [user]))
    }

    #if !os(Linux) && !os(Android)
    func testUserAddOperation() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        let role = try Role<User>(name: "Administrator", acl: acl)
        let userRoles = role.users
        let expected = "{\"className\":\"_User\",\"__type\":\"Relation\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(userRoles)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
        XCTAssertEqual(userRoles.key, "users")

        var user = User()
        user.objectId = "heel"
        let operation = try userRoles.add([user])

        // swiftlint:disable:next line_length
        let expected2 = "{\"users\":{\"objects\":[{\"__type\":\"Pointer\",\"className\":\"_User\",\"objectId\":\"heel\"}],\"__op\":\"AddRelation\"}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(operation)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
    }
    #endif

    func testUserRemoveIncorrectClassKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        let role = try Role<User>(name: "Administrator", acl: acl)
        let userRoles = role.users

        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try userRoles.remove("users", objects: [level]))
    }

    func testUserRemoveIncorrectKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        let role = try Role<User>(name: "Administrator", acl: acl)
        let userRoles = role.users

        var user = User()
        user.objectId = "heel"
        XCTAssertThrowsError(try userRoles.remove("level", objects: [user]))
    }

    #if !os(Linux) && !os(Android)
    func testUserRemoveOperation() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        let role = try Role<User>(name: "Administrator", acl: acl)
        let userRoles = role.users
        let expected = "{\"className\":\"_User\",\"__type\":\"Relation\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(userRoles)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
        XCTAssertEqual(userRoles.key, "users")

        var user = User()
        user.objectId = "heel"
        let operation = try userRoles.remove([user])

        // swiftlint:disable:next line_length
        let expected2 = "{\"users\":{\"objects\":[{\"__type\":\"Pointer\",\"className\":\"_User\",\"objectId\":\"heel\"}],\"__op\":\"RemoveRelation\"}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(operation)
        let decoded2 = try XCTUnwrap(try XCTUnwrap(String(data: encoded2, encoding: .utf8)))
        XCTAssertEqual(decoded2, expected2)
    }
    #endif

    func testRoleAddIncorrectClassKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        let role = try Role<User>(name: "Administrator", acl: acl)
        let roles = role.roles

        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try roles.add("roles", objects: [level]))
    }

    #if !os(Linux) && !os(Android)
    func testRoleAddIncorrectKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        let role = try Role<User>(name: "Administrator", acl: acl)
        let roles = role.roles

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        XCTAssertThrowsError(try roles.add("level", objects: [newRole]))
    }

    func testRoleAddOperation() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        let role = try Role<User>(name: "Administrator", acl: acl)
        let roles = role.roles
        let expected = "{\"className\":\"_Role\",\"__type\":\"Relation\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(roles)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
        XCTAssertEqual(roles.key, "roles")

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        let operation = try roles.add([newRole])

        // swiftlint:disable:next line_length
        let expected2 = "{\"roles\":{\"objects\":[{\"__type\":\"Pointer\",\"className\":\"_Role\",\"objectId\":\"heel\"}],\"__op\":\"AddRelation\"}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(operation)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
    }
    #endif

    func testRoleRemoveIncorrectClassKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        let role = try Role<User>(name: "Administrator", acl: acl)
        let roles = role.roles

        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try roles.remove("users", objects: [level]))
    }

    func testRoleRemoveIncorrectKeyError() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        let role = try Role<User>(name: "Administrator", acl: acl)
        let roles = role.roles

        var user = User()
        user.objectId = "heel"
        XCTAssertThrowsError(try roles.remove("level", objects: [user]))
    }

    #if !os(Linux) && !os(Android)
    func testRoleRemoveOperation() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        let role = try Role<User>(name: "Administrator", acl: acl)
        let roles = role.roles
        let expected = "{\"className\":\"_Role\",\"__type\":\"Relation\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(roles)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
        XCTAssertEqual(roles.key, "roles")

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        let operation = try roles.remove([newRole])

        // swiftlint:disable:next line_length
        let expected2 = "{\"roles\":{\"objects\":[{\"__type\":\"Pointer\",\"className\":\"_Role\",\"objectId\":\"heel\"}],\"__op\":\"RemoveRelation\"}}"
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
        userRoles.objectId = "yolo"
        let query = try userRoles.queryUsers(user)

        // swiftlint:disable:next line_length
        let expected = "{\"limit\":100,\"skip\":0,\"_method\":\"GET\",\"where\":{\"$relatedTo\":{\"key\":\"users\",\"object\":{\"__type\":\"Pointer\",\"className\":\"_Role\",\"objectId\":\"yolo\"}}}}"
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRoleQuery() throws {
        var acl = ParseACL()
        acl.publicWrite = false
        acl.publicRead = true

        var role = try Role<User>(name: "Administrator", acl: acl)
        role.objectId = "yolo"

        var newRole = try Role<User>(name: "Moderator", acl: acl)
        newRole.objectId = "heel"
        guard let query = role.queryRoles else {
            XCTFail("Should unwrap, if it doesn't it an error occurred when creating query.")
            return
        }

        // swiftlint:disable:next line_length
        let expected2 = "{\"limit\":100,\"skip\":0,\"_method\":\"GET\",\"where\":{\"$relatedTo\":{\"key\":\"roles\",\"object\":{\"__type\":\"Pointer\",\"className\":\"_Role\",\"objectId\":\"yolo\"}}}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(query)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
    }
    #endif
}
