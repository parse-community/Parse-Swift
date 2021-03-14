//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

//: Create your own value typed `ParseCloud` type.
struct Cloud: ParseCloud {

    //: Return type of your Cloud Function
    typealias ReturnType = String

    //: These are required for Object
    var functionJobName: String

    //: If your cloud function takes arguments, they can be passed by creating properties:
    //var argument1: [String: Int] = ["test": 5]
}

/*: Assuming you have the Cloud Function named "hello" on your parse-server:
     // main.js
     Parse.Cloud.define('hello', async () => {
       return 'Hello world!';
     });
 */
let cloud = Cloud(functionJobName: "hello")

cloud.runFunction { result in
    switch result {
    case .success(let response):
        print("Response from cloud function: \(response)")
    case .failure(let error):
        assertionFailure("Error calling cloud function: \(error)")
    }
}

//: Jobs can be run the same way by using the method `startJob()`.
PlaygroundPage.current.finishExecution()

//: [Next](@next)
