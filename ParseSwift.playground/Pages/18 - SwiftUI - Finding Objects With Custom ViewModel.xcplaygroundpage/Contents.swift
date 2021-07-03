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

    //: Custom initializer.
    init(name: String, score: Int) {
        self.name = name
        self.score = score
    }
}

//: To use queries with SwiftUI

//: To create a custom view model that queries GameScore's.
class ViewModel: ObservableObject {
    @Published var objects = [GameScore]()
    @Published var error: ParseError?

    private var subscriptions = Set<AnyCancellable>()

    init() {
        fetchScores()
    }

    func fetchScores() {
        let query = GameScore.query("score" > 2)
            .order([.descending("score")])
        let publisher = query
            .findPublisher()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    // Publish error.
                    self.error = error
                case .finished:
                    print("Successfully queried data")
                }
            },
            receiveValue: {
                // Publish found objects
                self.objects = $0
                print("Found \(self.objects.count), objects: \(self.objects)")
            })
        publisher.store(in: &subscriptions)
    }
}

//: Create a SwiftUI view.
struct ContentView: View {

    //: A view model in SwiftUI
    @ObservedObject var viewModel = ViewModel()

    var body: some View {
        NavigationView {
            if let error = viewModel.error {
                Text(error.debugDescription)
            } else {
                //: Warning - List seems to only work in Playgrounds Xcode 13+.
                List(viewModel.objects, id: \.objectId) { object in
                    VStack(alignment: .leading) {
                        Text("Score: \(object.score)")
                            .font(.headline)
                        if let createdAt = object.createdAt {
                            Text("\(createdAt.description)")
                        }
                    }
                }
            }
            Spacer()
        }
    }
}

PlaygroundPage.current.setLiveView(ContentView())
#endif

//: [Next](@next)
