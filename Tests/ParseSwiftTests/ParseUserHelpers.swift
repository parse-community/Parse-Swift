//
//  File.swift
//  ParseSwift
//
//  Created by Pierre-Michel Villa on 2022/01/24.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation
@testable import ParseSwift

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
    var sessionToken: String?
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
