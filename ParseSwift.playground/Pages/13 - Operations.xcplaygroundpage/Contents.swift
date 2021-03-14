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
    //: Those are required for Object.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties.
    var score: Int = 0

    //: Custom initializer.
    init(score: Int) {
        self.score = score
    }

    init(objectId: String?) {
        self.objectId = objectId
    }
}

//: You can have the server do operations on your `ParseObject`'s for you.

//: First lets create another GameScore.
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

//: There are other operations: add/remove/delete objects from `ParseObject`s.
//: In fact, the `users` and `roles` relations from `ParseRoles` used the add/remove operations.
let operations = savedScore.operation

//: Example: operations.add("hello", objects: ["test"]).

PlaygroundPage.current.finishExecution()
//: [Next](@next)
