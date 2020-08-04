//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift
PlaygroundPage.current.needsIndefiniteExecution = true

//: start parse-server with
//: npm start -- --appId applicationId --clientKey clientKey --masterKey masterKey --mountPath /1

initializeParse()

struct GameScore: ParseSwift.ParseObject {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ACL?

    //: Your own properties
    var score: Int

    //: a custom initializer
    init(score: Int) {
        self.score = score
    }
}

var score = GameScore(score: 10)

guard let savedScore = try? score.save() else { fatalError() }
assert(savedScore.objectId != nil)
assert(savedScore.createdAt != nil)
assert(savedScore.updatedAt != nil)
assert(savedScore.score == 10)

// Need to make it a var as Value Types
var changedScore = savedScore
changedScore.score = 200
guard let savedChangedScore = try? changedScore.save() else { fatalError() }
assert(savedChangedScore.score == 200)
assert(savedChangedScore.objectId == changedScore.objectId)

let score2 = GameScore(score: 3)
guard let results = try? GameScore.saveAll(score, score2) else { fatalError() }
results.forEach { (result) in
    let (_, error) = result
    assert(error == nil, "error should be nil")
}

guard let otherResults = try? [score, score2].saveAll() else { fatalError() }
otherResults.forEach { (result) in
    let (_, error) = result
    assert(error == nil, "error should be nil")
}

PlaygroundPage.current.finishExecution()

//: [Next](@next)
