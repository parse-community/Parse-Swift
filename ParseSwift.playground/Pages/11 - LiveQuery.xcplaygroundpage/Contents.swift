//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift
PlaygroundPage.current.needsIndefiniteExecution = true

initializeParse()

//: Create your own ValueTyped ParseObject
struct GameScore: ParseObject {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties
    var score: Int = 0

    //custom initializer
    init(score: Int) {
        self.score = score
    }

    init(objectId: String?) {
        self.objectId = objectId
    }
}

//: Be sure you have LiveQuery enabled on your server.

//: Create a query just as you normally would.
var query = GameScore.query("score" > 9)

//: This is how you subscribe your created query
let subscription = query.subscribe!

//: This is how you receive notifications about the success
//: of your subscription.
subscription.handleSubscribe { _ in
    print("Successfully subscribed to query")

    //: You can check this subscription is for this query
    do {
        if try ParseLiveQuery.getDefault()!.isSubscribed(query) {
            print("Subscribed")
        } else {
            print("Not Subscribed")
        }
    } catch {
        fatalError("Error checking if subscribed...")
    }
}

//: This is how you register to receive notificaitons of events related to your LiveQuery.
subscription.handleEvent { query, event in
    print(query)
    print(event)
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

//: Now go to your dashboard, goto the GameScore table and add, update, remove rows.
//: You should receive notifications for each.

//: To update the query for your subscription.
query = GameScore.query("score" > 40)
query.update(subscription)

//: This is how you register to receive notificaitons about being unsubscribed.
subscription.handleUnsubscribe { query in
    print("Unsubscribed from \(query)")
}

//: To unsubscribe from your query.
query.unsubscribe()

PlaygroundPage.current.finishExecution()
//: [Next](@next)
