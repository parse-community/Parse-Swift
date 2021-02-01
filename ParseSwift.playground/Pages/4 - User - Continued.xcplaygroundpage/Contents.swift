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
    var score: GameScore?
    var targetScore: GameScore?
}

//: Create your own value typed `ParseObject`.
struct GameScore: ParseObject {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties.
    var score: Int? = 0

    //: Custom initializer.
    init(score: Int) {
        self.score = score
    }

    init(objectId: String?) {
        self.objectId = objectId
    }
}

/*: Save your first customKey value to your `ParseUser`
    Asynchrounously - Performs work on background
    queue and returns to designated on designated callbackQueue.
    If no callbackQueue is specified it returns to main queue.
*/
User.current?.customKey = "myCustom"
User.current?.score = GameScore(score: 12)
User.current?.targetScore = GameScore(score: 100)
User.current?.save { results in

    switch results {
    case .success(let updatedUser):
        print("Successfully save myCustomKey and score to ParseServer: \(updatedUser)")
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

//: Looking at the output of user from the previous login, it only has
//: a pointer to the `score`and `targetScore` fields. You can fetch using `include` to
//: get the score.
User.current?.fetch(includeKeys: ["score"]) { result in
    switch result {
    case .success:
        print("Successfully fetched user with score key: \(User.current)")
    case .failure(let error):
        print("Error fetching score: \(error)")
    }
}

//: The `target` score is still missing. You can get all pointer fields at
//: once by including `["*"]`.
User.current?.fetch(includeKeys: ["*"]) { result in
    switch result {
    case .success:
        print("Successfully fetched user with all keys: \(User.current)")
    case .failure(let error):
        print("Error fetching score: \(error)")
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
