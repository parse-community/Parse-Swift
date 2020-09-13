//: [Previous](@previous)

import PlaygroundSupport
import Foundation
PlaygroundPage.current.needsIndefiniteExecution = true

import ParseSwift
initializeParse()

struct User: ParseUser {
    //: These are required for ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ACL?

    // These are required for ParseUser
    var username: String?
    var email: String?
    var password: String?

    // Your custom keys
    var customKey: String?
}

//Sign up user asynchronously
User.signup(username: "hello", password: "world") { results in

    switch results {
    case .success(let user):

        guard let currentUser = User.current else {
            print("Error: current user currently not stored locally")
            return
        }

        if !currentUser.hasSameObjectId(as: user) {
            print("Error: these two objects should match")
        } else {
            print("Succesfully signed up user")
        }

    case .failure(let error):
        print("Error signing up \(error)")
    }
}

//: [Next](@next)
