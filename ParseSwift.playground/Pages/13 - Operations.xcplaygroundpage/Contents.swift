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
    var originalData: Data?

    //: Your own properties.
    var points: Int?
    var name: String?

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
        if updated.shouldRestoreKey(\.name,
                                     original: object) {
            updated.name = object.name
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

//: Query all scores whose name is null or undefined.
let query1 = GameScore.query(isNotNull(key: "name"))
let results1 = try query1.find()
print("Total found: \(results1.count)")
results1.forEach { score in
    print("Found score with a name: \(score)")
}

//: Query all scores whose name is undefined.
let query2 = GameScore.query(exists(key: "name"))
let results2 = try query2.find()
print("Total found: \(results2.count)")
results2.forEach { score in
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
    .operation.set(("name", \.name), to: nil)
do {
    let updatedScore = try setToNullOperation.save()
    print("Updated score: \(updatedScore). Check the new score on Parse Dashboard.")
} catch {
    print(error)
}

//: Query all scores whose name is null or undefined.
let query3 = GameScore.query(isNull(key: "name"))
let results3 = try query3.find()
print("Total found: \(results3.count)")
results3.forEach { score in
    print("Found score with name is null: \(score)")
}

//: Query all scores whose name is undefined.
let query4 = GameScore.query(doesNotExist(key: "name"))
let results4 = try query4.find()
print("Total found: \(results4.count)")
results4.forEach { score in
    print("Found score with name does not exist: \(score)")
}

//: There are other operations: set/forceSet/unset/add/remove, etc. objects from `ParseObject`s.
//: In fact, the `users` and `roles` relations from `ParseRoles` used the add/remove operations.
//: Multiple operations can be chained together. See:
//: https://github.com/parse-community/Parse-Swift/pull/268#issuecomment-955714414
let operations = savedScore.operation

//: Example: operations.add("hello", objects: ["test"]).

PlaygroundPage.current.finishExecution()
//: [Next](@next)
