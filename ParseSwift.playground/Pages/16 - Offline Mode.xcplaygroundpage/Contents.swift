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

//: In order to enable offline mode you need to set offlinePolicy to either `create` or `save`
//: `save` will allow you to save and fetch objects.
//: `create` will allow you to create, save and fetch objects.
//: Note that `create` will require you to enable customObjectIds.
ParseSwift.initialize(applicationId: "applicationId",
                      clientKey: "clientKey",
                      masterKey: "masterKey",
                      serverURL: URL(string: "http://localhost:1337/1")!,
                      offlinePolicy: .create,
                      requiringCustomObjectIds: true,
                      usingEqualQueryConstraint: false,
                      usingDataProtectionKeychain: false)

struct GameScore: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    //: Your own properties.
    var points: Int?
    var timeStamp: Date? = Date()
    var oldScore: Int?
    var isHighest: Bool?

    /*:
     Optional - implement your own version of merge
     for faster decoding after updating your `ParseObject`.
     */
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points,
                                     original: object) {
            updated.points = object.points
        }
        if updated.shouldRestoreKey(\.timeStamp,
                                     original: object) {
            updated.timeStamp = object.timeStamp
        }
        if updated.shouldRestoreKey(\.oldScore,
                                     original: object) {
            updated.oldScore = object.oldScore
        }
        if updated.shouldRestoreKey(\.isHighest,
                                     original: object) {
            updated.isHighest = object.isHighest
        }
        return updated
    }
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

//: If you want to use local objects when an internet connection failed,
//: you need to set useLocalStore()
let afterDate = Date().addingTimeInterval(-300)
var query = GameScore.query("points" > 50,
                            "createdAt" > afterDate)
    .useLocalStore()
    .order([.descending("points")])

//: Query asynchronously (preferred way) - Performs work on background
//: queue and returns to specified callbackQueue.
//: If no callbackQueue is specified it returns to main queue.
query.limit(2)
    .order([.descending("points")])
    .find(callbackQueue: .main) { results in
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

//: Query synchronously (not preferred - all operations on current queue).
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

PlaygroundPage.current.finishExecution()
//: [Next](@next)
