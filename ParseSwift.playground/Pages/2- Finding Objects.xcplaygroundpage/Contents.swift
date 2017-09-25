//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift
PlaygroundPage.current.needsIndefiniteExecution = true

//: start parse-server with
//: npm start -- --appId applicationId --clientKey clientKey --masterKey masterKey --mountPath /1

initializeParse()

struct GameScore: ParseSwift.ObjectType {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ACL?

    var score: Int?
}

var score = GameScore()
score.score = 200
try score.save()

let afterDate = Date().addingTimeInterval(-300)
var query = GameScore.query("score" > 100, "createdAt" > afterDate)
let results = try query.limit(2).find(options: [])
assert(results.count >= 1)
results.forEach { (score) in
    guard let createdAt = score.createdAt else { fatalError() }
    assert(createdAt.timeIntervalSince1970 > afterDate.timeIntervalSince1970, "date should be ok")
}
//: [Next](@next)
