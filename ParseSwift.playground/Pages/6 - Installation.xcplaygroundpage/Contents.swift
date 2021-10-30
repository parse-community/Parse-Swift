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

struct Installation: ParseInstallation {
    //: These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: These are required by `ParseInstallation`.
    var installationId: String?
    var deviceType: String?
    var deviceToken: String?
    var badge: Int?
    var timeZone: String?
    var channels: [String]?
    var appName: String?
    var appIdentifier: String?
    var appVersion: String?
    var parseVersion: String?
    var localeIdentifier: String?

    //: Your custom keys
    var customKey: String?

    /*:
     It's recommended the developer adds the emptyObject computed property or similar.
     Gets an empty version of the respective object. This can be used when you only need to update a
     a subset of the fields of an object as oppose to updating every field of an object. Using an
     empty object and updating a subset of the fields reduces the amount of data sent between
     client and server when using `save` and `saveAll` to update objects.
    */
    var emptyObject: Self {
        var object = Self()
        object.objectId = objectId
        object.createdAt = createdAt
        return object
    }
}

/*: Save your first `customKey` value to your `ParseInstallation`.
    Performs work on background queue and returns to designated on
    designated callbackQueue. If no callbackQueue is specified it
    returns to main queue.
 */
var currentInstallation = Installation.current
currentInstallation?.customKey = "myCustomInstallationKey2"
currentInstallation?.save { results in

    switch results {
    case .success(let updatedInstallation):
        print("Successfully save myCustomInstallationKey to ParseServer: \(updatedInstallation)")
    case .failure(let error):
        print("Failed to update installation: \(error)")
    }
}

/*: Update your `ParseInstallation` `customKey` value.
    Performs work on background queue and returns to designated on
    designated callbackQueue. If no callbackQueue is specified it
    returns to main queue. Using `emptyObject` allows you to only
    send the updated keys to the parse server as opposed to the
    whole object.
 */
currentInstallation = currentInstallation?.emptyObject
currentInstallation?.customKey = "updatedValue"
currentInstallation?.save { results in

    switch results {
    case .success(let updatedInstallation):
        print("Successfully save myCustomInstallationKey to ParseServer: \(updatedInstallation)")
    case .failure(let error):
        print("Failed to update installation: \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
