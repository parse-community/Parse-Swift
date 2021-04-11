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

struct GameScore: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties.
    var score: Int?
    var timeStamp: Date? = Date()
    var oldScore: Int?
}

var score = GameScore()
score.score = 200
score.oldScore = 10
do {
    try score.save()
} catch {
    print(error)
}

let afterDate = Date().addingTimeInterval(-300)
var query = GameScore.query("score" > 50,
                            "createdAt" > afterDate)
    .order([.descending("score")])

//: Query asynchronously (preferred way) - Performs work on background
//: queue and returns to specified callbackQueue.
//: If no callbackQueue is specified it returns to main queue.
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

//: Query synchronously (not preferred - all operations on main queue).
let results = try query.find()
assert(results.count >= 1)
results.forEach { (score) in
    guard let createdAt = score.createdAt else { fatalError() }
    assert(createdAt.timeIntervalSince1970 > afterDate.timeIntervalSince1970, "date should be ok")
    print("Found score: \(score)")
}

//: Query first asynchronously (preferred way) - Performs work on background
//: queue and returns to specified callbackQueue.
//: If no callbackQueue is specified it returns to main queue.
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

//: Query based on relative time. Have to be using mongoDB.
let queryRelative = GameScore.query(relative(key: "createdAt",
                                             comparator: .lessThan,
                                             time: "10 minutes ago"))
queryRelative.find { results in
    switch results {
    case .success(let scores):

        print("Found scores using relative time: \(scores)")

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

let querySelect = query.select("score")
querySelect.first { results in
    switch results {
    case .success(let score):

        guard score.objectId != nil,
            let createdAt = score.createdAt else { fatalError() }
        assert(createdAt.timeIntervalSince1970 > afterDate.timeIntervalSince1970, "date should be ok")
        print("Found score using select: \(score)")

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

let queryExclude = query.exclude("score")
queryExclude.first { results in
    switch results {
    case .success(let score):

        guard score.objectId != nil,
            let createdAt = score.createdAt else { fatalError() }
        assert(createdAt.timeIntervalSince1970 > afterDate.timeIntervalSince1970, "date should be ok")
        print("Found score using exclude: \(score)")

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

PlaygroundPage.current.finishExecution()

//: [Next](@next)
