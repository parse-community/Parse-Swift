//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import Parse
PlaygroundPage.current.needsIndefiniteExecution = true

//: start parse-server with
//: npm start -- --appId applicationId --clientKey clientKey --masterKey masterKey --mountPath /1

Parse.initialize(applicationId: "applicationId",
                 clientKey: "clientKey",
                 masterKey: "masterKey",
                 serverURL: URL(string: "http://localhost:1337/1")!)


struct GameScore: Parse.ObjectType {
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

let score = GameScore(score: 10)

score.save() { (result) in
    guard case .success(var gameScore) = result else {
        assert(false)
        return
    }
    assert(gameScore.objectId != nil)
    assert(gameScore.createdAt != nil)
    assert(gameScore.updatedAt != nil)
    assert(gameScore.score == 10)
    var originalGameScore = gameScore
    gameScore.score = 200
    gameScore.save() { (result) in
        guard case .success(var gameScore) = result else {
            assert(false)
            return
        }
        assert(originalGameScore.score == 10) // original object is unchanged
        assert(originalGameScore.objectId == gameScore.objectId) // response has proper values
    }
}

let score2 = GameScore(score: 3)
GameScore.saveAll(score, score2) { (result) in
    guard case .success(let results) = result else {
        assert(false)
        return
    }
    results.forEach { (result) in
        let (_, error) = result
        assert(error == nil, "error should be nil")
    }
}

// Also works as extension of sequence
[score, score2].saveAll() { (result) in
    guard case .success(let results) = result else {
        assert(false)
        return
    }
    results.forEach { (result) in
        let (_, error) = result
        assert(error == nil, "error should be nil")
    }
}

//: [Next](@next)
