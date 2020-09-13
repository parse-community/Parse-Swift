//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

struct Installation: ParseInstallation {
    //: These are required for ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ACL?

    //: These are required for ParseInstallation
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

    // Your custom keys
    var customKey: String?
}

DispatchQueue.main.async {
    //Save your first customKey value to your ParseUser
    Installation.current?.customKey = "myCustomInstallationKey"
    Installation.current?.save { results in

        switch results {
        case .success(let updatedInstallation):
            print("Succesufully save myCustomInstallationKey to ParseServer: \(updatedInstallation)")
        case .failure(let error):
            print("Failed to update installation: \(error)")
        }
    }
}

//: [Next](@next)
