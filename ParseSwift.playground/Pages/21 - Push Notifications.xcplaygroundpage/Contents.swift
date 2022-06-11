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
let helloAlert = ParsePushAppleAlert(body: "Hello from ParseSwift!")
let applePayload = ParsePushPayloadApple(alert: helloAlert)
    .setBadge(1)

/*:
 We now crate a query where the `objectId`
 is not null or undefined.
*/
let installationQuery = Installation.query(isNotNull(key: "objectId"))

//: We can create a new push using the data and query.
let push = ParsePush(payload: applePayload, query: installationQuery)

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

//: Fetch the recent notificaiton.
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
let helloAgainAlert = ParsePushAppleAlert(body: "Hello from ParseSwift again!")
let applePayload2 = ParsePushPayloadApple(alert: helloAgainAlert)
    .incrementBadge()

var push2 = ParsePush<Installation, ParsePushPayloadApple>(payload: applePayload2)
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

//: Fetch the recent notificaiton.
push2.fetchStatus(pushStatusId) { result in
    switch result {
    case .success(let pushStatus):
        print("The push status is: \"\(pushStatus)\"")
    case .failure(let error):
        print("Couldn't fetch push status: \(error)")
    }
}

/*:
 Lets create a Firebase Cloud Message Push.
 */
let helloNotification = ParsePushFirebaseNotification(body: "Hello from ParseSwift using FCM!")
let firebasePayload = ParsePushPayloadFirebase(notification: helloNotification)

let push3 = ParsePush(payload: firebasePayload, query: installationQuery)

//: Send the new notification.
push3.send { result in
    switch result {
    case .success(let statusId):
        print("The Firebase push was created with id: \"\(statusId)\"")
        //: Update the stored property with the lastest status id.
        pushStatusId = statusId
    case .failure(let error):
        print("Couldn't create push: \(error)")
    }
}

//: Fetch the recent notificaiton.
push3.fetchStatus(pushStatusId) { result in
    switch result {
    case .success(let pushStatus):
        print("The Firebase push status is: \"\(pushStatus)\"")
    case .failure(let error):
        print("Couldn't fetch push status: \(error)")
    }
}

/*:
 If you have a mixed push environment and are querying
 multiple ParsePushStatus's you will can use the any
 payload, `ParsePushPayloadAny`.
 */
let query = ParsePushStatus<Installation, ParsePushPayloadAny>
    .query(isNotNull(key: "objectId"))

//: Be sure to add the `userMasterKey option.
query.findAll(options: [.useMasterKey]) { result in
    switch result {
    case .success(let pushStatus):
        print("All matching status: \"\(pushStatus)\"")
    case .failure(let error):
        print("Couldn't perform query: \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
