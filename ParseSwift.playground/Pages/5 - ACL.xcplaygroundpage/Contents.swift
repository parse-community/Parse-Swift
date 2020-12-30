//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

do {
    var acl = ParseACL()
    acl.publicRead = true
    acl.publicWrite = false
    try ParseACL.setDefaultACL(acl, withAccessForCurrentUser: true)
} catch {
    assertionFailure("Error storing default ACL to Keychain: \(error)")
}

//: Create your own ValueTyped ParseObject wi
struct GameScore: ParseObject {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties
    var score: Int

    //: a custom initializer
    init(score: Int) {
        self.score = score
    }
}

//: Define initial GameScores
var score = GameScore(score: 40)

//: Set the ACL to default for your GameScore
score.ACL = try? ParseACL.defaultACL()

/*: Save asynchronously (preferred way) - Performs work on background
    queue and returns to designated on designated callbackQueue.
    If no callbackQueue is specified it returns to main queue.
*/
score.save { result in
    switch result {
    case .success(let savedScore):
        assert(savedScore.objectId != nil)
        assert(savedScore.createdAt != nil)
        assert(savedScore.updatedAt != nil)
        assert(savedScore.score == 40)
        assert(savedScore.ACL != nil)

        print("Saved score with ACL: \(savedScore)")

    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

PlaygroundPage.current.finishExecution()

//: [Next](@next)
