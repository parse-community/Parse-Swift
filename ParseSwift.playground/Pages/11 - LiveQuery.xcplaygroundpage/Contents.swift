//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift
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
    var location: ParseGeoPoint?
    var name: String?

    //: Custom initializer.
    init(name: String, score: Int) {
        self.name = name
        self.score = score
    }
}

//: Be sure you have LiveQuery enabled on your server.

//: Create a query just as you normally would.
var query = GameScore.query("score" > 9)

//: This is how you subscribe to your created query using callbacks.
//: Note that if you want to use subscriptions with SwiftUI, you should
//: use `let subscription = query.subscribe` instead.
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

//: This is how you register to receive notificaitons of events related to your LiveQuery.
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

//: Now go to your dashboard, go to the GameScore table and add, update or remove rows.
//: You should receive notifications for each.

//: This is how you register to receive notificaitons about being unsubscribed.
subscription.handleUnsubscribe { query in
    print("Unsubscribed from \(query)")
}

//: To unsubscribe from your query.
do {
    try query.unsubscribe()
} catch {
    print(error)
}

//: Create a new query.
var query2 = GameScore.query("score" > 50)

//: Select the fields you are interested in receiving.
query2.fields("score")

//: Subscribe to your new query.
let subscription2 = query2.subscribeCallback!

//: As before, setup your subscription and event handlers.
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

//: Now go to your dashboard, go to the GameScore table and add, update or remove rows.
//: You should receive notifications for each, but only with your fields information.

//: This is how you register to receive notificaitons about being unsubscribed.
subscription2.handleUnsubscribe { query in
    print("Unsubscribed from \(query)")
}

//: To unsubscribe from your query.
do {
    try query2.unsubscribe()
} catch {
    print(error)
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
