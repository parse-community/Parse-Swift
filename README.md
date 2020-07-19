<p align="center">
    <img alt="Parse Platform" src="logo large.png" width="200">
  </a>
</p>

<h2 align="center">ParseSwift</h2>

<p align="center">
    An experimental pure Swift library that gives you access to the powerful Parse Server backend from your Swift applications.
</p>

<p align="center">
    <a href="https://twitter.com/intent/follow?screen_name=parseplatform"><img alt="Follow on Twitter" src="https://img.shields.io/twitter/follow/parseplatform?style=social&label=Follow"></a>
    <a href=" https://github.com/parse-community/Parse-Swift/blob/master/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-lightgrey.svg"></a>
    <a href="#backers"><img alt="Backers on Open Collective" src="https://opencollective.com/parse-server/backers/badge.svg" /></a>
  <a href="#sponsors"><img alt="Sponsors on Open Collective" src="https://opencollective.com/parse-server/sponsors/badge.svg" /></a>
</p>

<p align="center">
    <a href="https://github.com/parse-community/Parse-Swift"><img alt="Dependencies" src="https://img.shields.io/badge/dependencies-0-yellowgreen.svg"></a>
    <a href="https://travis-ci.org/parse-community/Parse-Swift/branches"><img alt="Build status" src="https://img.shields.io/travis/parse-community/Parse-Swift/master.svg"></a>
    <a href="https://community.parseplatform.org/"><img alt="Join the conversation" src="https://img.shields.io/discourse/https/community.parseplatform.org/topics.svg"></a>
</p>
<br>

For more information about the Parse Platform and its features, see the public [documentation][docs].

## Installation

As there are currently no releases of the ParseSwift SDK you will need to specify either a branch or a specific commit with your chosen package manager. The `master` branch may be unstable and there may be breaking changes.

### [Swift Package Manager](https://swift.org/package-manager/)

You can use The Swift Package Manager to install ParseSwift by adding the following description to your `Package.swift` file:

```swift
// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/parse-community/Parse-Swift.git", .branch("master")"),
    ]
)
```
Then run `swift build`.

### [CocoaPods](https://cocoapods.org)

Add the following line to your Podfile:
```ruby
pod 'ParseSwift', :git => 'https://github.com/parse-community/Parse-Swift', :branch => 'master'
```

Run `pod install`, and you should now have the latest version from the master branch. Please be aware that as this SDK is still in development there may be issues with master.

### [Carthage](https://github.com/carthage/carthage)

Add the following line to your Cartfile:
```
github "parse-community/Parse-Swift" "master"
```
Run `carthage update`, and you should now have the latest version of ParseSwift SDK in your Carthage folder.

## iOS Usage Guide

After installing ParseSwift, to use it first `import ParseSwift` in your AppDelegate.swift and then add the following code in your `application:didFinishLaunchingWithOptions:` method:
```swift
ParseSwift.initialize(applicationId: "xxxxxxxxxx", clientKey: "xxxxxxxxxx", serverURL: URL(string: "https://example.com")!)
```
Please chechout the [Swift Playground](https://github.com/parse-community/Parse-Swift/tree/master/ParseSwift.playground) for more usage information.

[docs]: http://docs.parseplatform.org/ios/guide/
