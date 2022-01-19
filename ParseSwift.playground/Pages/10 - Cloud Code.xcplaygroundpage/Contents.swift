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

//: Create your own value typed `ParseCloud` type.
struct Hello: ParseCloud {

    //: Return type of your Cloud Function
    typealias ReturnType = String

    //: These are required by `ParseCloud`, you can set the default value to make it easier
    //: to use.
    var functionJobName: String = "hello"

    //: If your cloud function takes arguments, they can be passed by creating properties:
    //var argument1: [String: Int] = ["test": 5]
}

//: Create another `ParseCloud` type.
struct TestCloudCode: ParseCloud {

    //: Return type of your Cloud Function
    typealias ReturnType = String

    //: These are required by `ParseCloud`, you can set the default value to make it easier
    //: to use.
    var functionJobName: String = "testCloudCode"

    //: If your cloud function takes arguments, they can be passed by creating properties:
    //var argument1: [String: Int] = ["test": 5]
}

/*: Assuming you have the Cloud Function named "hello" on your parse-server:
     // main.js
     Parse.Cloud.define('hello', async () => {
       return 'Hello world!';
     });
 */
let hello = Hello()

hello.runFunction { result in
    switch result {
    case .success(let response):
        print("Response from cloud function: \(response)")
    case .failure(let error):
        assertionFailure("Error calling cloud function: \(error)")
    }
}

/*: Assuming you have the Cloud Function named "testCloudCode" on your parse-server.
 You can catch custom errors created in Cloud Code:
     // main.js
     Parse.Cloud.define("testCloudCode", async() => {
        throw new Parse.Error(3000, "cloud has an error on purpose.");
     });
 */
let testCloudCode = TestCloudCode()

testCloudCode.runFunction { result in
    switch result {
    case .success:
        assertionFailure("Should have thrown a custom error")
    case .failure(let error):
        switch error.code {
        case .other:
            guard let otherCode = error.otherCode else {
                assertionFailure("Should have unwrapped otherCode")
                return
            }
            switch otherCode {
            case 3000:
                print("Received Cloud Code error: \(error)")
            default:
                assertionFailure("""
                    Should have received code \"3000\"
                    Instead received \(error)
                """)
            }
        default:
            assertionFailure("""
                Should have received code \"other\"
                Instead received \(error)
            """)
        }
    }
}

//: Jobs can be run the same way by using the method `startJob()`.

//: Saving objects with context for beforeSave, afterSave, etc.
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

    //: Implement your own version of merge
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
//: to preserve the convenience initializer.
extension GameScore {
    //: Custom initializer.
    init(points: Int) {
        self.points = points
    }

    init(objectId: String?) {
        self.objectId = objectId
    }
}

//: Define a GameScore.
let score = GameScore(points: 10)

//: Save asynchronously (preferred way) with the context option.
score.save(options: [.context(["hello": "world"])]) { result in
    switch result {
    case .success(let savedScore):
        print("Successfully saved \(savedScore)")
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
