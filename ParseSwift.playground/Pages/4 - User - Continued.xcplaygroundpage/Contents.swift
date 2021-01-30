//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

struct User: ParseUser {
    //: These are required for `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: These are required for `ParseUser`.
    var username: String?
    var email: String?
    var password: String?
    var authData: [String: [String: String]?]?

    //: Your custom keys.
    var customKey: String?
}

/*: Save your first customKey value to your `ParseUser`
    Asynchrounously - Performs work on background
    queue and returns to designated on designated callbackQueue.
    If no callbackQueue is specified it returns to main queue.
*/
User.current?.customKey = "myCustom"
User.current?.save { results in

    switch results {
    case .success(let updatedUser):
        print("Successfully save myCustomKey to ParseServer: \(updatedUser)")
    case .failure(let error):
        print("Failed to update user: \(error)")
    }
}

//: Logging out - synchronously
do {
    try User.logout()
    print("Successfully logged out")
} catch let error {
    print("Error logging out: \(error)")
}

/*: Login - asynchronously - Performs work on background
    queue and returns to designated on designated callbackQueue.
    If no callbackQueue is specified it returns to main queue.
*/
User.login(username: "hello", password: "world") { results in

    switch results {
    case .success(let user):

        guard let currentUser = User.current else {
            assertionFailure("Error: current user currently not stored locally")
            return
        }
        assert(currentUser.hasSameObjectId(as: user))
        print("Successfully logged in as user: \(user)")

    case .failure(let error):
        print("Error logging in: \(error)")
    }
}

//: Logging out - synchronously.
do {
    try User.logout()
    print("Successfully logged out")
} catch let error {
    print("Error logging out: \(error)")
}

//: Logging in anonymously.
User.anonymous.login { result in
    switch result {
    case .success:
        print("Successfully logged in \(String(describing: User.current))")
    case .failure(let error):
        print("Error logging in: \(error)")
    }
}

//: Convert the anonymous user to a real new user.
User.current?.username = "bye"
User.current?.password = "world"
User.current?.signup { result in
    switch result {

    case .success(let user):
        print("Parse signup successful: \(user)")

    case .failure(let error):
        print("Error logging in: \(error)")
    }
}

//: Logging out - synchronously.
do {
    try User.logout()
    print("Successfully logged out")
} catch let error {
    print("Error logging out: \(error)")
}

//: Password Reset Request - synchronously.
do {
    try User.verificationEmail(email: "hello@parse.org")
    print("Successfully requested verification email be sent")
} catch let error {
    print("Error requesting verification email be sent: \(error)")
}

//: Password Reset Request - synchronously.
do {
    try User.passwordReset(email: "hello@parse.org")
    print("Successfully requested password reset")
} catch let error {
    print("Error requesting password reset: \(error)")
}

PlaygroundPage.current.finishExecution()

//: [Next](@next)
