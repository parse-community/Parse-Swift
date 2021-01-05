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
/*
class HandleLiveQueryNotifications: ParseLiveQueryDelegate {
    func receivedChallenge(_ challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                         URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }
}*/

if #available(iOS 13.0, macOS 10.15, *) {
    let query = GameScore.query("score" > 9)
    let subscription = Subscription(query: query)
    //let notifications = HandleLiveQueryNotifications()
    let liveQuery = ParseLiveQuery()
    //liveQuery.delegate = notifications
    let subscribed = try liveQuery.subscribe(query, handler: subscription)
    subscribed.handleEvent { query, score in
        print(query)
        print(score)
    }
} else {
    // Fallback on earlier versions
    print("Can't run")
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
