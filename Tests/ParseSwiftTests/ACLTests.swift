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
        _ = KeychainStore.shared.removeAllObjects()
    }

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

    func testPublicAccess() {
        var acl = ACL()
        XCTAssertFalse(acl.publicRead)
        XCTAssertFalse(acl.publicWrite)

        acl.publicRead = true
        XCTAssertTrue(acl.publicRead)

        acl.publicWrite = true
        XCTAssertTrue(acl.publicWrite)
    }

    func testReadAccess() {
        var acl = ACL()
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
        var acl = ACL()
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
        var acl = ACL()
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
                let decoded = try JSONDecoder().decode(ACL.self, from: dataToDecode)
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
        var newACL = ACL()
        newACL.setReadAccess(userId: "someUserID", value: true)
        do {
            _ = try ACL.defaultACL()
            XCTFail("Should have thrown error because no user has been")
        } catch {
            return
        }

        do {
            _ = try ACL.setDefaultACL(newACL, withAccessForCurrentUser: true)
            XCTFail("Should have thrown error because no user has been")
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
        var newACL = ACL()
        newACL.setReadAccess(userId: "someUserID", value: true)
        do {
            var publicACL = try ACL.defaultACL()
            XCTAssertNotEqual(newACL, publicACL)
            try ACL.setDefaultACL(newACL, withAccessForCurrentUser: true)
            publicACL = try ACL.defaultACL()
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
        var newACL = ACL()
        newACL.setReadAccess(userId: "someUserID", value: true)
        do {
            try ACL.setDefaultACL(newACL, withAccessForCurrentUser: true)
            guard var aclController: DefaultACLController =
                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.defaultACL) else {
                    XCTFail("Should have found new ACLController.")
                return
            }

            aclController.useCurrentUser = false
            try KeychainStore.shared.set(aclController, for: ParseStorage.Keys.defaultACL)
            let publicACL = try ACL.defaultACL()
            XCTAssertEqual(newACL, publicACL)
        } catch {
            XCTFail("Should have set new ACL. Error \(error.localizedDescription)")
        }
    }
}
