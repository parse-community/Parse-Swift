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
    public var objectId: String?
    public var createdAt: Date?
    public var updatedAt: Date?
    public var ACL: ACL?

    //: Your own properties
    let score: Int

    //: a custom initializer
    init(score: Int) {
        self.score = score
    }
}

let score = GameScore(score: 10)

try score.save().success { (gameScore) in
    assert(gameScore.objectId != nil)
    assert(gameScore.createdAt != nil)
    assert(gameScore.updatedAt != nil)
    assert(gameScore.score == 10)
}.error { (err) in
    print(err)
}.execute()

let score2 = GameScore(score: 3)
try GameScore.saveAll(score, score2).success { (results) in
    results.forEach({ (result) in
        let (obj, error) = result
        assert(error == nil, "error should be nil")
    })
}.execute()

// Also works as extension of sequence
try [score, score2].saveAll().success { (results) in
    print(results)
}.execute()

//: [Next](@next)
