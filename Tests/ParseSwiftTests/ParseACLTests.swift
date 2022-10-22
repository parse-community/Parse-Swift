//
//  ParseACLTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 8/22/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseACLTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              primaryKey: "primaryKey",
                              serverURL: url, testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
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

    struct Role<RoleUser: ParseUser>: ParseRole {

        // required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // provided by Role
        var name: String?
    }

    func testCantSetDefaultACLWhenNotLoggedIn() throws {
        XCTAssertThrowsError(try ParseACL.defaultACL())
    }

    func testPublicAccess() {
        var acl = ParseACL()
        XCTAssertFalse(acl.publicRead)
        XCTAssertFalse(acl.publicWrite)

        acl.publicRead = true
        XCTAssertTrue(acl.publicRead)

        acl.publicWrite = true
        XCTAssertTrue(acl.publicWrite)
    }

    func testReadAccess() {
        var acl = ParseACL()
        XCTAssertFalse(acl.getReadAccess(objectId: "someUserID"))
        XCTAssertFalse(acl.getReadAccess(roleName: "someRoleName"))

        acl.setReadAccess(objectId: "someUserID", value: true)
        XCTAssertTrue(acl.getReadAccess(objectId: "someUserID"))

        acl.setReadAccess(roleName: "someRoleName", value: true)
        XCTAssertTrue(acl.getReadAccess(roleName: "someRoleName"))

        acl.publicWrite = true
        XCTAssertTrue(acl.publicWrite)
    }

    func testReadAccessObject() throws {
        let user = User(objectId: "someUserID")
        let role = try Role<User>(name: "someRoleName")
        var acl = ParseACL()
        XCTAssertFalse(acl.getReadAccess(user: user))
        XCTAssertFalse(acl.getReadAccess(role: role))

        acl.setReadAccess(user: user, value: true)
        XCTAssertTrue(acl.getReadAccess(user: user))

        acl.setReadAccess(role: role, value: true)
        XCTAssertTrue(acl.getReadAccess(role: role))

        let user2 = User()
        acl.setReadAccess(user: user2, value: true)
        XCTAssertFalse(acl.getReadAccess(user: user2))

        acl.publicWrite = true
        XCTAssertTrue(acl.publicWrite)
    }

    func testWriteAccess() {
        var acl = ParseACL()
        XCTAssertFalse(acl.getWriteAccess(objectId: "someUserID"))
        XCTAssertFalse(acl.getWriteAccess(roleName: "someRoleName"))

        acl.setWriteAccess(objectId: "someUserID", value: true)
        XCTAssertTrue(acl.getWriteAccess(objectId: "someUserID"))

        acl.setWriteAccess(roleName: "someRoleName", value: true)
        XCTAssertTrue(acl.getWriteAccess(roleName: "someRoleName"))

        acl.publicWrite = true
        XCTAssertTrue(acl.publicWrite)
    }

    func testWriteAccessObject() throws {
        let user = User(objectId: "someUserID")
        let role = try Role<User>(name: "someRoleName")
        var acl = ParseACL()
        XCTAssertFalse(acl.getWriteAccess(user: user))
        XCTAssertFalse(acl.getWriteAccess(role: role))

        acl.setWriteAccess(user: user, value: true)
        XCTAssertTrue(acl.getWriteAccess(user: user))

        acl.setWriteAccess(role: role, value: true)
        XCTAssertTrue(acl.getWriteAccess(role: role))

        let user2 = User()
        acl.setWriteAccess(user: user2, value: true)
        XCTAssertFalse(acl.getWriteAccess(user: user2))

        acl.publicWrite = true
        XCTAssertTrue(acl.publicWrite)
    }

    func testCoding() {
        var acl = ParseACL()
        acl.setReadAccess(objectId: "a", value: false)
        acl.setReadAccess(objectId: "b", value: true)
        acl.setWriteAccess(objectId: "c", value: false)
        acl.setWriteAccess(objectId: "d", value: true)

        var encoded: Data?
        do {
            encoded = try ParseCoding.jsonEncoder().encode(acl)
        } catch {
            XCTFail(error.localizedDescription)
        }

        if let dataToDecode = encoded {
            do {
                let decoded = try ParseCoding.jsonDecoder().decode(ParseACL.self, from: dataToDecode)
                XCTAssertEqual(acl.getReadAccess(objectId: "a"), decoded.getReadAccess(objectId: "a"))
                XCTAssertEqual(acl.getReadAccess(objectId: "b"), decoded.getReadAccess(objectId: "b"))
                XCTAssertEqual(acl.getWriteAccess(objectId: "c"), decoded.getWriteAccess(objectId: "c"))
                XCTAssertEqual(acl.getWriteAccess(objectId: "d"), decoded.getWriteAccess(objectId: "d"))
            } catch {
                XCTFail(error.localizedDescription)
            }
        } else {
            XCTAssertNil(encoded)
        }
    }

    func testCodingAccess() throws {
        let access = ParseACL.Access.read
        let encoded = try ParseCoding.jsonEncoder().encode(access)
        let decoded = try ParseCoding.jsonDecoder().decode(ParseACL.Access.self, from: encoded)
        XCTAssertEqual(access, decoded)
        let access2 = ParseACL.Access.write
        let encoded2 = try ParseCoding.jsonEncoder().encode(access2)
        let decoded2 = try ParseCoding.jsonDecoder().decode(ParseACL.Access.self, from: encoded2)
        XCTAssertEqual(access2, decoded2)
        guard let data = "hello".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertThrowsError(try ParseCoding.jsonDecoder().decode(ParseACL.Access.self, from: data))
    }

    func testDebugString() {
        var acl = ParseACL()
        acl.setReadAccess(objectId: "a", value: false)
        acl.setReadAccess(objectId: "b", value: true)
        acl.setWriteAccess(objectId: "c", value: false)
        acl.setWriteAccess(objectId: "d", value: true)

        XCTAssertTrue(acl.debugDescription.contains("\"b\":{\"read\":true}"))
        XCTAssertTrue(acl.debugDescription.contains("\"d\":{\"write\":true}"))
        XCTAssertTrue(acl.description.contains("\"b\":{\"read\":true}"))
        XCTAssertTrue(acl.description.contains("\"d\":{\"write\":true}"))
    }

    func testDefaultACLNoUser() {
        var newACL = ParseACL()
        let userId = "someUserID"
        newACL.setReadAccess(objectId: userId, value: true)
        do {
            var defaultACL = try ParseACL.defaultACL()
            XCTAssertNotEqual(newACL, defaultACL)
            defaultACL = try ParseACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)
            if defaultACL.getReadAccess(objectId: userId) {
                XCTFail("Should not have set read access because there is no current user")
            }
        } catch {
            return
        }

        do {
            _ = try ParseACL.setDefaultACL(newACL, withAccessForCurrentUser: true)
            let defaultACL = try ParseACL.defaultACL()
            if !defaultACL.getReadAccess(objectId: userId) {
                XCTFail("Should have set defaultACL with read access even though there is no current user")
            }
        } catch {
            return
        }
    }

    func testNoDefaultACL() {
        XCTAssertThrowsError(try ParseACL.defaultACL())
    }

    func testDefaultACL() {
        let loginResponse = LoginSignupResponse()
        let loginUserName = "hello10"
        let loginPassword = "world"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        do {
            _ = try User.signup(username: loginUserName, password: loginPassword)
        } catch {
            XCTFail("Could not signUp user: \(error)")
        }

        guard let userObjectId = User.current?.objectId else {
            XCTFail("Could not get objectId of currentUser")
            return
        }

        var newACL = ParseACL()
        newACL.publicRead = true
        newACL.publicWrite = true
        do {
            _ = try ParseACL.setDefaultACL(newACL, withAccessForCurrentUser: true)
            let defaultACL = try ParseACL.defaultACL()
            XCTAssertEqual(newACL.publicRead, defaultACL.publicRead)
            XCTAssertEqual(newACL.publicWrite, defaultACL.publicWrite)
            XCTAssertTrue(defaultACL.getReadAccess(objectId: userObjectId))
            XCTAssertTrue(defaultACL.getWriteAccess(objectId: userObjectId))
            try User.logout()
            XCTAssertThrowsError(try ParseACL.defaultACL())
        } catch {
            XCTFail("Should have set new ACL. Error \(error)")
        }
    }

    func testDefaultACLDontUseCurrentUser() {
        let loginResponse = LoginSignupResponse()
        let loginUserName = "hello10"
        let loginPassword = "world"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            _ = try User.signup(username: loginUserName, password: loginPassword)
        } catch {
            XCTFail("Could not signUp user: \(error.localizedDescription)")
        }

        guard let userObjectId = User.current?.objectId else {
            XCTFail("Could not get objectId of currentUser")
            return
        }

        var newACL = ParseACL()
        newACL.setReadAccess(objectId: "someUserID", value: true)
        do {
            _ = try ParseACL.setDefaultACL(newACL, withAccessForCurrentUser: false)
            let defaultACL = try ParseACL.defaultACL()
            XCTAssertTrue(defaultACL.getReadAccess(objectId: "someUserID"))
            XCTAssertFalse(defaultACL.getReadAccess(objectId: userObjectId))
            XCTAssertFalse(defaultACL.getWriteAccess(objectId: userObjectId))
        } catch {
            XCTFail("Should have set new ACL. Error \(error.localizedDescription)")
        }
    }
}

extension ParseACLTests.User {
    init(objectId: String) {
        self.objectId = objectId
    }
}
