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
    //: These are required by ParseObject.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var location: ParseGeoPoint?
    var originalData: Data?

    //: Your own properties
    var points: Int?

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
}

//: Define initial GameScore.
var score = GameScore(points: 10)
do {
    try score.location = ParseGeoPoint(latitude: 40.0, longitude: -30.0)
}

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
        assert(savedScore.points == 10)
        assert(savedScore.location != nil)

        guard let location = savedScore.location else {
            print("Something went wrong")
            return
        }

        print(location)

    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: Now we will show how to query based on the `ParseGeoPoint`.
var query: Query<GameScore> //: Store query for later user
var constraints = [QueryConstraint]()

do {
    let pointToFind = try ParseGeoPoint(latitude: 40.0, longitude: -30.0)
    constraints.append(near(key: "location", geoPoint: pointToFind))

    query = GameScore.query(constraints)
    query.find { results in
        switch results {
        case .success(let scores):

            assert(scores.count >= 1)
            scores.forEach { (score) in
                print("""
                    Someone with objectId \"\(score.objectId!)\"
                    has a points value of \"\(String(describing: score.points))\" near me
                """)
            }

        case .failure(let error):
            assertionFailure("Error querying: \(error)")
        }
    }
}

/*: If you only want to query for points in descending order, use the order enum.
Notice the "var", the query has to be mutable since it is a value type.
*/
var querySorted = query
querySorted.order([.descending("points")])
querySorted.find { results in
    switch results {
    case .success(let scores):

        assert(scores.count >= 1)
        scores.forEach { (score) in
            print("""
                Someone with objectId \"\(score.objectId!)\"
                has a points value of \"\(String(describing: score.points))\" near me
            """)
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

//: If you only want to query for points > 50, you can add more constraints.
constraints.append("points" > 9)
var query2 = GameScore.query(constraints)
query2.find { results in
    switch results {
    case .success(let scores):

        assert(scores.count >= 1)
        scores.forEach { (score) in
            print("""
                Someone with objectId \"\(score.objectId!)\" has a
                points value of \"\(String(describing: score.points))\" near me which is greater than 9
            """)
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

//: If you want to query for points > 50 and whose location is undefined.
var query3 = GameScore.query("points" > 50, doesNotExist(key: "location"))
query3.find { results in
    switch results {
    case .success(let scores):

        scores.forEach { (score) in
            print("""
                Someone has a points value of \"\(String(describing: score.points))\"
                with no geopoint \(String(describing: score.location))
            """)
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

//: If you want to query for points > 50 and whose location is null or undefined.
var anotherQuery3 = GameScore.query("points" > 50, isNull(key: "location"))
anotherQuery3.find { results in
    switch results {
    case .success(let scores):

        scores.forEach { (score) in
            print("""
                Someone has a points value of \"\(String(describing: score.points))\"
                with no geopoint \(String(describing: score.location))
            """)
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

//: If you want to query for points > 9 and whose location is not undefined.
var query4 = GameScore.query("points" > 9, exists(key: "location"))
query4.find { results in
    switch results {
    case .success(let scores):

        assert(scores.count >= 1)
        scores.forEach { (score) in
            print("""
                Someone has a points of \"\(String(describing: score.points))\"
                with geopoint \(String(describing: score.location))
            """)
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

//: If you want to query for points > 9 and whose location is not null or undefined.
var anotherQuery4 = GameScore.query("points" > 9, isNotNull(key: "location"))
anotherQuery4.find { results in
    switch results {
    case .success(let scores):

        assert(scores.count >= 1)
        scores.forEach { (score) in
            print("""
                Someone has a points of \"\(String(describing: score.points))\"
                with geopoint \(String(describing: score.location))
            """)
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

let query5 = GameScore.query("points" == 50)
let query6 = GameScore.query("points" == 200)

var query7 = GameScore.query(or(queries: [query5, query6]))
query7.find { results in
    switch results {
    case .success(let scores):

        scores.forEach { (score) in
            print("""
                Someone has a points value of \"\(String(describing: score.points))\"
                with geopoint using OR \(String(describing: score.location))
            """)
        }

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

//: Find all GameScores.
let query8 = GameScore.query
query8.findAll { result in
    switch result {
    case .success(let scores):
        print(scores)
    case .failure(let error):
        print(error.localizedDescription)
    }
}

do {
    let points: [ParseGeoPoint] = [
        try .init(latitude: 35.0, longitude: -28.0),
        try .init(latitude: 45.0, longitude: -28.0),
        try .init(latitude: 39.0, longitude: -35.0)
    ]
    let query9 = GameScore.query(withinPolygon(key: "location", points: points))
    query9.find { results in
        switch results {
        case .success(let scores):

            scores.forEach { (score) in
                print("""
                    Someone has a points value of \"\(String(describing: score.points))\"
                    with a geolocation \(String(describing: score.location)) within the
                    polygon using points: \(points)
                """)
            }
        case .failure(let error):
            assertionFailure("Error querying: \(error)")
        }
    }
} catch {
    print("Could not create geopoints: \(error)")
}

do {
    let points: [ParseGeoPoint] = [
        try .init(latitude: 35.0, longitude: -28.0),
        try .init(latitude: 45.0, longitude: -28.0),
        try .init(latitude: 39.0, longitude: -35.0)
    ]
    let polygon = try ParsePolygon(points)
    let query10 = GameScore.query(withinPolygon(key: "location", polygon: polygon))
    query10.find { results in
        switch results {
        case .success(let scores):
            scores.forEach { (score) in
                print("""
                    Someone has a points value of \"\(String(describing: score.points))\"
                    with a geolocation \(String(describing: score.location)) within the
                    polygon: \(polygon)
                """)
            }
        case .failure(let error):
            assertionFailure("Error querying: \(error)")
        }
    }
} catch {
    print("Could not create geopoints: \(error)")
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

/*: Explain the previous query. Read the documentation note on `explain`
 queries and use a type-erased wrapper such as AnyCodable.
 */
//let explain: AnyDecodable = try query8.firstExplain()
//print(explain)

PlaygroundPage.current.finishExecution()
//: [Next](@next)
