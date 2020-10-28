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
    var ACL: ParseACL?

    //: These are required for ParseUser
    var username: String?
    var email: String?
    var password: String?

    //: Your custom keys
    var customKey: String?
}

/*: Save your first customKey value to your ParseUser
    Asynchrounously - Performs work on background
    queue and returns to designated on designated callbackQueue.
    If no callbackQueue is specified it returns to main queue.
*/
User.current?.customKey = "myCustom"
User.current?.save { results in

    switch results {
    case .success(let updatedUser):
        print("Succesufully save myCustomKey to ParseServer: \(updatedUser)")
    case .failure(let error):
        assertionFailure("Failed to update user: \(error)")
    }
}

//: Logging out - synchronously
do {
    try User.logout()
    print("Succesfully logged out")
} catch let error {
    assertionFailure("Error logging out: \(error)")
}

/*: Login - asynchronously - Performs work on background
    queue and returns to designated on designated callbackQueue.
    If no callbackQueue is specified it returns to main queue
*/
User.login(username: "hello", password: "world") { results in

    switch results {
    case .success(let user):

        guard let currentUser = User.current else {
            assertionFailure("Error: current user currently not stored locally")
            return
        }
        assert(currentUser.hasSameObjectId(as: user))

    case .failure(let error):
        assertionFailure("Error logging in \(error)")
    }
}

//: Logging out - synchronously
do {
    try User.logout()
    print("Succesfully logged out")
} catch let error {
    assertionFailure("Error logging out: \(error)")
}

//: Another way to sign up
var newUser = User()
newUser.username = "hello10"
newUser.password = "world"

newUser.signup { result in
    switch result {

    case .success(let user):
        print("Parse signup successful \(user)")

    case .failure(let error):
        assertionFailure("Error logging in \(error)")
    }
}

PlaygroundPage.current.finishExecution()

//: [Next](@next)
