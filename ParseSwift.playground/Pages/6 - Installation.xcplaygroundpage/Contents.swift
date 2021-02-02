//: [Previous](@previous)

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

//: WARNING: All calls on Installation need to be done on the main queue
DispatchQueue.main.async {

    /*: Save your first customKey value to your `ParseInstallation`.
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
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
