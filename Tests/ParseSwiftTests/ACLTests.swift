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
    }

    override func tearDown() {
        super.tearDown()
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
}
