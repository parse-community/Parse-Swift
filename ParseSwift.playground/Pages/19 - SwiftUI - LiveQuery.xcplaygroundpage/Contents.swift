//: [Previous](@previous)

//: If you are using Xcode 13+, ignore the comments below:
//: For this page, make sure your build target is set to ParseSwift (iOS) and targeting
//: an iPhone, iPod, or iPad. Also be sure your `Playground Settings`
//: in the `File Inspector` is `Platform = iOS`. This is because
//: SwiftUI in macOS Playgrounds doesn't seem to build correctly
//: Be sure to switch your target and `Playground Settings` back to
//: macOS after leaving this page.

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
var query = GameScore.query("score" < 11)

//: To use subscriptions inside of SwiftUI
struct ContentView: View {

    //: A LiveQuery subscription can be used as a view model in SwiftUI
    @ObservedObject var subscription = query.subscribe!

    var body: some View {
        VStack {

            if subscription.subscribed != nil {
                Text("Subscribed to query!")
            } else if subscription.unsubscribed != nil {
                Text("Unsubscribed from query!")
            } else if let event = subscription.event {

                //: This is how you register to receive notifications of events related to your LiveQuery.
                switch event.event {

                case .entered(let object):
                    Text("Entered with score: \(object.score)")
                case .left(let object):
                    Text("Left with score: \(object.score)")
                case .created(let object):
                    Text("Created with score: \(object.score)")
                case .updated(let object):
                    Text("Updated with score: \(object.score)")
                case .deleted(let object):
                    Text("Deleted with score: \(object.score)")
                }
            } else {
                Text("Not subscribed to a query")
            }

            Spacer()

            Text("Update GameScore in Parse Dashboard to see changes here")

            Button(action: {
                try? query.unsubscribe()
            }, label: {
                Text("Unsubscribe")
                    .font(.headline)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .padding()
                    .cornerRadius(20.0)
                    .frame(width: 300, height: 50)
            })
        }
    }
}

PlaygroundPage.current.setLiveView(ContentView())

PlaygroundPage.current.finishExecution()
//: [Next](@next)
