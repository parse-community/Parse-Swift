# Parse-Swift
[EXPERIMENTAL] Parse pure Swift SDK

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
Please chechout the [Swift Playground]() for more usage information.
