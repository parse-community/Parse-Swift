//: [Previous](@previous)

//: For this page, make sure your build target is set to ParseSwift (macOS) and targeting
//: `My Mac` or whatever the name of your mac is. Also be sure your `Playground Settings`
//: in the `File Inspector` is `Platform = macOS`. This is because
//: Keychain in iOS Playgrounds behaves differently. Every page in Playgrounds should
//: be set to build for `macOS` unless specified.

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

//: To track when the app has been opened, do the following.
ParseAnalytics.trackAppOpened { result in
    if case .success = result {
        print("Saved analytics for app opened.")
    }
}

//: To track any event, do the following.
var friendEvent = ParseAnalytics(name: "openedFriendList")
friendEvent.track { result in
    if case .success = result {
        print("Saved analytics for custom event.")
    }
}

//: You can also add dimensions to your analytics.
friendEvent.track(dimensions: ["more": "info"]) { result in
    if case .success = result {
        print("Saved analytics for custom event with dimensions.")
    }
}

PlaygroundPage.current.finishExecution()

//: [Next](@next)
