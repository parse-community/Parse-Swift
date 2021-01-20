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
        try KeychainStore.shared.deleteAll()
        try ParseStorage.shared.deleteAll()
    }

    func testName() throws {
        XCTAssertNoThrow(try Role<User>(name: "Hello9_- "))
        XCTAssertThrowsError(try Role<User>(name: "Hello9!"))
        XCTAssertNoThrow(try Role<User>(name: "Hello9_- ", acl: ParseACL()))
        XCTAssertThrowsError(try Role<User>(name: "Hello9!", acl: ParseACL()))
    }
/*
    func testSave() throws {
        let currentUser = User.current
        //: The Role needs an ACL.
        var acl = ParseACL()
        /*acl.setReadAccess(user: currentUser, value: true)
        acl.setWriteAccess(user: currentUser, value: true)
        */

        var adminRole = try Role<User>(name: "Administrator", acl: acl)

        var user = User()
        user.objectId = "heel"
        try adminRole.users.add([user])
        adminRole.save { result in
            switch result {
            case .success(let savedRole):
                print("The role saved successfully: \(savedRole)")
                print("Check your \"Role\" class in Parse Dashboard.")
            case .failure(let error):
                print("Error savin role: \(error)")
            }
        }
    }*/
}
