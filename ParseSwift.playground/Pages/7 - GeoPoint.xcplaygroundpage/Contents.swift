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
    var location: GeoPoint?
    //: Your own properties
    var score: Int

    //: a custom initializer
    init(score: Int) {
        self.score = score
    }
}

//: Define initial GameScore
var score = GameScore(score: 10)
score.location = GeoPoint(latitude: 40.0, longitude: -30.0)

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
        assert(savedScore.score == 10)
        assert(savedScore.location != nil)

        guard let location = savedScore.location else {
            print("Something went wrong")
            return
        }

        print(location.debugDescription)
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }

}

/*: Define another GameScore. This time we will use current location.
    On your mac, go to "System Preferences -> Security & Privacy -> Privacy"
 click "Location Services" on the left, and then check the box, "Enable Location
 Services". If you don't do this, Xcode can't use your current location
 */
var score2 = GameScore(score: 200)
GeoPoint.currentLocation { result in
    switch result {
    case .success(let location):

        //: Set current location
        score2.location = location

        /*: Save asynchronously (preferred way) - Performs work on background
            queue and returns to designated on designated callbackQueue.
            If no callbackQueue is specified it returns to main queue.
        */
        score2.save { result in
            switch result {
            case .success(let savedScore):
                assert(savedScore.objectId != nil)
                assert(savedScore.createdAt != nil)
                assert(savedScore.updatedAt != nil)
                assert(savedScore.ACL == nil)
                assert(savedScore.score == 200)
                assert(savedScore.location != nil)

                guard let location = savedScore.location else {
                    print("Something went wrong")
                    return
                }

                print(location.debugDescription)
            case .failure(let error):
                assertionFailure("Error saving: \(error)")
            }

        }

    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: Now we will show how to query based on the GeoPoint
let pointToFind = GeoPoint(latitude: 40.0, longitude: -30.0)
var constraints = [QueryConstraint]()
constraints.append(near(key: "location", geoPoint: pointToFind))

let query = GameScore.query(constraints)
query.find(callbackQueue: .main) { results in
    switch results {
    case .success(let scores):

        assert(scores.count >= 1)
        scores.forEach { (score) in
            print("Someone with objectId \"\(score.objectId!)\" has a score of \"\(score.score)\" near me")
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

//: If you only want to query for scores > 50, you can add more constraints
constraints.append("score" > 50)
let query2 = GameScore.query(constraints)
query2.find(callbackQueue: .main) { results in
    switch results {
    case .success(let scores):

        assert(scores.count >= 1)
        scores.forEach { (score) in
            print("""
                Someone with objectId \"\(score.objectId!)\" has a
                score of \"\(score.score)\" near me which is greater than 50
            """)
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

//: [Next](@next)
