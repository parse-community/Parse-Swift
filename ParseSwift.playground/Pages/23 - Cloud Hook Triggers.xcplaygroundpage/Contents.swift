//: [Previous](@previous)

/*:
 The code in this Playground is intended to run at the
 server level only. It is not intended to be run in client
 applications as it requires the use of the master key.
 */

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

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

/*:
 Parse Hook Triggers can be created by conforming to
 `ParseHookFunctionable`.
 */
struct HookTrigger: ParseHookTriggerable {
    var className: String?
    var triggerName: ParseHookTriggerType?
    var url: URL?
}

/*:
 Lets create our first Hook trigger by first creating an instance
 with the name of the trigger and url for the hook.
 */
let gameScore = GameScore()
var myTrigger = HookTrigger(object: gameScore,
                            triggerName: .afterSave,
                            url: URL(string: "https://api.example.com/bar")!)

//: Then, create the trigger on the server.
myTrigger.create { result in
    switch result {
    case .success(let newFunction):
        print("Created: \"\(newFunction)\"")
    case .failure(let error):
        print("Could not create: \(error)")
    }
}

/*:
 The trigger can be fetched at any time.
 */
myTrigger.fetch { result in
    switch result {
    case .success(let fetchedFunction):
        print("Fetched: \"\(fetchedFunction)\"")
    case .failure(let error):
        print("Could not fetch: \(error)")
    }
}

/*:
 There will be times you need to update a Hook trigger.
 You can update your hook at anytime.
 */
myTrigger.url = URL(string: "https://api.example.com/car")
myTrigger.update { result in
    switch result {
    case .success(let updated):
        print("Updated: \"\(updated)\"")
    case .failure(let error):
        print("Could not update: \(error)")
    }
}

/*:
 Lets fetchAll using the instance method to see all of the
 available hook triggers.
 */
myTrigger.fetchAll { result in
    switch result {
    case .success(let triggers):
        print("Current: \"\(triggers)\"")
    case .failure(let error):
        print("Could not fetch: \(error)")
    }
}

/*:
 Hook triggers can also be deleted.
 */
myTrigger.delete { result in
    switch result {
    case .success:
        print("The Parse Cloud trigger was deleted successfully")
    case .failure(let error):
        print("Could not delete: \(error)")
    }
}

/*:
 You can also use the fetchAll type method to fetch all of
 the current Hook triggers.
 */
HookTrigger.fetchAll { result in
    switch result {
    case .success(let triggers):
        print("Current: \"\(triggers)\"")
    case .failure(let error):
        print("Could not fetch: \(error)")
    }
}

PlaygroundPage.current.finishExecution()

//: [Next](@next)
