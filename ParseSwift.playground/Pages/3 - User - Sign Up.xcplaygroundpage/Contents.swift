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
    var ACL: ParseACL?

    // These are required for ParseUser
    var username: String?
    var email: String?
    var password: String?

    //: Your custom keys
    var customKey: String?
}

/*: Sign up user asynchronously - Performs work on background
    queue and returns to designated on designated callbackQueue.
    If no callbackQueue is specified it returns to main queue
*/
User.signup(username: "hello", password: "world") { results in

    switch results {
    case .success(let user):

        guard let currentUser = User.current else {
            assertionFailure("Error: current user currently not stored locally")
            return
        }

        if !currentUser.hasSameObjectId(as: user) {
            assertionFailure("Error: these two objects should match")
        } else {
            print("Successfully signed up user \(user)")
        }

    case .failure(let error):
        assertionFailure("Error signing up \(error)")
    }
}

PlaygroundPage.current.finishExecution()

//: [Next](@next)
