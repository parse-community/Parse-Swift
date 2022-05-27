//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

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

    //: Implement your own version of merge
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

//: Now lets create the schema on the server.
gameScoreSchema.create { result in
    switch result {
    case .success(let savedSchema):
        print("Check GameScore2 in Dashboard. \(savedSchema)")
    case .failure(let error):
        print("Couldn't save schema: \(error)")
    }
}

//: [Next](@next)
