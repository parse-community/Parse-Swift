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

/*:
 start parse-server with
 npm start -- --appId applicationId --clientKey clientKey --masterKey masterKey --mountPath /1
*/

/*:
 In Xcode, make sure you are building the "ParseSwift (macOS)" framework.
 */

initializeParse(customObjectId: true)

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
    //: Custom initializer.
    init(objectId: String, points: Int) {
        self.objectId = objectId
        self.points = points
    }
}

//: Define initial GameScore this time with custom `objectId`.
//: customObjectId has to be enabled on the server for this to work.
var score = GameScore(objectId: "myObjectId", points: 10)

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

        //: Now that this object has a `createdAt`, it is properly saved to the server.
        //: Any changes to `createdAt` and `objectId` will not be saved to the server.
        print("Saved score: \(savedScore)")

        /*:
         To modify, need to make it a var as the value type
         was initialized as immutable. Using `.mergeable` or `set()`
         allows you to only send the updated keys to the
         parse server as opposed to the whole object.
        */
        var changedScore = savedScore.mergeable
        changedScore.points = 200
        changedScore.save { result in
            switch result {
            case .success(let savedChangedScore):
                assert(savedChangedScore.points == 200)
                assert(savedScore.objectId == savedChangedScore.objectId)
                print("Updated score: \(savedChangedScore)")

            case .failure(let error):
                assertionFailure("Error saving: \(error)")
            }
        }
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: Fetch object
score.fetch { result in
    switch result {
    case .success(let fetchedScore):
        print("Successfully fetched: \(fetchedScore)")
    case .failure(let error):
        assertionFailure("Error fetching: \(error)")
    }
}

//: Query object
let query = GameScore.query("objectId" == "myObjectId")
query.first { result in
    switch result {
    case .success(let found):
        print(found)
    case .failure(let error):
        print(error)
    }
}

//: Now we will attempt to fetch a ParseObject that is not saved.
let scoreToFetch = GameScore(objectId: "hello")

//: Asynchronously (preferred way) fetch this GameScore based on it is objectId alone.
scoreToFetch.fetch { result in
    switch result {
    case .success(let fetchedScore):
        print("Successfully fetched: \(fetchedScore)")
    case .failure(let error):
        assertionFailure("Error fetching on purpose: \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
