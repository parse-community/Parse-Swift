//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
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

//Save your first customKey value to your ParseUser
User.current?.customKey = "myCustom"
User.current?.save { results in

    switch results {
    case .success(let updatedUser):
        print("Succesufully save myCustomKey to ParseServer: \(updatedUser)")
    case .failure(let error):
        print("Failed to update user: \(error)")
    }
}

//Logging out
do {
    try User.logout()
    print("Succesfully logged out")
} catch let error {
    print("Error logging out: \(error)")
}


User.login(username: "hello", password: "world") { results in

    switch results {
    case .success(let user):

        guard let currentUser = User.current else {
            print("Error: current user currently not stored locally")
            return
        }

        if !currentUser.hasSameObjectId(as: user) {
            print("Error: these two objects should match")
        } else {
            print("Succesfully logged in")
        }

    case .failure(let error):
        print("Error logging in \(error)")
    }
}

//: [Next](@next)
