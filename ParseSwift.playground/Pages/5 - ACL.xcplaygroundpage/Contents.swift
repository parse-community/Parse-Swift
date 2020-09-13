//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

do {
    var acl = ParseACL()
    acl.publicRead = false
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
        self.ACL = try? ParseACL.defaultACL()
    }
}

//: Define initial GameScores
let score = GameScore(score: 40)

/*: Query asynchronously (preferred way) - Performs work on background
    queue and returns to designated on designated callbackQueue.
    If no callbackQueue is specified it returns to main queue.
*/
score.save { result in
    switch result {
    case .success(let savedScore):
        assert(savedScore.objectId != nil)
        assert(savedScore.createdAt != nil)
        assert(savedScore.updatedAt != nil)
        assert(savedScore.ACL != nil)
        assert(savedScore.score == 40)

    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

PlaygroundPage.current.finishExecution()

//: [Next](@next)
