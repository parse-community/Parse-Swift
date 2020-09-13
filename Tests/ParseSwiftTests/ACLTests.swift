//
//  ACLTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 8/22/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ACLTests: XCTestCase {

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
        try? KeychainStore.shared.deleteAll()
        try? ParseStorage.shared.deleteAll()
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

        // Your custom keys
        var customKey: String?
    }

    struct LoginSignupResponse: ParseUser {
        var objectId: String?
        var createdAt: Date?
        var sessionToken: String
        var updatedAt: Date?
        var ACL: ParseACL?

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
        XCTAssertFalse(acl.getReadAccess(userId: "someUserID"))
        XCTAssertFalse(acl.getReadAccess(roleName: "someRoleName"))

        acl.setReadAccess(userId: "someUserID", value: true)
        XCTAssertTrue(acl.getReadAccess(userId: "someUserID"))

        acl.setReadAccess(roleName: "someRoleName", value: true)
        XCTAssertTrue(acl.getReadAccess(roleName: "someRoleName"))

        acl.publicWrite = true
        XCTAssertTrue(acl.publicWrite)
    }

    func testWriteAccess() {
        var acl = ParseACL()
        XCTAssertFalse(acl.getWriteAccess(userId: "someUserID"))
        XCTAssertFalse(acl.getWriteAccess(roleName: "someRoleName"))

        acl.setWriteAccess(userId: "someUserID", value: true)
        XCTAssertTrue(acl.getWriteAccess(userId: "someUserID"))

        acl.setWriteAccess(roleName: "someRoleName", value: true)
        XCTAssertTrue(acl.getWriteAccess(roleName: "someRoleName"))

        acl.publicWrite = true
        XCTAssertTrue(acl.publicWrite)
    }

    func testCoding() {
        var acl = ParseACL()
        acl.setReadAccess(userId: "a", value: false)
        acl.setReadAccess(userId: "b", value: true)
        acl.setWriteAccess(userId: "c", value: false)
        acl.setWriteAccess(userId: "d", value: true)

        var encoded: Data?
        do {
            encoded = try JSONEncoder().encode(acl)
        } catch {
            XCTFail(error.localizedDescription)
        }

        if let dataToDecode = encoded {
            do {
                let decoded = try JSONDecoder().decode(ParseACL.self, from: dataToDecode)
                XCTAssertEqual(acl.getReadAccess(userId: "a"), decoded.getReadAccess(userId: "a"))
                XCTAssertEqual(acl.getReadAccess(userId: "b"), decoded.getReadAccess(userId: "b"))
                XCTAssertEqual(acl.getWriteAccess(userId: "c"), decoded.getWriteAccess(userId: "c"))
                XCTAssertEqual(acl.getWriteAccess(userId: "d"), decoded.getWriteAccess(userId: "d"))
            } catch {
                XCTFail(error.localizedDescription)
            }
        } else {
            XCTAssertNil(encoded)
        }

    }

    func testDefaultACLNoUser() {
        var newACL = ParseACL()
        let userId = "someUserID"
        newACL.setReadAccess(userId: userId, value: true)
        do {
            let defaultACL = try ParseACL.defaultACL()
            XCTAssertNotEqual(newACL, defaultACL)
            try ParseACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)
            if defaultACL.getReadAccess(userId: userId) {
                XCTFail("Shouldn't have set read access because there's no current user")
            }
        } catch {
            return
        }

        do {
            try ParseACL.setDefaultACL(newACL, withAccessForCurrentUser: true)
            let defaultACL = try ParseACL.defaultACL()
            if !defaultACL.getReadAccess(userId: userId) {
                XCTFail("Should have set defaultACL with read access even though there's no current user")
            }
        } catch {
            return
        }
    }

    func testDefaultACL() {
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
            _ = try User.signup(username: "testUser", password: "password")
        } catch {
            XCTFail("Couldn't signUp user: \(error.localizedDescription)")
        }
        var newACL = ParseACL()
        newACL.setReadAccess(userId: "someUserID", value: true)
        do {
            var publicACL = try ParseACL.defaultACL()
            XCTAssertNotEqual(newACL, publicACL)
            try ParseACL.setDefaultACL(newACL, withAccessForCurrentUser: true)
            publicACL = try ParseACL.defaultACL()
            XCTAssertEqual(newACL, publicACL)
        } catch {
            XCTFail("Should have set new ACL. Error \(error.localizedDescription)")
        }
    }

    func testDefaultACLDontUseCurrentUser() {
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
            _ = try User.signup(username: "testUser", password: "password")
        } catch {
            XCTFail("Couldn't signUp user: \(error.localizedDescription)")
        }
        var newACL = ParseACL()
        newACL.setReadAccess(userId: "someUserID", value: true)
        do {
            try ParseACL.setDefaultACL(newACL, withAccessForCurrentUser: true)
            guard var aclController: DefaultACL =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.defaultACL) else {
                    XCTFail("Should have found new ACLController.")
                return
            }

            aclController.useCurrentUser = false
            try KeychainStore.shared.set(aclController, for: ParseStorage.Keys.defaultACL)
            let publicACL = try ParseACL.defaultACL()
            XCTAssertEqual(newACL, publicACL)
        } catch {
            XCTFail("Should have set new ACL. Error \(error.localizedDescription)")
        }
    }
}
