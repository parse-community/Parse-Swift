//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift
PlaygroundPage.current.needsIndefiniteExecution = true

//: start parse-server with
//: npm start -- --appId applicationId --clientKey clientKey --masterKey masterKey --mountPath /1

initializeParse()

struct GameScore: ParseSwift.ObjectType {
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

guard let score = try? score.sync.save() else { fatalError() }
assert(score.objectId != nil)
assert(score.createdAt != nil)
assert(score.updatedAt != nil)
assert(score.score == 10)

// Need to make it a var as Value Types
var changedScore = score
changedScore.score = 200
guard let savedScore = try? changedScore.sync.save() else { fatalError() }
assert(score.score == 10)
assert(score.objectId == changedScore.objectId)

// TODO: Add support for sync saveAll
let score2 = GameScore(score: 3)
let results = try? GameScore.saveAllSync(score, score2) else { fatalError() }
results.forEach { (result) in
    let (_, error) = result
    assert(error == nil, "error should be nil")
}

let otherResults = [score, score2].saveAllSync() else { fatalError() }
otherResults.forEach { (result) in
    let (_, error) = result
    assert(error == nil, "error should be nil")
}

PlaygroundPage.current.finishExecution()

//: [Next](@next)
