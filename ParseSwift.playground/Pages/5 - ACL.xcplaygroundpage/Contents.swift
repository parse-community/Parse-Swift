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

do {
    var acl = ParseACL()
    acl.publicRead = true
    acl.publicWrite = false
    try ParseACL.setDefaultACL(acl, withAccessForCurrentUser: true)
} catch {
    assertionFailure("Error storing default ACL to Keychain: \(error)")
}

//: Create your own value typed ParseObject.
struct GameScore: ParseObject {
    //: These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    //: Your own properties
    var points: Int?

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

//: Define initial GameScores.
var score = GameScore(points: 40)

/*:
 Save asynchronously (preferred way) - Performs work on background
 queue and returns to specified callbackQueue. If no callbackQueue
 is specified it returns to main queue.
*/
score.save { result in
    switch result {
    case .success(let savedScore):
        assert(savedScore.objectId != nil)
        assert(savedScore.createdAt != nil)
        assert(savedScore.updatedAt != nil)
        assert(savedScore.points == 40)
        assert(savedScore.ACL != nil)

        print("Saved score with ACL: \(savedScore)")

    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
