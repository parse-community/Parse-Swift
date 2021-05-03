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

/*: start parse-server with
npm start -- --appId applicationId --clientKey clientKey --masterKey masterKey --mountPath /1
*/

/*: In Xcode, make sure you are building the "ParseSwift (macOS)" framework.
 */

initializeParseCustomObjectId()

//: Create your own value typed `ParseObject`.
struct GameScore: ParseObject {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties.
    var score: Int = 0

    //: Custom initializer.
    init(objectId: String, score: Int) {
        self.objectId = objectId
        self.score = score
    }
}

//: Define initial GameScore this time with custom `objectId`.
//: customObjectId has to be enabled on the server for this to work.
var score = GameScore(objectId: "myObjectId", score: 10)

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
        assert(savedScore.ACL == nil)
        assert(savedScore.score == 10)

        //: Now that this object has a `createdAt`, it's properly saved to the server.
        //: Any changes to `createdAt` and `objectId` will not be saved to the server.
        print("Saved score: \(savedScore)")

        /*: To modify, need to make it a var as the value type
            was initialized as immutable.
        */
        var changedScore = savedScore
        changedScore.score = 200
        changedScore.createdAt = Date()
        changedScore.save { result in
            switch result {
            case .success(var savedChangedScore):
                assert(savedChangedScore.score == 200)
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

//: [Next](@next)
