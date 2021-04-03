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
    //: These are required for `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: These are required for `ParseInstallation`.
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
}

/*: Save your first `customKey` value to your `ParseInstallation`.
    Performs work on background queue and returns to designated on
    designated callbackQueue. If no callbackQueue is specified it
    returns to main queue.
 */
Installation.current?.customKey = "myCustomInstallationKey2"
Installation.current?.save { results in

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
    returns to main queue.
 */
Installation.current?.customKey = "updatedValue"
Installation.current?.save { results in

    switch results {
    case .success(let updatedInstallation):
        print("Successfully save myCustomInstallationKey to ParseServer: \(updatedInstallation)")
    case .failure(let error):
        print("Failed to update installation: \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
