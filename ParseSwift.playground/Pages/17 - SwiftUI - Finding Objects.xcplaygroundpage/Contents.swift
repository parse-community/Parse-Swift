//: [Previous](@previous)

//: For this page, make sure your build target is set to ParseSwift (iOS) and targeting
//: an iPhone, iPod, or iPad. Also be sure your `Playground Settings`
//: in the `File Inspector` is `Platform = iOS`. This is because
//: SwiftUI in macOS Playgrounds doesn't seem to build correctly
//: Be sure to switch your target and `Playground Settings` back to
//: macOS after leaving this page.

#if canImport(SwiftUI)
import PlaygroundSupport
import Foundation
import ParseSwift
import SwiftUI
#if canImport(Combine)
import Combine
#endif

PlaygroundPage.current.needsIndefiniteExecution = true

initializeParse()

//: Create your own value typed ParseObject.
struct GameScore: ParseObject, Identifiable {

    //: Conform to Identifiable for iOS13+
    var id: String { // swiftlint:disable:this identifier_name
        if let objectId = self.objectId {
            return objectId
        } else {
            return UUID().uuidString
        }
    }

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

//: To use queries with SwiftUI

//: Create a SwiftUI view.
struct ContentView: View {

    //: A view model in SwiftUI
    @ObservedObject var viewModel = GameScore.query("score" > 2)
        .order([.descending("score")])
        .viewModel

    var body: some View {
        NavigationView {
            if let error = viewModel.error {
                Text(error.debugDescription)
            } else {
                //: Warning - List seems to only work in Playgrounds Xcode 13+.
                List(viewModel.results, id: \.objectId) { result in
                    VStack(alignment: .leading) {
                        Text("Score: \(result.score)")
                            .font(.headline)
                        if let createdAt = result.createdAt {
                            Text("\(createdAt.description)")
                        }
                    }
                }
            }
            Spacer()
        }.onAppear(perform: {
            viewModel.find()
        })
    }
}

PlaygroundPage.current.setLiveView(ContentView())
#endif

//: [Next](@next)
