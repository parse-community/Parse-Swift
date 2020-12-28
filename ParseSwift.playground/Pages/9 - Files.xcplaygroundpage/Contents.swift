//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift
PlaygroundPage.current.needsIndefiniteExecution = true

initializeParse()

//: Create your own ValueTyped ParseObject
struct GameScore: ParseObject {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties
    var score: Int = 0
    var profilePicture: ParseFile?
    var myData: ParseFile?

    //custom initializer
    init(score: Int) {
        self.score = score
    }

    init(objectId: String?) {
        self.objectId = objectId
    }
}

//: Define initial GameScore
var score = GameScore(score: 52)

//: Set the link online for the file
let linkToFile = URL(string: "https://parseplatform.org/img/logo.svg")!

//: Create a new ParseFile for your picture
let profilePic = ParseFile(name: "profile.svg", cloudURL: linkToFile)

//: Set the pic as part of your ParseObject
score.profilePicture = profilePic

/*: Save asynchronously (preferred way) - Performs work on background
    queue and returns to designated on designated callbackQueue.
    If no callbackQueue is specified it returns to main queue.
*/
score.save { result in
    switch result {
    case .success(let savedScore):
        assert(savedScore.objectId != nil)
        assert(savedScore.createdAt != nil)
        assert(savedScore.updatedAt != nil)
        assert(savedScore.ACL == nil)
        assert(savedScore.score == 52)
        assert(savedScore.profilePicture != nil)

        print("Your profile picture has been successfully saved")

        //: To get the contents updated ParseFile, you need to fetch your GameScore
        savedScore.fetch { result in
            switch result {
            case .success(let fetchedScore):
                guard let picture = fetchedScore.profilePicture else {
                    return
                }
                print("The new name of my saved profilePicture is: \(picture.name)")
                print("All of the details of my profilePicture file is : \(picture)")

                //: If you need to download your profilePicture
                picture.fetch { result in
                    switch result {
                    case .success(let fetchedFile):
                        print("The file is now saved: \(fetchedFile.localURL)")
                    case .failure(let error):
                        assertionFailure("Error fetching: \(error)")
                    }
                }

            case .failure(let error):
                assertionFailure("Error fetching: \(error)")
            }
        }
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: Files can also be saved from data. Below is how to do it synchrously, but async is similar to above
//: Create a new ParseFile for your data
let sampleData = "Hello World".data(using: .utf8)!
let helloFile = ParseFile(name: "hello.txt", data: sampleData)

//: Define another GameScore
var score2 = GameScore(score: 105)
score2.myData = helloFile

//: Save synchronously (not preferred - all operations on main queue)
do {
    let savedScore = try score2.save()
    print("Your hello file has been successfully saved")

    //: To get the contents updated ParseFile, you need to fetch your GameScore
    let fetchedScore = try savedScore.fetch()
    if var myData = fetchedScore.myData {

        print("The new name of my saved data is: \(myData.name)")
        print("All of the details of my data file is : \(myData)")

        //: If you need to download your profilePicture
        let fetchedFile = try myData.fetch()
        if fetchedFile.localURL != nil {
            print("The file is now saved: \(fetchedFile.localURL!)")
        } else {
            assertionFailure("Error fetching: there should be a localURL")
        }
    } else {
        assertionFailure("Error fetching: there should be a localURL")
    }
} catch {
    fatalError("Error saving: \(error)")
}

//: Files can also be saved from files located on your device by using:
//: let localFile = ParseFile(name: "hello.txt", localURL: <#T##URL#>)

//: [Next](@next)
