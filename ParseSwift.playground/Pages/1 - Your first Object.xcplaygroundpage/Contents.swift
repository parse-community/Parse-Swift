import PlaygroundSupport
import Foundation
import ParseSwift
PlaygroundPage.current.needsIndefiniteExecution = true

/*: start parse-server with
npm start -- --appId applicationId --clientKey clientKey --masterKey masterKey --mountPath /1
*/

/*: In Xcode, make sure you are building the "ParseSwift (macOS)" framework.
 */

initializeParse()

//: Create your own ValueTyped ParseObject
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
let score = GameScore(score: 10)
let score2 = GameScore(score: 3)

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
        assert(savedScore.ACL == nil)
        assert(savedScore.score == 10)

        /*: To modify, need to make it a var as the Value Type
            was initialized as immutable
        */
        var changedScore = savedScore
        changedScore.score = 200
        changedScore.save { result in
            switch result {
            case .success(var savedChangedScore):
                assert(savedChangedScore.score == 200)
                assert(savedScore.objectId == savedChangedScore.objectId)

                /*: Note that savedChangedScore is mutable since it's
                    a var after success.
                */
                savedChangedScore.score = 500

            case .failure(let error):
                assertionFailure("Error saving: \(error)")
            }
        }
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: Saving multiple GameScores at once
[score, score2].saveAll { results in
    switch results {
    case .success(let otherResults):
        otherResults.forEach { otherResult in
            switch otherResult {
            case .success(let savedScore):
                print("Saved \"\(savedScore.className)\" with score \(savedScore.score) successfully")

            case .failure(let error):
                assertionFailure("Error saving: \(error)")
            }
        }

    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: Save synchronously (not preferred - all operations on main queue)
let savedScore: GameScore?
do {
    savedScore = try score.save()
} catch {
    savedScore = nil
    fatalError("Error saving: \(error)")
}

assert(savedScore != nil)
assert(savedScore?.objectId != nil)
assert(savedScore?.createdAt != nil)
assert(savedScore?.updatedAt != nil)
assert(savedScore?.score == 10)

/*:  To modify, need to make it a var as the Value Type
    was initialized as immutable
*/
guard var changedScore = savedScore else {
    fatalError()
}
changedScore.score = 200

let savedChangedScore: GameScore?
do {
    savedChangedScore = try changedScore.save()
} catch {
    savedChangedScore = nil
    fatalError("Error saving: \(error)")
}

assert(savedChangedScore != nil)
assert(savedChangedScore!.score == 200)
assert(savedScore!.objectId == savedChangedScore!.objectId)

let otherResults: [(Result<GameScore, ParseError>)]?
do {
    otherResults = try [score, score2].saveAll()
} catch {
    otherResults = nil
    fatalError("Error saving: \(error)")
}
assert(otherResults != nil)

otherResults!.forEach { result in
    switch result {
    case .success(let savedScore):
        print("Saved \"\(savedScore.className)\" with score \(savedScore.score) successfully")
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

PlaygroundPage.current.finishExecution()

//: [Next](@next)
