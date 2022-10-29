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

    /*:
     Optional - implement your own version of merge
     for faster decoding after updating your `ParseObject`.
     */
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
    var level: Int?
    var data: ParseBytes?
    var owner: User?
    var rivals: [User]?

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
        if updated.shouldRestoreKey(\.level,
                                     original: object) {
            updated.level = object.level
        }
        if updated.shouldRestoreKey(\.data,
                                     original: object) {
            updated.data = object.data
        }
        if updated.shouldRestoreKey(\.owner,
                                     original: object) {
            updated.owner = object.owner
        }
        if updated.shouldRestoreKey(\.rivals,
                                     original: object) {
            updated.rivals = object.rivals
        }
        return updated
    }
}

//: First lets create a new CLP for the new schema.
let clp = ParseCLP(requiresAuthentication: true, publicAccess: false)
    .setAccessPublic(true, on: .get)
    .setAccessPublic(true, on: .find)

//: Next we use the CLP to create the new schema and add fields to it.
var gameScoreSchema = ParseSchema<GameScore2>(classLevelPermissions: clp)
    .addField("points",
              type: .number,
              options: ParseFieldOptions<Int>(required: false, defauleValue: nil))
    .addField("level",
              type: .number,
              options: ParseFieldOptions<Int>(required: false, defauleValue: nil))
    .addField("data",
              type: .bytes,
              options: ParseFieldOptions<String>(required: false, defauleValue: nil))

do {
    gameScoreSchema = try gameScoreSchema
        .addField("owner",
                  type: .pointer,
                  options: ParseFieldOptions<User>(required: false, defauleValue: nil))
        .addField("rivals",
                  type: .array,
                  options: ParseFieldOptions<[User]>(required: false, defauleValue: nil))
} catch {
    print("Cannot add field: \(gameScoreSchema)")
}

//: Now lets create the schema on the server.
gameScoreSchema.create { result in
    switch result {
    case .success(let savedSchema):
        print("Check GameScore2 in Dashboard. \nThe created schema:  \(savedSchema)")
    case .failure(let error):
        print("Could not save schema: \(error)")
    }
}

//: We can update the CLP to only allow access to users specified in the "owner" field.
let clp2 = clp.setPointerFields(Set(["owner"]), on: .get)
gameScoreSchema.classLevelPermissions = clp2

//: In addition, we can add an index.
gameScoreSchema = gameScoreSchema.addIndex("myIndex", field: "level", index: 1)

//: Next, we need to update the schema on the server with the changes.
gameScoreSchema.update { result in
    switch result {
    case .success(let updatedSchema):
        print("Check GameScore2 in Dashboard. \nThe updated schema: \(updatedSchema)")
        /*:
         Updated the current gameScoreSchema with the newest.
         */
        gameScoreSchema = updatedSchema
    case .failure(let error):
        print("Could not update schema: \(error)")
    }
}

//: Indexes can also be deleted.
gameScoreSchema = gameScoreSchema.deleteIndex("myIndex")

//: Next, we need to update the schema on the server with the changes.
gameScoreSchema.update { result in
    switch result {
    case .success(let updatedSchema):
        print("Check GameScore2 in Dashboard. \nThe updated schema: \(updatedSchema)")
        /*:
         Updated the current gameScoreSchema with the newest.
         */
        gameScoreSchema = updatedSchema
    case .failure(let error):
        print("Could not update schema: \(error)")
    }
}

//: We can also fetch the schema.
gameScoreSchema.fetch { result in
    switch result {
    case .success(let fetchedGameScore):
        print("The fetched GameScore2 schema is: \(fetchedGameScore)")
    case .failure(let error):
        print("Could not fetch schema: \(error)")
    }
}

/*:
 Fields can also be deleted on a schema. Lets remove
 the **data** field since it is not going being used.
*/
gameScoreSchema = gameScoreSchema.deleteField("data")

//: Next, we need to update the schema on the server with the changes.
gameScoreSchema.update { result in
    switch result {
    case .success(let updatedSchema):
        print("Check GameScore2 in Dashboard. \nThe updated schema: \(updatedSchema)")
        /*:
         Updated the current gameScoreSchema with the newest.
         */
        gameScoreSchema = updatedSchema
    case .failure(let error):
        print("Could not update schema: \(error)")
    }
}

/*:
 Sets of fields can also be protected from access. Lets protect
 some fields from access.
*/
var clp3 = gameScoreSchema.classLevelPermissions
clp3 = clp3?
    .setProtectedFieldsPublic(["owner"])
    .setProtectedFields(["level"], userField: "rivals")
gameScoreSchema.classLevelPermissions = clp3

//: Next, we need to update the schema on the server with the changes.
gameScoreSchema.update { result in
    switch result {
    case .success(let updatedSchema):
        print("Check GameScore2 in Dashboard. \nThe updated schema: \(updatedSchema)")
        /*:
         Updated the current gameScoreSchema with the newest.
         */
        gameScoreSchema = updatedSchema
    case .failure(let error):
        print("Could not update schema: \(error)")
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
        print("Could not save schema: \(error)")
    }
}

//: You can delete all objects your schema by purging them.
gameScoreSchema.purge { result in
    switch result {
    case .success:
        print("All objects have been purged from this schema.")
    case .failure(let error):
        print("Could not purge schema: \(error)")
    }
}

/*:
 As long as there is no data in your `ParseSchema` you can
 delete the schema.
*/
 gameScoreSchema.delete { result in
    switch result {
    case .success:
        print("The schema has been deleted.")
    case .failure(let error):
        print("Could not delete the schema: \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
