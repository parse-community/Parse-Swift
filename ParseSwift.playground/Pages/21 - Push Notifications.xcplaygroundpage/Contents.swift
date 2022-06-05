//: [Previous](@previous)

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
    var originalData: Data?

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
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.customKey,
                                     original: object) {
            updated.customKey = object.customKey
        }
        return updated
    }
}

/**
 We will begin by creating the payload information we want to
 send in the push notification.
 */
var alert = ParsePushPayloadAppleAlert()
alert.body = "Hello from ParseSwift!"
var data = ParsePushPayload()
data.setAlert(alert)
data.setBadge(1)

/*:
 We now crate a query where the `objectId`
 matches the installation of this Playground.
*/
var installationQuery = Installation.query()
if let objectId = Installation.current?.objectId {
    installationQuery.where("objectId" ==  objectId)
}

//: We can create a new push using the data and query.
let push = ParsePush<Installation, ParsePushPayload>(data: data, query: installationQuery)

//: Storing this property for later.
var pushStatusId = ""

//: We can send the push notification whenever we are ready.
push.send { result in
    switch result {
    case .success(let statusId):
        print("The push was created with id: \"\(statusId)\"")
        //: Update the stored property with the lastest status id.
        pushStatusId = statusId
    case .failure(let error):
        print("Couldn't create push: \(error)")
    }
}

push.fetchStatus(pushStatusId) { result in
    switch result {
    case .success(let pushStatus):
        print("The push status is: \"\(pushStatus)\"")
    case .failure(let error):
        print("Couldn't fetch push status: \(error)")
    }
}

/*:
 Lets create another Push, this time by incrementing the badge
 and using channels instead of a query.
 */
alert.body = "Hello from ParseSwift again!"
data.setAlert(alert)
data.incrementBadge()

var push2 = ParsePush<Installation, ParsePushPayload>(data: data)
push2.channels = Set(["newDevices"])

//: Send the new notification.
push2.send { result in
    switch result {
    case .success(let statusId):
        print("The push was created with id: \"\(statusId)\"")
        //: Update the stored property with the lastest status id.
        pushStatusId = statusId
    case .failure(let error):
        print("Couldn't create push: \(error)")
    }
}

push2.fetchStatus(pushStatusId) { result in
    switch result {
    case .success(let pushStatus):
        print("The push status is: \"\(pushStatus)\"")
    case .failure(let error):
        print("Couldn't fetch push status: \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
