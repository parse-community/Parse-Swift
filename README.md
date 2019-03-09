# Parse-Swift
[EXPERIMENTAL] Parse pure Swift SDK

## iOS Usage Guide

After installing ParseSwift, to use it first `import ParseSwift` in your AppDelegate and then add the following code in your `didFinishLaunchingWithOptions`:
```swift
ParseSwift.initialize(applicationId: "xxxxxxxxxx", clientKey: "xxxxxxxxxx", serverURL: URL(string: "https://example.com")!)
```
