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
    //: Those are required for Object.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var location: ParseGeoPoint?
    //: Your own properties
    var score: Int?

    //: A custom initializer.
    init(score: Int) {
        self.score = score
    }
}

//: Define initial GameScore.
var score = GameScore(score: 10)
score.location = ParseGeoPoint(latitude: 40.0, longitude: -30.0)

/*: Save asynchronously (preferred way) - performs work on background
    queue and returns to specified callbackQueue.
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

//: Now we will show how to query based on the `ParseGeoPoint`.
let pointToFind = ParseGeoPoint(latitude: 40.0, longitude: -30.0)
var constraints = [QueryConstraint]()
constraints.append(near(key: "location", geoPoint: pointToFind))

let query = GameScore.query(constraints)
query.find { results in
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

/*: If you only want to query for scores in descending order, use the order enum.
Notice the "var", the query has to be mutable since it's a value type.
*/
var querySorted = query
querySorted.order([.descending("score")])
querySorted.find { results in
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

//: If you only want to query for scores > 50, you can add more constraints.
constraints.append("score" > 9)
var query2 = GameScore.query(constraints)
query2.find { results in
    switch results {
    case .success(let scores):

        assert(scores.count >= 1)
        scores.forEach { (score) in
            print("""
                Someone with objectId \"\(score.objectId!)\" has a
                score of \"\(score.score)\" near me which is greater than 9
            """)
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

//: If you want to query for scores > 50 and don't have a `ParseGeoPoint`.
var query3 = GameScore.query("score" > 50, doesNotExist(key: "location"))
query3.find { results in
    switch results {
    case .success(let scores):

        scores.forEach { (score) in
            print("""
                Someone has a score of \"\(score.score)\" with no geopoint \(String(describing: score.location))
            """)
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

//: If you want to query for scores > 9 and have a `ParseGeoPoint`.
var query4 = GameScore.query("score" > 9, exists(key: "location"))
query4.find { results in
    switch results {
    case .success(let scores):

        assert(scores.count >= 1)
        scores.forEach { (score) in
            print("""
                Someone has a score of \"\(score.score)\" with geopoint \(String(describing: score.location))
            """)
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

let query5 = GameScore.query("score" == 50)
let query6 = GameScore.query("score" == 200)

var query7 = GameScore.query(or(queries: [query5, query6]))
query7.find { results in
    switch results {
    case .success(let scores):

        scores.forEach { (score) in
            print("""
                Someone has a score of \"\(score.score)\" with geopoint using OR \(String(describing: score.location))
            """)
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

//: Find all GameScores.
let query8 = GameScore.query()
query8.findAll { result in
    switch result {
    case .success(let scores):
        print(scores)
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//: Hint of the previous query (asynchronous)
query2 = query2.hint("_id_")
query2.find { result in
    switch result {
    case .success(let scores):
        print(scores)
    case .failure(let error):
        print(error.localizedDescription)
    }
}

//: Explain the previous query.
let explain: AnyDecodable = try query8.firstExplain()
print(explain)

PlaygroundPage.current.finishExecution()
//: [Next](@next)
