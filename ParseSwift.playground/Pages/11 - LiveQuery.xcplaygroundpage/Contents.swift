//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift
import SwiftUI

PlaygroundPage.current.needsIndefiniteExecution = true

initializeParse()

//: Create your own value typed ParseObject.
struct GameScore: ParseObject {
    //: These are required for any Object.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties.
    var score: Int = 0
	@NullableProperty var location: ParseGeoPoint?
	@NullableProperty var name: String?
}

//: It's recommended to place custom initializers in an extension
//: to preserve the convenience initializer.
extension GameScore {
    //: Custom initializer.
    init(name: String, score: Int) {
        self.name = name
        self.score = score
    }
}

//: Create a delegate for LiveQuery errors
class LiveQueryDelegate: ParseLiveQueryDelegate {

    func received(_ error: Error) {
        print(error)
    }

    func closedSocket(_ code: URLSessionWebSocketTask.CloseCode?, reason: Data?) {
        print("Socket closed with \(String(describing: code)) and \(String(describing: reason))")
    }
}

//: Be sure you have LiveQuery enabled on your server.

//: Set the delegate.
let delegate = LiveQueryDelegate()
if let socket = ParseLiveQuery.getDefault() {
    socket.receiveDelegate = delegate
}

//: Create a query just as you normally would.
var query = GameScore.query("score" < 11)

//: This is how you subscribe to your created query using callbacks.
let subscription = query.subscribeCallback!

//: This is how you receive notifications about the success
//: of your subscription.
subscription.handleSubscribe { subscribedQuery, isNew in

    //: You can check this subscription is for this query
    if isNew {
        print("Successfully subscribed to new query \(subscribedQuery)")
    } else {
        print("Successfully updated subscription to new query \(subscribedQuery)")
    }
}

//: This is how you register to receive notifications of events related to your LiveQuery.
subscription.handleEvent { _, event in
    switch event {

    case .entered(let object):
        print("Entered: \(object)")
    case .left(let object):
        print("Left: \(object)")
    case .created(let object):
        print("Created: \(object)")
    case .updated(let object):
        print("Updated: \(object)")
    case .deleted(let object):
        print("Deleted: \(object)")
    }
}

//: Ping the LiveQuery server
ParseLiveQuery.client?.sendPing { error in
    if let error = error {
        print("Error pinging LiveQuery server: \(error)")
    } else {
        print("Successfully pinged server!")
    }
}

//: Now go to your dashboard, go to the GameScore table and add, update or remove rows.
//: You should receive notifications for each.

//: This is how you register to receive notifications about being unsubscribed.
subscription.handleUnsubscribe { query in
    print("Unsubscribed from \(query)")
}

//: To unsubscribe from your query.
do {
    try query.unsubscribe()
} catch {
    print(error)
}

//: If you look at your server log, you will notice the client and server disconnnected.
//: This is because there is no more LiveQuery subscriptions.

//: Ping the LiveQuery server. This should produce an error
//: because LiveQuery is disconnected.
ParseLiveQuery.client?.sendPing { error in
    if let error = error {
        print("Error pinging LiveQuery server: \(error)")
    } else {
        print("Successfully pinged server!")
    }
}

//: Create a new query.
var query2 = GameScore.query("score" > 50)

//: Select the fields you are interested in receiving.
query2.fields("score")

//: Subscribe to your new query.
let subscription2 = query2.subscribeCallback!

//: As before, setup your subscription, event, and unsubscribe handlers.
subscription2.handleSubscribe { subscribedQuery, isNew in

    //: You can check this subscription is for this query.
    if isNew {
        print("Successfully subscribed to new query \(subscribedQuery)")
    } else {
        print("Successfully updated subscription to new query \(subscribedQuery)")
    }
}

subscription2.handleEvent { _, event in
    switch event {

    case .entered(let object):
        print("Entered: \(object)")
    case .left(let object):
        print("Left: \(object)")
    case .created(let object):
        print("Created: \(object)")
    case .updated(let object):
        print("Updated: \(object)")
    case .deleted(let object):
        print("Deleted: \(object)")
    }
}

subscription2.handleUnsubscribe { query in
    print("Unsubscribed from \(query)")
}

//: To close the current LiveQuery connection.
ParseLiveQuery.client?.close()

//: To close all LiveQuery connections use:
//ParseLiveQuery.client?.closeAll()

//: Ping the LiveQuery server. This should produce an error
//: because LiveQuery is disconnected.
ParseLiveQuery.client?.sendPing { error in
    if let error = error {
        print("Error pinging LiveQuery server: \(error)")
    } else {
        print("Successfully pinged server!")
    }
}

//: Resubscribe to your previous query.
//: Since we never unsubscribed you can use your previous handlers.
let subscription3 = query2.subscribeCallback!

//: Resubscribe to another previous query.
//: This one needs new handlers.
let subscription4 = query.subscribeCallback!

//: Need a new handler because we previously unsubscribed.
subscription4.handleSubscribe { subscribedQuery, isNew in

    //: You can check this subscription is for this query
    if isNew {
        print("Successfully subscribed to new query \(subscribedQuery)")
    } else {
        print("Successfully updated subscription to new query \(subscribedQuery)")
    }
}

//: Need a new event handler because we previously unsubscribed.
subscription4.handleEvent { _, event in
    switch event {

    case .entered(let object):
        print("Entered: \(object)")
    case .left(let object):
        print("Left: \(object)")
    case .created(let object):
        print("Created: \(object)")
    case .updated(let object):
        print("Updated: \(object)")
    case .deleted(let object):
        print("Deleted: \(object)")
    }
}

//: Need a new unsubscribe handler because we previously unsubscribed.
subscription4.handleUnsubscribe { query in
    print("Unsubscribed from \(query)")
}

//: To unsubscribe from your query.
do {
    try query2.unsubscribe()
} catch {
    print(error)
}

//: Ping the LiveQuery server
ParseLiveQuery.client?.sendPing { error in
    if let error = error {
        print("Error pinging LiveQuery server: \(error)")
    } else {
        print("Successfully pinged server!")
    }
}

//: To unsubscribe from your your last query.
do {
    try query.unsubscribe()
} catch {
    print(error)
}

//: If you look at your server log, you will notice the client and server disconnnected.
//: This is because there is no more LiveQuery subscriptions.

PlaygroundPage.current.finishExecution()
//: [Next](@next)
