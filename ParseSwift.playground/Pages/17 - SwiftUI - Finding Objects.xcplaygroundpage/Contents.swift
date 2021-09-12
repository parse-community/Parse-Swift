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
struct GameScore: ParseObject, Identifiable {

    //: Conform to Identifiable for iOS13+
    var id: String { // swiftlint:disable:this identifier_name
        guard let objectId = self.objectId else {
            return UUID().uuidString
        }
        return objectId
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
    var myFiles: [ParseFile]?

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
    @State var name = ""
    @State var score = ""

    var body: some View {
        NavigationView {
            if let error = viewModel.error {
                Text(error.description)
            } else {
                //: Warning - List seems to only work in Playgrounds Xcode 13+.
                List(viewModel.results, id: \.id) { result in
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
            TextField("Name", text: $name)
            TextField("Score", text: $score)
            Button(action: {
                guard let scoreValue = Int(score),
                      let linkToFile = URL(string: "https://parseplatform.org/img/logo.svg") else {
                    return
                }
                var score = GameScore(name: name, score: scoreValue)
                //: Create new `ParseFile` for saving.
                let file1 = ParseFile(name: "file1.svg", cloudURL: linkToFile)
                let file2 = ParseFile(name: "file2.svg", cloudURL: linkToFile)
                score.myFiles = [file1, file2]
            }, label: {
                Text("Save score")
            })
        }/*.onAppear(perform: {
            viewModel.find()
        })*/
    }
}

PlaygroundPage.current.setLiveView(ContentView())

PlaygroundPage.current.finishExecution()
//: [Next](@next)
