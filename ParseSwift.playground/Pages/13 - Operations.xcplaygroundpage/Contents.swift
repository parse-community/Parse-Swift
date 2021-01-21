//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

//: Some ValueTypes ParseObject's we will use...
struct GameScore: ParseObject {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties
    var score: Int = 0

    //custom initializer
    init(score: Int) {
        self.score = score
    }

    init(objectId: String?) {
        self.objectId = objectId
    }
}

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
    var authData: [String: [String: String]?]?

    //: Your custom keys
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
        self.name = ""
    }
}

//: You can have the server do operations on your ParseObjects for you.

//: First lets create another GameScore
let savedScore: GameScore!
do {
    savedScore = try GameScore(score: 102).save()
} catch {
    savedScore = nil
    fatalError("Error saving: \(error)")
}

//: Then we will increment the score.
let incrementedOperation = savedScore
    .operation.increment("score", by: 1)

incrementedOperation.save { result in
    switch result {
    case .success:
        print("Original score: \(savedScore). Check the new score on Parse Dashboard.")
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: You can increment the score again syncronously.
do {
    _ = try incrementedOperation.save()
    print("Original score: \(savedScore). Check the new score on Parse Dashboard.")
} catch {
    print(error)
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
