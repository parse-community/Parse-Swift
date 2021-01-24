//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift
PlaygroundPage.current.needsIndefiniteExecution = true

initializeParse()

struct GameScore: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    var score: Int?
}

var score = GameScore()
score.score = 200
try score.save()

let afterDate = Date().addingTimeInterval(-300)
var query = GameScore.query("score" > 100, "createdAt" > afterDate)

// Query asynchronously (preferred way) - Performs work on background
// queue and returns to designated on designated callbackQueue.
// If no callbackQueue is specified it returns to main queue.
query.limit(2).find(callbackQueue: .main) { results in
    switch results {
    case .success(let scores):

        assert(scores.count >= 1)
        scores.forEach { (score) in
            guard let createdAt = score.createdAt else { fatalError() }
            assert(createdAt.timeIntervalSince1970 > afterDate.timeIntervalSince1970, "date should be ok")
            print("Found score: \(score)")
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

// Query synchronously (not preferred - all operations on main queue).
let results = try query.find()
assert(results.count >= 1)
results.forEach { (score) in
    guard let createdAt = score.createdAt else { fatalError() }
    assert(createdAt.timeIntervalSince1970 > afterDate.timeIntervalSince1970, "date should be ok")
    print("Found score: \(score)")
}

// Query first asynchronously (preferred way) - Performs work on background
// queue and returns to designated on designated callbackQueue.
// If no callbackQueue is specified it returns to main queue.
query.first { results in
    switch results {
    case .success(let score):

        guard score.objectId != nil,
            let createdAt = score.createdAt else { fatalError() }
        assert(createdAt.timeIntervalSince1970 > afterDate.timeIntervalSince1970, "date should be ok")
        print("Found score: \(score)")

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

PlaygroundPage.current.finishExecution()

//: [Next](@next)
