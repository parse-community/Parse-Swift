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

//: Create a value typed `ParseConfig` that matches your server config.
struct Config: ParseConfig {

    //: If your server Config has any parameters their names and types should
    //: match your ParseCondig properties:
    var welcomeMessage: String?
    var winningNumber: Int?
}

/*: Go to your Parse Dashboard and click `Config->Create a parameter`:
    Now add the following parameters:
 - Parameter Name: "welcomeMessage", Type: "String", Value: "Hello".
 - Parameter Name: "winningNumber", Type: "Number", Value: "42".
 */
var config = Config()

config.fetch { result in
    switch result {
    case .success(let currentConfig):
        print("The current config on the server: \(currentConfig)")
    case .failure(let error):
        assertionFailure("Error fetching the config: \(error)")
    }
}

//: We can also update the config.
config.winningNumber = 50

//: Save the update.
config.save { result in
    switch result {
    case .success(let isUpdated):
        if isUpdated {
            print("The current config on the server has been updated.")
        } else {
            print("The current config on the server failed to update.")
        }
    case .failure(let error):
        assertionFailure("Error updating the config: \(error)")
    }
}

//: Fetch the updated config to make sure it's saved.
config.fetch { result in
    switch result {
    case .success(let currentConfig):
        print("The current config on the server: \(currentConfig)")
    case .failure(let error):
        assertionFailure("Error fetching the config: \(error)")
    }
}

//: Anytime you fetch or update your Config successfully, it's automatically saved to your Keychain.
print(Config.current ?? "No config")

PlaygroundPage.current.finishExecution()

//: [Next](@next)
