# Parse-Swift
[EXPERIMENTAL] Parse pure Swift SDK

## iOS Usage Guide 

To use ParseSwift first `import ParseSwift` in your AppDelegate and then add the following code in your `didFinishLaunchingWithOptions`:
```swift
ParseSwift.initialize(applicationId: "xxxxxxxxx", clientKey: "xxxxxxxxx", serverURL: URL(string: "https://example.com")!)
```
