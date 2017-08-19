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
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ACL?

    var score: Int?
}

func printString<T>(_ codable: T) where T: Encodable {
    let str = String(data: try! JSONEncoder().encode(codable), encoding: .utf8)!
    print(str)
}

var score = GameScore()
score.score = 200

score.save() { _ in
    var query = GameScore.query("score" > 100)
    query.limit(2).find() { (scores) in
        print(scores)
    }
}



//: [Next](@next)
