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
    var score: Double?

    //: Your own properties.
    var points: Int?
    var timeStamp: Date? = Date()
    var oldScore: Int?
    var isHighest: Bool?
}

var score = GameScore()
score.points = 200
score.oldScore = 10
score.isHighest = true
do {
    try score.save()
} catch {
    print(error)
}

let afterDate = Date().addingTimeInterval(-300)
var query = GameScore.query("points" > 50,
                            "createdAt" > afterDate)
    .order([.descending("points")])

//: Query asynchronously (preferred way) - Performs work on background
//: queue and returns to specified callbackQueue.
//: If no callbackQueue is specified it returns to main queue.
query.limit(2).find(callbackQueue: .main) { results in
    switch results {
    case .success(let scores):

        assert(scores.count >= 1)
        scores.forEach { score in
            guard let createdAt = score.createdAt else { fatalError() }
            assert(createdAt.timeIntervalSince1970 > afterDate.timeIntervalSince1970, "date should be ok")
            print("Found score: \(score)")
        }

    case .failure(let error):
        if error.equalsTo(.objectNotFound) {
            assertionFailure("Object not found for this query")
        } else {
            assertionFailure("Error querying: \(error)")
        }
    }
}

//: Query synchronously (not preferred - all operations on main queue).
let results = try query.find()
assert(results.count >= 1)
results.forEach { score in
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
        if error.containedIn([.objectNotFound, .invalidQuery]) {
            assertionFailure("The query is invalid or the object is not found.")
        } else {
            assertionFailure("Error querying: \(error)")
        }
    }
}

//: Query first asynchronously (preferred way) - Performs work on background
//: queue and returns to specified callbackQueue.
//: If no callbackQueue is specified it returns to main queue.
query.withCount { results in
    switch results {
    case .success(let (score, count)):
        print("Found scores: \(score) total amount: \(count)")

    case .failure(let error):
        if error.containedIn([.objectNotFound, .invalidQuery]) {
            assertionFailure("The query is invalid or the object is not found.")
        } else {
            assertionFailure("Error querying: \(error)")
        }
    }
}

//: Query based on relative time.
let queryRelative = GameScore.query(relative("createdAt" < "10 minutes ago"))
queryRelative.find { results in
    switch results {
    case .success(let scores):

        print("Found scores using relative time: \(scores)")

    case .failure(let error):
        print("Error querying: \(error)")
    }
}

let querySelect = query.select("points")
querySelect.first { results in
    switch results {
    case .success(let score):

        guard score.objectId != nil,
            let createdAt = score.createdAt else { fatalError() }
        assert(createdAt.timeIntervalSince1970 > afterDate.timeIntervalSince1970, "date should be ok")
        print("Found score using select: \(score)")

    case .failure(let error):
        if let parseError = error.equalsTo(.objectNotFound) {
            assertionFailure("Object not found: \(parseError)")
        } else {
            assertionFailure("Error querying: \(error)")
        }
    }
}

let queryExclude = query.exclude("points")
queryExclude.first { results in
    switch results {
    case .success(let score):

        guard score.objectId != nil,
            let createdAt = score.createdAt else { fatalError() }
        assert(createdAt.timeIntervalSince1970 > afterDate.timeIntervalSince1970, "date should be ok")
        print("Found score using exclude: \(score)")

    case .failure(let error):
        if let parseError = error.containedIn(.objectNotFound, .invalidQuery) {
            assertionFailure("Matching error found: \(parseError)")
        } else {
            assertionFailure("Error querying: \(error)")
        }
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
