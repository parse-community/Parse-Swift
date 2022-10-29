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
    //: These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    //: These are required by `ParseUser`.
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?

    //: Your custom keys.
    var customKey: String?
    var gameScore: GameScore?
    var targetScore: GameScore?
    var allScores: [GameScore]?

    /*:
     Optional - implement your own version of merge
     for faster decoding after updating your `ParseObject`.
     */
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.customKey,
                                     original: object) {
            updated.customKey = object.customKey
        }
        if updated.shouldRestoreKey(\.gameScore,
                                     original: object) {
            updated.gameScore = object.gameScore
        }
        if updated.shouldRestoreKey(\.targetScore,
                                     original: object) {
            updated.targetScore = object.targetScore
        }
        if updated.shouldRestoreKey(\.allScores,
                                     original: object) {
            updated.allScores = object.allScores
        }
        return updated
    }
}

//: It's recommended to place custom initializers in an extension
//: to preserve the memberwise initializer.
extension User {
    //: Custom init for signup.
    init(username: String, password: String, email: String) {
        self.username = username
        self.password = password
        self.email = email
    }
}

//: Create your own value typed `ParseObject`.
struct GameScore: ParseObject {
    //: These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    //: Your own properties.
    var points: Int? = 0

    /*:
     Optional - implement your own version of merge
     for faster decoding after updating your `ParseObject`.
     */
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points,
                                         original: object) {
            updated.points = object.points
        }
        return updated
    }
}

//: It's recommended to place custom initializers in an extension
//: to preserve the memberwise initializer.
extension GameScore {
    //: Custom initializer.
    init(points: Int) {
        self.points = points
    }
}

//: Logging out - synchronously
do {
    try User.logout()
    print("Successfully logged out")
} catch let error {
    print("Error logging out: \(error)")
}

/*:
 Login - asynchronously - Performs work on background
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

/*:
 Save your first `customKey` value to your `ParseUser`
 Asynchrounously - Performs work on background
 queue and returns to specified callbackQueue.
 If no callbackQueue is specified it returns to main queue.
 Using `.mergeable` or `set()` allows you to only send
 the updated keys to the parse server as opposed to the
 whole object. You can chain set calls or even use
 `set()` in combination with mutating the `ParseObject`
 directly.
*/
var currentUser = User.current?
    .set(\.customKey, to: "myCustom")
    .set(\.gameScore, to: GameScore(points: 12))
    .set(\.targetScore, to: GameScore(points: 100))
currentUser?.allScores = [GameScore(points: 5), GameScore(points: 8)]
currentUser?.save { result in

    switch result {
    case .success(let updatedUser):
        print("Successfully saved custom fields of User to ParseServer: \(updatedUser)")
    case .failure(let error):
        print("Failed to update user: \(error)")
    }
}

//: Looking at the output of user from the previous login, it only has
//: a pointer to the `gameScore` and `targetScore` fields. You can
//: fetch using `include` to get the gameScore.
User.current?.fetch(includeKeys: ["gameScore"]) { result in
    switch result {
    case .success:
        print("Successfully fetched user with gameScore key: \(String(describing: User.current))")
    case .failure(let error):
        print("Error fetching User: \(error)")
    }
}

//: The `target` gameScore is still missing. You can get all pointer fields at
//: once by including `["*"]`.
User.current?.fetch(includeKeys: ["*"]) { result in
    switch result {
    case .success:
        print("Successfully fetched user with all keys: \(String(describing: User.current))")
    case .failure(let error):
        print("Error fetching User: \(error)")
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
newUser.customKey = "mind"
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
var currentUser2 = User.current
currentUser2?.username = "bye"
currentUser2?.password = "world"
currentUser2?.signup { result in
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
