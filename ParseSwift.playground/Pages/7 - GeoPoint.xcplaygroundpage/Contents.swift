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
    var ACL: ACL?
    var location: GeoPoint?
    //: Your own properties
    var score: Int

    //: A custom initializer
    init(score: Int) {
        self.score = score
    }
}

//: Define initial GameScore
var score = GameScore(score: 10)
score.location = GeoPoint(latitude: 40.0, longitude: -30.0)

/*: Save asynchronously (preferred way) - performs work on background
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

/*: If you only want to query for scores in descending order, use the order enum.
Notice the "var", the query has to be mutable since it's a valueType.
*/
var querySorted = query
querySorted.order([.descending("score")])
querySorted.find(callbackQueue: .main) { results in
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
var query2 = GameScore.query(constraints)
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

//: If you want to query for scores > 50 and don't have a GeoPoint
var query3 = GameScore.query("score" > 50, doesNotExist(key: "location"))
query3.find(callbackQueue: .main) { results in
    switch results {
    case .success(let scores):

        assert(scores.count >= 1)
        scores.forEach { (score) in
            print("""
                Someone has a score of \"\(score.score)\" with no geopoint \(String(describing: score.location))
            """)
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

//: If you want to query for scores > 50 and have a GeoPoint
var query4 = GameScore.query("score" > 10, exists(key: "location"))
query4.find(callbackQueue: .main) { results in
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
query7.find(callbackQueue: .main) { results in
    switch results {
    case .success(let scores):

        assert(scores.count >= 1)
        scores.forEach { (score) in
            print("""
                Someone has a score of \"\(score.score)\" with geopoint using OR \(String(describing: score.location))
            """)
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

//: Explain the previous query
let explain = try query2.find(explain: true)
print(explain)

let hint = try query2.find(explain: false, hint: "objectId")
print(hint)

//: [Next](@next)
