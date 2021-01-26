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
    <a href="https://github.com/parse-community/Parse-Swift"><img alt="Dependencies" src="https://img.shields.io/badge/dependencies-0-yellowgreen.svg"></a>
    <a href="https://community.parseplatform.org/"><img alt="Join the conversation" src="https://img.shields.io/discourse/https/community.parseplatform.org/topics.svg"></a>
    <a href="https://cocoapods.org/pods/ParseSwift"><img alt="Cocoapods" src="https://img.shields.io/cocoapods/v/ParseSwift.svg"></a>
</p>
<br>

For more information about the Parse Platform and its features, see the public [documentation][docs]. The ParseSwift SDK is not a port of the [Parse-SDK-iOS-OSX SDK](https://github.com/parse-community/Parse-SDK-iOS-OSX) and though some of it may feel familiar, it is not backwards compatible and is designed with a new philosophy. For more details visit the [api documentation](http://parseplatform.org/Parse-Swift/api/).

To learn how to use or experiment with ParseSwift, you can run and edit the [ParseSwift.playground](https://github.com/parse-community/Parse-Swift/tree/main/ParseSwift.playground/Pages). You can use the parse-server in [this repo](https://github.com/netreconlab/parse-hipaa/tree/parse-swift) which has docker compose files (`docker-compose up` gives you a working server) configured to connect with the playground files, has [Parse Dashboard](https://github.com/parse-community/parse-dashboard), and can be used with mongo or postgres.

## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

You can use The Swift Package Manager (SPM) to install ParseSwift by adding the following description to your `Package.swift` file:

```swift
// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/parse-community/Parse-Swift", from: "1.1.2"),
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
ParseSwift.initialize(applicationId: "xxxxxxxxxx", clientKey: "xxxxxxxxxx", serverURL: URL(string: "https://example.com")!, liveQueryServerURL: URL(string: "https://example.com")!, authentication: ((URLAuthenticationChallenge,
(URLSession.AuthChallengeDisposition,
 URLCredential?) -> Void) -> Void))
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

The LiveQuery client interface is based around the concept of `Subscription`s. You can register any `Query` for live updates from the associated live query server, by simply calling `subscribe()` on a query:
```swift
let myQuery = Message.query("from" == "parse")
guard let subscription = myQuery.subscribe else {
    "Error subscribing..."
    return
}
```

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

Handling errors is and other events is similar, take a look at the `Subscription` class for more information.

### Advanced Usage

You are not limited to a single Live Query Client - you can create multiple instances of `ParseLiveQuery`, use certificate authentication and pinning, receive metrics about each client connection, connect to individual server URLs, and more.

[docs]: https://docs.parseplatform.org
