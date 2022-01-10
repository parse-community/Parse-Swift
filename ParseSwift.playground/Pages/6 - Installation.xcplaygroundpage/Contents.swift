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

struct Installation: ParseInstallation, ParseObjectMutable {
    //: These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var score: Double?

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

    //: Implement your own version of merge
    func merge(_ object: Self) throws -> Self {
        var updated = try mergeParse(object)
        if updated.isRestoreOriginalKey(\.customKey,
                                         original: object) {
            updated.customKey = object.customKey
        }
        return updated
    }
}

/*: Save your first `customKey` value to your `ParseInstallation`.
    Performs work on background queue and returns to designated on
    designated callbackQueue. If no callbackQueue is specified it
    returns to main queue. Note that this may be the first time you
    are saving your Installation.
 */
let currentInstallation = Installation.current
currentInstallation?.save { results in

    switch results {
    case .success(let updatedInstallation):
        print("Successfully saved Installation to ParseServer: \(updatedInstallation)")
    case .failure(let error):
        print("Failed to update installation: \(error)")
    }
}

/*: Update your `ParseInstallation` `customKey` value.
    Performs work on background queue and returns to designated on
    designated callbackQueue. If no callbackQueue is specified it
    returns to main queue.
 */
var installationToUpdate = Installation.current?.mutable
installationToUpdate?.customKey = "myCustomInstallationKey2"
installationToUpdate?.save { results in

    switch results {
    case .success(let updatedInstallation):
        print("Successfully save myCustomInstallationKey to ParseServer: \(updatedInstallation)")
    case .failure(let error):
        print("Failed to update installation: \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
