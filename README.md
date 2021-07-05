<p align="center">
  <a href="https://parseplatform.org"><img alt="Parse Platform" src="https://user-images.githubusercontent.com/8621344/99892392-6f32dc80-2c42-11eb-8c32-db0fa4a66a81.png" width="200"></a>
</p>

<h2 align="center">ParseSwift</h2>

<p align="center">
    A pure Swift library that gives you access to the powerful Parse Server backend from your Swift applications.
</p>

<p align="center">
    <a href="https://twitter.com/intent/follow?screen_name=parseplatform"><img alt="Follow on Twitter" src="https://img.shields.io/twitter/follow/parseplatform?style=social&label=Follow"></a>
    <a href=" https://github.com/parse-community/Parse-Swift/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-lightgrey.svg"></a>
    <a href="#backers"><img alt="Backers on Open Collective" src="https://opencollective.com/parse-server/backers/badge.svg" /></a>
  <a href="#sponsors"><img alt="Sponsors on Open Collective" src="https://opencollective.com/parse-server/sponsors/badge.svg" /></a>
</p>

<p align="center">
<a href="https://swiftpackageindex.com/parse-community/Parse-Swift"><img alt="Swift 5.0" src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fparse-community%2FParse-Swift%2Fbadge%3Ftype%3Dswift-versions"></a>
<a href="https://swiftpackageindex.com/parse-community/Parse-Swift"><img alt="Platforms" src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fparse-community%2FParse-Swift%2Fbadge%3Ftype%3Dplatforms"></a>
    <a href="https://github.com/parse-community/Parse-Swift/actions?query=workflow%3Aci+branch%3Amain"><img alt="CI status" src="https://github.com/parse-community/Parse-Swift/workflows/ci/badge.svg?branch=main"></a>
    <a href="https://github.com/parse-community/Parse-Swift/actions?query=workflow%3Arelease"><img alt="Release status" src="https://github.com/parse-community/Parse-Swift/workflows/release/badge.svg"></a>
    <a href="https://codecov.io/gh/parse-community/Parse-Swift/branches"><img alt="Code coverage" src="https://codecov.io/gh/parse-community/Parse-Swift/branch/main/graph/badge.svg"></a>
    <a href="http://parseplatform.org/Parse-Swift/api/"><img alt="Documentation" src="https://github.com/parse-community/Parse-Swift/blob/gh-pages/api/badge.svg"></a>
    <a href="https://github.com/parse-community/Parse-Swift"><img alt="Dependencies" src="https://img.shields.io/badge/dependencies-0-yellowgreen.svg"></a>
    <a href="https://community.parseplatform.org/"><img alt="Join the conversation" src="https://img.shields.io/discourse/https/community.parseplatform.org/topics.svg"></a>
    <a href="https://cocoapods.org/pods/ParseSwift"><img alt="Cocoapods" src="https://img.shields.io/cocoapods/v/ParseSwift.svg"></a>
</p>
<br>

For more information about the Parse Platform and its features, see the public [documentation][docs]. The ParseSwift SDK is not a port of the [Parse-SDK-iOS-OSX SDK](https://github.com/parse-community/Parse-SDK-iOS-OSX) and though some of it may feel familiar, it is not backwards compatible and is designed with a new philosophy. For more details visit the [api documentation](http://parseplatform.org/Parse-Swift/api/).

To learn how to use or experiment with ParseSwift, you can run and edit the [ParseSwift.playground](https://github.com/parse-community/Parse-Swift/tree/main/ParseSwift.playground/Pages). You can use the parse-server in [this repo](https://github.com/netreconlab/parse-hipaa/tree/parse-swift) which has docker compose files (`docker-compose up` gives you a working server) configured to connect with the playground files, has [Parse Dashboard](https://github.com/parse-community/parse-dashboard), and can be used with mongoDB or PostgreSQL.

## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

You can use The Swift Package Manager (SPM) to install ParseSwift by adding the following description to your `Package.swift` file:

```swift
// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/parse-community/Parse-Swift", from: "1.9.0"),
    ]
)
```
Then run `swift build`. 

You can also install using SPM in your Xcode project by going to 
"Project->NameOfYourProject->Swift Packages" and placing "https://github.com/parse-community/Parse-Swift.git" in the 
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

**Requires: iOS 13.0+, macOS 10.15+, macCatalyst 13.0+, tvOS 13.0+, watchOS 6.0+**

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
let myQuery = GameScore.query("score" > 9)

struct ContentView: View {

    //: A LiveQuery subscription can be used as a view model in SwiftUI
    @ObservedObject var subscription = myQuery.subscribe!
    
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
