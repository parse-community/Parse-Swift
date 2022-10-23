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

//: Create your own value typed `ParseObject`.
struct GameScore: ParseObject {
    //: These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    //: Your own properties.
    var points: Int? = 0
    var profilePicture: ParseFile?
    var myData: ParseFile?
    var otherPhoto: GamePhoto?

    /*:
     Optional - implement your own version of merge
     for faster decoding after updating your `ParseObject`.
     */
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points,
                                     original: object) {
            updated.points = object.points
        }
        if updated.shouldRestoreKey(\.profilePicture,
                                     original: object) {
            updated.profilePicture = object.profilePicture
        }
        if updated.shouldRestoreKey(\.myData,
                                     original: object) {
            updated.myData = object.myData
        }
        if updated.shouldRestoreKey(\.otherPhoto,
                                     original: object) {
            updated.otherPhoto = object.otherPhoto
        }
        return updated
    }
}

//: It's recommended to place custom initializers in an extension
//: to preserve the memberwise initializer.
extension GameScore {
    //: Custom initializer.
    init(points: Int) {
        self.points = points
    }

    init(objectId: String?) {
        self.objectId = objectId
    }
}

struct GamePhoto: ParseObject {
    //: These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    //: Your own properties.
    var image: ParseFile?
}

//: Define initial GameScore.
var score = GameScore(points: 52)

//: Set the link online for the file.
let linkToFile = URL(string: "https://parseplatform.org/img/logo.svg")!

//: Create a new `ParseFile` for your picture.
let profilePic = ParseFile(name: "profile.svg", cloudURL: linkToFile)

//: Set the picture as part of your ParseObject
score.profilePicture = profilePic

//: Set the picture in a nested ParseObject
var photo = GamePhoto()
photo.image = profilePic
score.otherPhoto = photo

/*:
 Save asynchronously (preferred way) - Performs work on background
 queue and returns to specified callbackQueue.
 If no callbackQueue is specified it returns to main queue.
*/
score.save { result in
    switch result {
    case .success(let savedScore):
        assert(savedScore.objectId != nil)
        assert(savedScore.createdAt != nil)
        assert(savedScore.updatedAt != nil)
        assert(savedScore.points == 52)
        assert(savedScore.profilePicture != nil)

        print("Your profile picture has been successfully saved")

        //: To get the contents updated `ParseFile`, you need to fetch your GameScore.
        savedScore.fetch { result in
            switch result {
            case .success(let fetchedScore):
                guard let picture = fetchedScore.profilePicture,
                      let url = fetchedScore.profilePicture?.url else {
                    return
                }
                print("The new name of your saved profilePicture is: \(picture.name)")
                print("The profilePicture is saved to your Parse Server at: \(url)")
                print("The full details of your profilePicture ParseFile are: \(picture)")

                //: If you need to download your profilePicture
                picture.fetch { result in
                    switch result {
                    case .success(let fetchedFile):
                        print("The file is now saved on your device at: \(String(describing: fetchedFile.localURL))")
                        print("The full details of your profilePicture ParseFile are: \(fetchedFile)")
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

/*:
 Files can also be saved from data. Below is how to do it synchronously, but async is similar to above
 Create a new `ParseFile` for your data.
 */
let sampleData = "Hello World".data(using: .utf8)!
let helloFile = ParseFile(name: "hello.txt", data: sampleData)

//: Define another GameScore.
var score2 = GameScore(points: 105)
score2.myData = helloFile

//: Save synchronously (not preferred - all operations on current queue).
do {
    let savedScore = try score2.save()
    print("Your hello file has been successfully saved")

    //: To get the contents updated `ParseFile`, you need to fetch your GameScore.
    let fetchedScore = try savedScore.fetch()
    if let myData = fetchedScore.myData {

        guard let url = myData.url else {
            fatalError("Error: file should have url.")
        }
        print("The new name of your saved data is: \(myData.name)")
        print("The file is saved to your Parse Server at: \(url)")
        print("The full details of your data file are: \(myData)")

        //: If you need to download your file.
        let fetchedFile = try myData.fetch()
        if fetchedFile.localURL != nil {
            print("The file is now saved at: \(fetchedFile.localURL!)")
            print("The full details of your data ParseFile are: \(fetchedFile)")

            /*:
             If you want to use the data from the file to display the text file or image, you need to retreive
             the data from the file.
            */
            guard let dataFromParseFile = try? Data(contentsOf: fetchedFile.localURL!) else {
                fatalError("Error: Could not get data from file.")
            }

            //: Checking to make sure the data saved on the Parse Server is the same as the original
            if dataFromParseFile != sampleData {
                assertionFailure("Data is not the same. Something went wrong.")
            }

            guard let parseFileString = String(data: dataFromParseFile, encoding: .utf8) else {
                fatalError("Error: Could not create String from data.")
            }
            print("The data saved on parse is: \"\(parseFileString)\"")
        } else {
            assertionFailure("Error fetching: there should be a localURL")
        }
    } else {
        assertionFailure("Error fetching: there should be a localURL")
    }
} catch {
    fatalError("Error saving: \(error)")
}

/*:
 Files can also be saved from files located on your device by using:
 let localFile = ParseFile(name: "hello.txt", localURL: URL).
*/

PlaygroundPage.current.finishExecution()
//: [Next](@next)
