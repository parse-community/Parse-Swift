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
let incrementOperation = savedScore
    .operation.increment("score", by: 1)

incrementOperation.save { result in
    switch result {
    case .success:
        print("Original score: \(savedScore). Check the new score on Parse Dashboard.")
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: You can increment the score again syncronously.
do {
    _ = try incrementOperation.save()
    print("Original score: \(savedScore). Check the new score on Parse Dashboard.")
} catch {
    print(error)
}

//: There are other operations: add/remove/delete objects from `ParseObjects`.
//: In fact, the `users` and `roles` relations from `ParseRoles` used the add/remove operations.
let operations = savedScore.operation

//: Example: operations.add("hello", objects: ["test"])

PlaygroundPage.current.finishExecution()
//: [Next](@next)
