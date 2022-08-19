![parse-repository-header-sdk-swift](https://user-images.githubusercontent.com/5673677/138289926-a26ca0bd-1713-4c30-b69a-acd840ccead0.png)

<h3 align="center">iOS · macOS · watchOS · tvOS · Linux · Android · Windows</h3>

---

[![Build Status CI](https://github.com/parse-community/Parse-Swift/workflows/ci/badge.svg?branch=main)](https://github.com/parse-community/Parse-Swift/actions?query=workflow%3Aci+branch%3Amain)
[![Build Status Release](https://github.com/parse-community/Parse-Swift/workflows/release/badge.svg)](https://github.com/parse-community/Parse-Swift/actions?query=workflow%3Arelease)
[![Coverage](https://codecov.io/gh/parse-community/Parse-Swift/branch/main/graph/badge.svg)](https://codecov.io/gh/parse-community/Parse-Swift/branches)
[![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/carthage/carthage)
[![Pod](https://img.shields.io/cocoapods/v/ParseSwift.svg)](https://cocoapods.org/pods/ParseSwift)

[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fparse-community%2FParse-Swift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/parse-community/Parse-Swift)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fparse-community%2FParse-Swift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/parse-community/Parse-Swift)

[![Backers on Open Collective](https://opencollective.com/parse-server/backers/badge.svg)][open-collective-link]
[![Sponsors on Open Collective](https://opencollective.com/parse-server/sponsors/badge.svg)][open-collective-link]
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)][license-link]
[![Forum](https://img.shields.io/discourse/https/community.parseplatform.org/topics.svg)](https://community.parseplatform.org/c/client-sdks/parseswift-sdk)
[![Twitter](https://img.shields.io/twitter/follow/ParsePlatform.svg?label=Follow&style=social)](https://twitter.com/intent/follow?screen_name=ParsePlatform)

---

A pure Swift library that gives you access to the powerful Parse Server backend from your Swift applications.

For more information about the Parse Platform and its features, see the public [documentation][docs]. The ParseSwift SDK is not a port of the [Parse-SDK-iOS-OSX SDK](https://github.com/parse-community/Parse-SDK-iOS-OSX) and though some of it may feel familiar, it is not backwards compatible and is designed using [protocol oriented programming (POP) and value types](https://www.pluralsight.com/guides/protocol-oriented-programming-in-swift) instead of OOP and reference types. You can learn more about POP by watching [Protocol-Oriented Programming in Swift](https://developer.apple.com/videos/play/wwdc2015/408/) or [Protocol and Value Oriented Programming in UIKit Apps](https://developer.apple.com/videos/play/wwdc2016/419/) videos from previous WWDC's. For more details about ParseSwift, visit the [api documentation](http://parseplatform.org/Parse-Swift/release/documentation/parseswift/).

To learn how to use or experiment with ParseSwift, you can run and edit the [ParseSwift.playground](https://github.com/parse-community/Parse-Swift/tree/main/ParseSwift.playground/Pages). You can use the parse-server in [this repo](https://github.com/netreconlab/parse-hipaa/tree/parse-swift) which has docker compose files (`docker-compose up` gives you a working server) configured to connect with the playground files, has [Parse Dashboard](https://github.com/parse-community/parse-dashboard), and can be used with MongoDB or PostgreSQL. You can also configure the Swift Playgrounds to work with your own Parse Server by editing the configuation in [Common.swift](https://github.com/parse-community/Parse-Swift/blob/e9ba846c399257100b285d25d2bd055628b13b4b/ParseSwift.playground/Sources/Common.swift#L4-L19). To learn more, check out [CONTRIBUTING.md](https://github.com/parse-community/Parse-Swift/blob/main/CONTRIBUTING.md#swift-playgrounds).

---

- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
  - [CocoaPods](#cocoapods)
  - [Carthage](#carthage)
- [Usage Guide](#usage-guide)
- [LiveQuery](#livequery)
  - [Setup Server](#setup-server)
  - [Use Client](#use-client)
    - [SwiftUI View Models Using Combine](#swiftui-view-models-using-combine)
    - [Traditional Callbacks](#traditional-callbacks)
  - [Advanced Usage](#advanced-usage)
- [Migration from Parse ObjC SDK](#migration-from-parse-objc-sdk)

## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

You can use The Swift Package Manager (SPM) to install ParseSwift by adding the following description to your `Package.swift` file:

```swift
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/parse-community/Parse-Swift", .upToNextMajor(from: "4.0.0")),
    ]
)
```
Then run `swift build`. 

You can also install using SPM in your Xcode project by going to 
"Project->NameOfYourProject->Swift Packages" and placing `https://github.com/parse-community/Parse-Swift.git` in the 
search field.

### [CocoaPods](https://cocoapods.org)

Add the following line to your Podfile:

```ruby
pod 'ParseSwift'
```

Run `pod install`, and you should now have the latest version from the main branch.

### [Carthage](https://github.com/carthage/carthage)

Add the following line to your Cartfile:
```
github "parse-community/Parse-Swift"
```
Run `carthage update`, and you should now have the latest version of ParseSwift SDK in your Carthage folder.

## Usage Guide

After installing ParseSwift, to use it first `import ParseSwift` in your AppDelegate.swift and then add the following code in your `application:didFinishLaunchingWithOptions:` method:
```swift
ParseSwift.initialize(applicationId: "xxxxxxxxxx", clientKey: "xxxxxxxxxx", serverURL: URL(string: "https://example.com")!)
```
Please checkout the [Swift Playground](https://github.com/parse-community/Parse-Swift/tree/main/ParseSwift.playground) for more usage information.

## LiveQuery

`Query` is one of the key concepts on the Parse Platform. It allows you to retrieve `ParseObject`s by specifying some conditions, making it easy to build apps such as a dashboard, a todo list or even some strategy games. However, `Query` is based on a pull model, which is not suitable for apps that need real-time support.

Suppose you are building an app that allows multiple users to edit the same file at the same time. `Query` would not be an ideal tool since you can not know when to query from the server to get the updates.

To solve this problem, we introduce Parse LiveQuery. This tool allows you to subscribe to a `Query` you are interested in. Once subscribed, the server will notify clients whenever a `ParseObject` that matches the `Query` is created or updated, in real-time.

### Setup Server

Parse LiveQuery contains two parts, the LiveQuery server and the LiveQuery clients (this SDK). In order to use live queries, you need to at least setup the server.

The easiest way to setup the LiveQuery server is to make it run with the [Open Source Parse Server](https://github.com/ParsePlatform/parse-server/wiki/Parse-LiveQuery#server-setup).


### Use Client

#### SwiftUI View Models Using Combine

The LiveQuery client interface is based around the concept of `Subscription`s. You can register any `Query` for live updates from the associated live query server and use the query as a view model for a SwiftUI view by simply using the `subscribe` property of a query:

```swift
let myQuery = GameScore.query("points" > 9)

struct ContentView: View {

    //: A LiveQuery subscription can be used as a view model in SwiftUI
    @StateObject var subscription = myQuery.subscribe!
    
    var body: some View {
        VStack {

            if subscription.subscribed != nil {
                Text("Subscribed to query!")
            } else if subscription.unsubscribed != nil {
                Text("Unsubscribed from query!")
            } else if let event = subscription.event {

                //: This is how you register to receive notificaitons of events related to your LiveQuery.
                switch event.event {

                case .entered(let object):
                    Text("Entered with points: \(object.points)")
                case .left(let object):
                    Text("Left with points: \(object.points)")
                case .created(let object):
                    Text("Created with points: \(object.points)")
                case .updated(let object):
                    Text("Updated with points: \(object.points)")
                case .deleted(let object):
                    Text("Deleted with points: \(object.points)")
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
```

or by calling the `subscribe(_ client: ParseLiveQuery)` method of a query. If you want to customize your view model more you can subclass `Subscription` or add the subscription to your own view model. You can test out LiveQuery subscriptions in [Swift Playgrounds](https://github.com/parse-community/Parse-Swift/blob/a8b3d00b848f3351d2c61a569d4ad4a3c96890d2/ParseSwift.playground/Pages/11%20-%20LiveQuery.xcplaygroundpage/Contents.swift#L38-L95).

#### Traditional Callbacks

You can also use asynchronous call backs to subscribe to a LiveQuery:

```swift
let myQuery = Message.query("from" == "parse")
guard let subscription = myQuery.subscribeCallback else {
    print("Error subscribing...")
    return
}
```

or by calling the `subscribeCallback(_ client: ParseLiveQuery)` method of a query.

Where `Message` is a ParseObject.

Once you've subscribed to a query, you can `handle` events on them, like so:

```swift
subscription.handleSubscribe { subscribedQuery, isNew in

    //Handle the subscription however you like.
    if isNew {
        print("Successfully subscribed to new query \(subscribedQuery)")
    } else {
        print("Successfully updated subscription to new query \(subscribedQuery)")
    }
}
```

You can handle any event listed in the LiveQuery [spec](https://github.com/parse-community/parse-server/wiki/Parse-LiveQuery-Protocol-Specification#event-message):
```swift
subscription.handleEvent { _, event in
    // Called whenever an object was created
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
```

Similiarly, you can unsubscribe and register to be notified when it occurs:
```swift
subscription.handleUnsubscribe { query in
    print("Unsubscribed from \(query)")
}

//: To unsubscribe from your query.
do {
    try query.unsubscribe()
} catch {
    print(error)
}
```

Handling errors is and other events is similar, take a look at the `Subscription` class for more information. You can test out LiveQuery subscriptions in [Swift Playgrounds](https://github.com/parse-community/Parse-Swift/blob/a8b3d00b848f3351d2c61a569d4ad4a3c96890d2/ParseSwift.playground/Pages/11%20-%20LiveQuery.xcplaygroundpage/Contents.swift#L97-L142).

### Advanced Usage

You are not limited to a single Live Query Client - you can create multiple instances of `ParseLiveQuery`, use certificate authentication and pinning, receive metrics about each client connection, connect to individual server URLs, and more.

[docs]: https://docs.parseplatform.org
[license-link]: LICENSE
[open-collective-link]: https://opencollective.com/parse-server

## Migration from Parse ObjC SDK

See the [Migration Guide](MIGRATION.md) to help you migrate from the Parse ObjC SDK.