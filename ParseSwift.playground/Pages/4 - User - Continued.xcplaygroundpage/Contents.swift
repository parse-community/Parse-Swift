//: [Previous](@previous)

//: For this page, make sure your build target is set to ParseSwift (macOS) and targeting
//: `My Mac` or whatever the name of your mac is. Also be sure your `Playground Settings`
//: in the `File Inspector` is `Platform = macOS`. This is because
//: Keychain in iOS Playgrounds behaves differently. Every page in Playgrounds should
//: be set to build for `macOS` unless specified.

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
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?

    //: Your custom keys.
    var customKey: String?
    var score: GameScore?
    var targetScore: GameScore?
    var allScores: [GameScore]?

    //: Custom init for signup.
    init(username: String, password: String, email: String) {
        self.username = username
        self.password = password
        self.email = email
    }
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

//: Logging out - synchronously
do {
    try User.logout()
    print("Successfully logged out")
} catch let error {
    print("Error logging out: \(error)")
}

/*: Login - asynchronously - Performs work on background
    queue and returns to specified callbackQueue.
    If no callbackQueue is specified it returns to main queue.
*/
User.login(username: "hello", password: "world") { result in

    switch result {
    case .success(let user):

        guard let currentUser = User.current else {
            assertionFailure("Error: current user not stored locally")
            return
        }
        assert(currentUser.hasSameObjectId(as: user))
        print("Successfully logged in as user: \(user)")

    case .failure(let error):
        print("Error logging in: \(error)")
    }
}

/*: Save your first `customKey` value to your `ParseUser`
    Asynchrounously - Performs work on background
    queue and returns to specified callbackQueue.
    If no callbackQueue is specified it returns to main queue.
*/
User.current?.customKey = "myCustom"
User.current?.score = GameScore(score: 12)
User.current?.targetScore = GameScore(score: 100)
User.current?.allScores = [GameScore(score: 5), GameScore(score: 8)]
User.current?.save { result in

    switch result {
    case .success(let updatedUser):
        print("Successfully save custom fields of User to ParseServer: \(updatedUser)")
    case .failure(let error):
        print("Failed to update user: \(error)")
    }
}

//: Looking at the output of user from the previous login, it only has
//: a pointer to the `score` and `targetScore` fields. You can
//: fetch using `include` to get the score.
User.current?.fetch(includeKeys: ["score"]) { result in
    switch result {
    case .success:
        print("Successfully fetched user with score key: \(String(describing: User.current))")
    case .failure(let error):
        print("Error fetching score: \(error)")
    }
}

//: The `target` score is still missing. You can get all pointer fields at
//: once by including `["*"]`.
User.current?.fetch(includeKeys: ["*"]) { result in
    switch result {
    case .success:
        print("Successfully fetched user with all keys: \(String(describing: User.current))")
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

//: To add additional information when signing up a user,
//: you should create an instance of your user first.
var newUser = User(username: "parse", password: "aPassword*", email: "parse@parse.com")
//: Add any other additional information.
newUser.targetScore = .init(score: 40)
newUser.signup { result in

    switch result {
    case .success(let user):

        guard let currentUser = User.current else {
            assertionFailure("Error: current user not stored locally")
            return
        }
        assert(currentUser.hasSameObjectId(as: user))
        print("Successfully signed up as user: \(user)")

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

//: Verification Email - synchronously.
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

//: Logging in anonymously.
User.anonymous.login { result in
    switch result {
    case .success:
        print("Successfully logged in \(String(describing: User.current))")
        print("Session token: \(String(describing: User.current?.sessionToken))")
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
        print("Session token: \(String(describing: User.current?.sessionToken))")
    case .failure(let error):
        print("Error logging in: \(error)")
    }
}

PlaygroundPage.current.finishExecution()

//: [Next](@next)
