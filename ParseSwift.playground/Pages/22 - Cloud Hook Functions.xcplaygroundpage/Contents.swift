//: [Previous](@previous)

/*:
 The code in this Playground is intended to run at the
 server level only. It is not intended to be run in client
 applications as it requires the use of the master key.
 */

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

/*:
 Parse Hook Functions can be created by conforming to
 `ParseHookFunctionable`.
 */
struct MyHookFunction: ParseHookFunctionable {
    var functionName: String?
    var url: URL?
    var warning: String?
}

/*:
 Lets create our first Hook function by first creating an instance
 with the name of the function and url for the hook.
 */
var myFunction = MyHookFunction(name: "foo",
                                url: URL(string: "https://api.example.com/foo"))

//: Then, create the function on the server.
myFunction.create { result in
    switch result {
    case .success(let newFunction):
        print("Created: \"\(newFunction)\"")
    case .failure(let error):
        print("Could not create: \(error)")
    }
}

/*:
 The function can be fetched at any time.
 */
myFunction.fetch { result in
    switch result {
    case .success(let fetchedFunction):
        print("Fetched: \"\(fetchedFunction)\"")
    case .failure(let error):
        print("Could not fetch: \(error)")
    }
}

/*:
 There will be times you need to update a Hook function.
 You can update your hook at anytime.
 */
myFunction.url = URL(string: "https://api.example.com/bar")
myFunction.update { result in
    switch result {
    case .success(let updated):
        print("Updated: \"\(updated)\"")
    case .failure(let error):
        print("Could not update: \(error)")
    }
}

/*:
 Lets fetchAll using the instance method to see all of the
 available hook functions.
 */
myFunction.fetchAll { result in
    switch result {
    case .success(let functions):
        print("Current: \"\(functions)\"")
    case .failure(let error):
        print("Could not fetch: \(error)")
    }
}

/*:
 Hook functions can also be deleted.
 */
myFunction.delete { result in
    switch result {
    case .success:
        print("The Parse Cloud function was deleted successfully")
    case .failure(let error):
        print("Could not delete: \(error)")
    }
}

/*:
 You can also use the fetchAll type method to fetch all of
 the current Hook functions.
 */
MyHookFunction.fetchAll { result in
    switch result {
    case .success(let functions):
        print("Current: \"\(functions)\"")
    case .failure(let error):
        print("Could not fetch: \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
