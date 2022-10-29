//: For this page, make sure your build target is set to ParseSwift (macOS) and targeting
//: `My Mac` or whatever the name of your mac is. Also be sure your `Playground Settings`
//: in the `File Inspector` is `Platform = macOS`. This is because
//: Keychain in iOS Playgrounds behaves differently. Every page in Playgrounds should
//: be set to build for `macOS` unless specified.

import PlaygroundSupport
import Foundation
import ParseSwift
PlaygroundPage.current.needsIndefiniteExecution = true

/*: start parse-server with
npm start -- --appId applicationId --clientKey clientKey --masterKey masterKey --mountPath /1
*/

//: In Xcode, make sure you are building the "ParseSwift (macOS)" framework.

initializeParse()

//: Get current SDK version
if let version = ParseVersion.current {
    print("Current Swift SDK version is \"\(version)\"")
}

//: Check the health of your Parse Server.
do {
    print("Server health is: \(try ParseHealth.check())")
} catch {
    print(error)
}

//: Create your own value typed `ParseObject`.
struct GameScore: ParseObject {
    //: These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    //: Your own properties.
    var points: Int?

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
        return updated
    }
}

//: It's recommended to place custom initializers in an extension
//: to preserve the memberwise initializer.
extension GameScore {

    init(points: Int) {
        self.points = points
    }

    init(objectId: String?) {
        self.objectId = objectId
    }
}

struct GameData: ParseObject {
    //: These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    //: Your own properties.
    var polygon: ParsePolygon?
    //: `ParseBytes` needs to be a part of the original schema
    //: or else you will need your masterKey to force an upgrade.
    var bytes: ParseBytes?

    /*:
     Optional - implement your own version of merge
     for faster decoding after updating your `ParseObject`.
     */
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if shouldRestoreKey(\.polygon,
                             original: object) {
            updated.polygon = object.polygon
        }
        if shouldRestoreKey(\.bytes,
                             original: object) {
            updated.bytes = object.bytes
        }
        return updated
    }
}

//: It's recommended to place custom initializers in an extension
//: to preserve the memberwise initializer.
extension GameData {

    init (bytes: ParseBytes?, polygon: ParsePolygon) {
        self.bytes = bytes
        self.polygon = polygon
    }
}

//: Define initial GameScores.
let score = GameScore(points: 10)
let score2 = GameScore(points: 3)

/*: Save asynchronously (preferred way) - Performs work on background
    queue and returns to specified callbackQueue.
    If no callbackQueue is specified it returns to main queue.
*/
score.save { result in
    switch result {
    case .success(let savedScore):
        assert(savedScore.objectId != nil)
        assert(savedScore.createdAt != nil)
        assert(savedScore.updatedAt != nil)
        assert(savedScore.points == 10)

        /*:
         To modify, you need to make it a var as the value type
         was initialized as immutable. Using `.mergeable`
         allows you to only send the updated keys to the
         parse server as opposed to the whole object. Make sure
         to call `.mergeable` before you begin
         your first mutation of your `ParseObject`.
        */
        var changedScore = savedScore.mergeable
        changedScore.points = 200
        changedScore.save { result in
            switch result {
            case .success(let savedChangedScore):
                assert(savedChangedScore.points == 200)
                assert(savedScore.objectId == savedChangedScore.objectId)

            case .failure(let error):
                assertionFailure("Error saving: \(error)")
            }
        }
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: This will store the second batch score to be used later.
var score2ForFetchedLater: GameScore?

//: Saving multiple GameScores at once.
[score, score2].saveAll { results in
    switch results {
    case .success(let otherResults):
        var index = 0
        otherResults.forEach { otherResult in
            switch otherResult {
            case .success(let savedScore):
                print("""
                    Saved \"\(savedScore.className)\" with
                    points \(String(describing: savedScore.points)) successfully
                """)
                if index == 1 {
                    score2ForFetchedLater = savedScore
                }
                index += 1
            case .failure(let error):
                assertionFailure("Error saving: \(error)")
            }
        }

    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: Saving multiple GameScores at once using a transaction.
//: May not work on MongoDB depending on your configuration.
/*[score, score2].saveAll(transaction: true) { results in
    switch results {
    case .success(let otherResults):
        var index = 0
        otherResults.forEach { otherResult in
            switch otherResult {
            case .success(let savedScore):
                print("Saved \"\(savedScore.className)\" with points \(savedScore.points) successfully")
                if index == 1 {
                    score2ForFetchedLater = savedScore
                }
                index += 1
            case .failure(let error):
                assertionFailure("Error saving: \(error)")
            }
        }

    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}*/

//: Save synchronously (not preferred - all operations on current queue).
let savedScore: GameScore?
do {
    savedScore = try score.save()
} catch {
    savedScore = nil
    fatalError("Error saving: \(error)")
}

assert(savedScore != nil)
assert(savedScore?.objectId != nil)
assert(savedScore?.createdAt != nil)
assert(savedScore?.updatedAt != nil)
assert(savedScore?.points == 10)

/*:
 To modify, you need to make a mutable copy of `savedScore`.
 Instead of using `.mergeable` this time, we will use the `set()`
 method which allows us to accomplish the same thing
 as `.mergeable`. You can choose to use `.set()` or
 `.mergeable` as long as you use either before you begin
 your first mutation of your `ParseObject`.
*/
guard var changedScore = savedScore else {
    fatalError("Should have produced mutable changedScore")
}
changedScore = changedScore.set(\.points, to: 200)

let savedChangedScore: GameScore?
do {
    savedChangedScore = try changedScore.save()
    print("Updated score: \(String(describing: savedChangedScore))")
} catch {
    savedChangedScore = nil
    fatalError("Error saving: \(error)")
}

assert(savedChangedScore != nil)
assert(savedChangedScore!.points == 200)
assert(savedScore!.objectId == savedChangedScore!.objectId)

let otherResults: [(Result<GameScore, ParseError>)]?
do {
    otherResults = try [score, score2].saveAll()
} catch {
    otherResults = nil
    fatalError("Error saving: \(error)")
}
assert(otherResults != nil)

otherResults!.forEach { result in
    switch result {
    case .success(let savedScore):
        print("Saved \"\(savedScore.className)\" with points \(String(describing: savedScore.points)) successfully")
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: Now we will create another object and delete it.
let score3 = GameScore(points: 30)

//: Save the score and store it in "scoreToDelete".
var scoreToDelete: GameScore!
do {
    scoreToDelete = try score3.save()
    print("Successfully saved: \(scoreToDelete!)")
} catch {
    assertionFailure("Error deleting: \(error)")
}

//: Delete the score from parse-server synchronously.
do {
    try scoreToDelete.delete()
    print("Successfully deleted: \(scoreToDelete!)")
} catch {
    assertionFailure("Error deleting: \(error)")
}

//: Now we will fetch a ParseObject that has already been saved based on its' objectId.
let scoreToFetch = GameScore(objectId: savedScore?.objectId)

//: Asynchronously (preferred way) fetch this GameScore based on it is objectId alone.
scoreToFetch.fetch { result in
    switch result {
    case .success(let fetchedScore):
        print("Successfully fetched: \(fetchedScore)")
    case .failure(let error):
        assertionFailure("Error fetching: \(error)")
    }
}

//: Synchronously fetch this GameScore based on it is objectId alone.
do {
    let fetchedScore = try scoreToFetch.fetch()
    print("Successfully fetched: \(fetchedScore)")
} catch {
    assertionFailure("Error fetching: \(error)")
}

//: Now we will fetch `ParseObject`'s in batch that have already been saved based on its' objectId.
let score2ToFetch = GameScore(objectId: score2ForFetchedLater?.objectId)

//: Asynchronously (preferred way) fetch GameScores based on it is objectId alone.
[scoreToFetch, score2ToFetch].fetchAll { result in
    switch result {
    case .success(let fetchedScores):

        fetchedScores.forEach { result in
            switch result {
            case .success(let fetched):
                print("Successfully fetched: \(fetched)")
            case .failure(let error):
                print("Error fetching: \(error)")
            }
        }
    case .failure(let error):
        assertionFailure("Error fetching: \(error)")
    }
}

var fetchedScore: GameScore!

//: Synchronously fetchAll GameScore's based on it is objectId's alone.
do {
    let fetchedScores = try [scoreToFetch, score2ToFetch].fetchAll()
    fetchedScores.forEach { result in
        switch result {
        case .success(let fetched):
            fetchedScore = fetched
            print("Successfully fetched: \(fetched)")
        case .failure(let error):
            print("Error fetching: \(error)")
        }
    }
} catch {
    assertionFailure("Error fetching: \(error)")
}

//: Asynchronously (preferred way) deleteAll GameScores based on it is objectId alone.
[scoreToFetch, score2ToFetch].deleteAll { result in
    switch result {
    case .success(let deletedScores):
        deletedScores.forEach { result in
            switch result {
            case .success:
                print("Successfully deleted score")
            case .failure(let error):
                print("Error deleting: \(error)")
            }
        }
    case .failure(let error):
        assertionFailure("Error deleting: \(error)")
    }
}

//: Synchronously deleteAll GameScore's based on it is objectId's alone.
//: Commented out because the async above deletes the items already.
/* do {
    let fetchedScores = try [scoreToFetch, score2ToFetch].deleteAll()
    fetchedScores.forEach { result in
        switch result {
        case .success(let fetched):
            print("Successfully deleted: \(fetched)")
        case .failure(let error):
            print("Error deleted: \(error)")
        }
    }
} catch {
    assertionFailure("Error deleting: \(error)")
}*/

//: How to add `ParseBytes` and `ParsePolygon` to objects.
let points = [
    try ParseGeoPoint(latitude: 0, longitude: 0),
    try ParseGeoPoint(latitude: 0, longitude: 1),
    try ParseGeoPoint(latitude: 1, longitude: 1),
    try ParseGeoPoint(latitude: 1, longitude: 0),
    try ParseGeoPoint(latitude: 0, longitude: 0)
]

do {
    let polygon = try ParsePolygon(points)
    let bytes = ParseBytes(data: "hello world".data(using: .utf8)!)
    var gameData = GameData(bytes: bytes, polygon: polygon)
    gameData = try gameData.save()
    print("Successfully saved: \(gameData)")
} catch {
    print("Error saving: \(error.localizedDescription)")
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
