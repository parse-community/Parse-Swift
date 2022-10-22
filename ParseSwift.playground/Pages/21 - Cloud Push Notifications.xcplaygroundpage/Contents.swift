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

    /*:
     Optional - implement your own version of merge
     for faster decoding after updating your `ParseObject`.
     */
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.customKey,
                                     original: object) {
            updated.customKey = object.customKey
        }
        return updated
    }
}

/*:
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

//: Now create a new push notification using the payload and query.
let push = ParsePush(payload: applePayload, query: installationQuery)

//: Creating this property to use later in the playground.
var pushStatusId = ""

//: You can send the push notification whenever you are ready.
push.send { result in
    switch result {
    case .success(let statusId):
        print("The push was created with id: \"\(statusId)\"")
        //: Update the stored property with the lastest status id.
        pushStatusId = statusId
    case .failure(let error):
        print("Could not create push: \(error)")
    }
}

//: You can fetch the status of notificaiton if you know it is id.
push.fetchStatus(pushStatusId) { result in
    switch result {
    case .success(let pushStatus):
        print("The push status is: \"\(pushStatus)\"")
    case .failure(let error):
        print("Could not fetch push status: \(error)")
    }
}

/*:
 Lets create another Push, this time by incrementing the badge
 and using channels instead of a query.
 */
let helloAgainAlert = ParsePushAppleAlert(body: "Hello from ParseSwift again!")
let applePayload2 = ParsePushPayloadApple(alert: helloAgainAlert)
    .incrementBadge()

var push2 = ParsePush(payload: applePayload2)
//: Set all channels the notificatioin should be published to.
push2.channels = Set(["newDevices"])

//: You can send the push notification whenever you are ready.
push2.send { result in
    switch result {
    case .success(let statusId):
        print("The push was created with id: \"\(statusId)\"")
        //: Update the stored property with the lastest status id.
        pushStatusId = statusId
    case .failure(let error):
        print("Could not create push: \(error)")
    }
}

/*:
 Similar to before, you can fetch the status of notificaiton
 if you know the id.
 */
push2.fetchStatus(pushStatusId) { result in
    switch result {
    case .success(let pushStatus):
        print("The push status is: \"\(pushStatus)\"")
    case .failure(let error):
        print("Could not fetch push status: \(error)")
    }
}

/*:
 You can also send push notifications using Firebase Cloud Messanger.
 */
let helloNotification = ParsePushFirebaseNotification(body: "Hello from ParseSwift using FCM!")
let firebasePayload = ParsePushPayloadFirebase(notification: helloNotification)

let push3 = ParsePush(payload: firebasePayload, query: installationQuery)

//: You can send the push notification whenever you are ready.
push3.send { result in
    switch result {
    case .success(let statusId):
        print("The Firebase push was created with id: \"\(statusId)\"")
        //: Update the stored property with the lastest status id.
        pushStatusId = statusId
    case .failure(let error):
        print("Could not create push: \(error)")
    }
}

/*:
 Similar to before, you can fetch the status of notificaiton
 if you know the id.
 */
push3.fetchStatus(pushStatusId) { result in
    switch result {
    case .success(let pushStatus):
        print("The Firebase push status is: \"\(pushStatus)\"")
    case .failure(let error):
        print("Could not fetch push status: \(error)")
    }
}

/*:
 If you have a mixed push environment and are querying
 multiple ParsePushStatus's you will can use the any
 payload, `ParsePushPayloadAny`.
 */
let query = ParsePushStatus<ParsePushPayloadAny>
    .query(isNotNull(key: "objectId"))

/*:
 Be sure to add the `.userMasterKey option when doing
 anything with `ParsePushStatus` directly.
*/
query.findAll(options: [.usePrimaryKey]) { result in
    switch result {
    case .success(let pushStatus):
        print("All matching statuses: \"\(pushStatus)\"")
    case .failure(let error):
        print("Could not perform query: \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
