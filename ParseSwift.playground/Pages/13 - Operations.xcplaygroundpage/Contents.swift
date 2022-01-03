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

struct GameScore: ParseObject {
    //: These are required by ParseObject.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var score: Double?

    //: Your own properties.
    var points: Int? = 0
    var name: String?
}

//: It's recommended to place custom initializers in an extension
//: to preserve the convenience initializer.
extension GameScore {
    //: Custom initializer.
    init(points: Int) {
        self.points = points
    }

    init(objectId: String?) {
        self.objectId = objectId
    }
}

//: You can have the server do operations on your `ParseObject`'s for you.

//: First lets create another GameScore.
let savedScore: GameScore!
do {
    let score = GameScore(points: 102, name: "player1")
    savedScore = try score.save()
} catch {
    savedScore = nil
    assertionFailure("Error saving: \(error)")
}

//: Then we will increment the points.
let incrementOperation = savedScore
    .operation.increment("points", by: 1)

incrementOperation.save { result in
    switch result {
    case .success:
        print("Original score: \(String(describing: savedScore)). Check the new score on Parse Dashboard.")
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: You can increment the score again syncronously.
do {
    _ = try incrementOperation.save()
    print("Original score: \(String(describing: savedScore)). Check the new score on Parse Dashboard.")
} catch {
    print(error)
}

//: Query all scores who have a name.
let query1 = GameScore.query(notNull(key: "name"))
let results1 = try query1.find()
results1.forEach { score in
    print("Found score with a name: \(score)")
}

//: You can also remove a value for a property using unset.
let unsetOperation = savedScore
    .operation.unset(("points", \.points))
do {
    let updatedScore = try unsetOperation.save()
    print("Updated score: \(updatedScore). Check the new score on Parse Dashboard.")
} catch {
    print(error)
}

//: There may be cases where you want to set/forceSet a value to null
//: instead of unsetting
let setToNullOperation = savedScore
    .operation.set(("name", \.name), value: nil)
do {
    let updatedScore = try setToNullOperation.save()
    print("Updated score: \(updatedScore). Check the new score on Parse Dashboard.")
} catch {
    print(error)
}

//: Query synchronously (not preferred - all operations on main queue).
let query2 = GameScore.query(isNull(key: "name"))
let results2 = try query2.find()
results2.forEach { score in
    print("Found score with name is null: \(score)")
}

//: There are other operations: set/forceSet/unset/add/remove, etc. objects from `ParseObject`s.
//: In fact, the `users` and `roles` relations from `ParseRoles` used the add/remove operations.
//: Multiple operations can be chained together. See:
//: https://github.com/parse-community/Parse-Swift/pull/268#issuecomment-955714414
let operations = savedScore.operation

//: Example: operations.add("hello", objects: ["test"]).

PlaygroundPage.current.finishExecution()
//: [Next](@next)
