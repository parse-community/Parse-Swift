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

struct GameScore: ParseObjectType {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?

    var score: Int?
}

func printString<T>(_ codable: T) where T: Encodable {
    let str = String(data: try! JSONEncoder().encode(codable), encoding: .utf8)!
    print(str)
}

var score = GameScore()
score.score = 30

printString(GameScore.find())
printString(score.save())
//GameScore.find()
//    .success { (scores) in
//        assert(scores.count > 0)
//        PlaygroundPage.current.finishExecution()
//    }.execute()

try score.save().execute()

var query = GameScore.query("score" > 100)

let command = query.limit(2).find()

try query.limit(2).find()
    .success { (scores) in
        print(scores)
    }
    .error({ (err) in
        print(err)
    })
    .execute()
//: [Next](@next)
