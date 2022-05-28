//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

//: Youe specific _User value type.
struct User: ParseUser {
    //: These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    //: These are required by `ParseUser`.
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?

    //: Your custom keys.
    var customKey: String?

    //: Implement your own version of merge
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.customKey,
                                     original: object) {
            updated.customKey = object.customKey
        }
        return updated
    }
}

//: Create your own value typed `ParseObject`.
struct GameScore2: ParseObject {
    //: These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    //: Your own properties.
    var points: Int?
    var data: ParseBytes?
    var owner: User?

    //: Implement your own version of merge
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points,
                                     original: object) {
            updated.points = object.points
        }
        if updated.shouldRestoreKey(\.data,
                                     original: object) {
            updated.data = object.data
        }
        if updated.shouldRestoreKey(\.owner,
                                     original: object) {
            updated.owner = object.owner
        }
        return updated
    }
}

//: It's recommended to place custom initializers in an extension
//: to preserve the memberwise initializer.
extension GameScore2 {

    init(points: Int) {
        self.points = points
    }

    init(objectId: String?) {
        self.objectId = objectId
    }
}

//: First lets create a new CLP for the new schema.
let clp = ParseCLP(requireAuthentication: true, publicAccess: false)
    .setAccessPublic(true, on: .get)
    .setAccessPublic(true, on: .find)

//: Next we use the CLP to create the new schema and add fields to it.
var gameScoreSchema = ParseSchema<GameScore2>(classLevelPermissions: clp)
    .addField("points",
              type: .number,
              options: ParseFieldOptions<Int>(required: false, defauleValue: nil))
    .addField("data",
              type: .bytes,
              options: ParseFieldOptions<String>(required: false, defauleValue: nil))

do {
    gameScoreSchema = try gameScoreSchema.addField("owner",
                                                   type: .pointer,
                                                   target: User(),
                                                   options: ParseFieldOptions<User>(required: false, defauleValue: nil))
} catch {
    print("Can't add field: \(gameScoreSchema)")
}

//: Now lets create the schema on the server.
gameScoreSchema.create { result in
    switch result {
    case .success(let savedSchema):
        print("Check GameScore2 in Dashboard. \(savedSchema)")
    case .failure(let error):
        print("Couldn't save schema: \(error)")
    }
}

//: We can update the CLP to only allow access to users specified in the "owner" field.
var clp2 = clp.setPointerFields(.get, to: Set(["owner"]))
gameScoreSchema.classLevelPermissions = clp2

//: In addition, we can add an index.
gameScoreSchema = gameScoreSchema.addIndex("myIndex", field: "points", index: 1)

//: Now lets create the schema on the server.
gameScoreSchema.update { result in
    switch result {
    case .success(let savedSchema):
        print("Check GameScore2 in Dashboard. \(savedSchema)")
    case .failure(let error):
        print("Couldn't update schema: \(error)")
    }
}

//: You can fetch your schema from the server at anytime.
gameScoreSchema.fetch { result in
    switch result {
    case .success(let fetchedSchema):
        print("The current schema is: \(fetchedSchema)")
    case .failure(let error):
        print("Couldn't fetch schema: \(error)")
    }
}

//: Now lets save a new object to the new schema.
var gameScore = GameScore2()
gameScore.points = 120
gameScore.owner = User.current

gameScore.save { result in
    switch result {
    case .success(let savedGameScore):
        print("The saved GameScore is: \(savedGameScore)")
    case .failure(let error):
        print("Couldn't save schema: \(error)")
    }
}

//: You can delete all objects your schema by purging them.
gameScoreSchema.purge { result in
    switch result {
    case .success:
        print("All objects have been purged from this schema.")
    case .failure(let error):
        print("Couldn't purge schema: \(error)")
    }
}

/*: As long as there's no data in your `ParseSchema` you can
 delete the schema.
*/
 gameScoreSchema.delete { result in
    switch result {
    case .success:
        print("The schema has been deleted.")
    case .failure(let error):
        print("Couldn't delete the schema: \(error)")
    }
}

//: [Next](@next)
