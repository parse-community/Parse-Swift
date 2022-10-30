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
    var scores: ParseRelation<Self>?

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

struct Role<RoleUser: ParseUser>: ParseRole {

    //: Required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    //: Provided by Role.
    var name: String?

    //: Custom properties.
    var subtitle: String

    /*:
     Optional - implement your own version of merge
     for faster decoding after updating your `ParseObject`.
     */
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.subtitle,
                                     original: object) {
            updated.subtitle = object.subtitle
        }
        return updated
    }
}

//: Create your own value typed `ParseObject`.
struct GameScore: ParseObject {
    //: These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    //: Your own properties.
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

    init(points: Int) {
        self.points = points
    }
}

//: Roles can provide additional access/security to your apps.

//: This variable will store the saved role.
var savedRole: Role<User>?

//: Now we will create the Role.
guard let currentUser = User.current else {
    fatalError("User currently is not signed in")
}

//: Every Role requires an ACL that cannot be changed after saving.
var acl = ParseACL()
acl.setReadAccess(user: currentUser, value: true)
acl.setWriteAccess(user: currentUser, value: true)

do {
    //: Create the actual Role with a name and ACL.
    var adminRole = try Role<User>(name: "Administrator", acl: acl)
    adminRole.subtitle = "staff"
    adminRole.save { result in
        switch result {
        case .success(let saved):
            print("The role saved successfully: \(saved)")
            print("Check your \"Role\" class in Parse Dashboard.")

            //: Store the saved role so we can use it later...
            savedRole = saved

        case .failure(let error):
            print("Error saving role: \(error)")
        }
    }
} catch {
    print("Error: \(error)")
}

//: Lets check to see if our Role has saved.
if savedRole != nil {
    print("We have a saved Role")
}

//: Users can be added to our previously saved Role.
do {
    //: `ParseRoles` have `ParseRelations` that relate them either `ParseUser` and `ParseRole` objects.
    //: The `ParseUser` relations can be accessed using `users`. We can then add `ParseUser`'s to the relation.
    try savedRole!.users?.add([User.current!]).save { result in
        switch result {
        case .success(let saved):
            print("The role saved successfully: \(saved)")
            print("Check \"users\" field in your \"Role\" class in Parse Dashboard.")

        case .failure(let error):
            print("Error saving role: \(error)")
        }
    }

} catch {
    print("Error: \(error)")
}

/*:
 To retrieve the users who are all Administrators,
 we need to query the relation.
 */
do {
    let query: Query<User>? = try savedRole!.users?.query()
    query?.find { result in
        switch result {
        case .success(let relatedUsers):
            print("""
                The following users are part of the
                \"\(String(describing: savedRole!.name)) role: \(relatedUsers)
            """)

        case .failure(let error):
            print("Error querying role: \(error)")
        }
    }
} catch {
    print(error)
}

//: Of course, you can remove users from the roles as well.
do {
    try savedRole!.users?.remove([User.current!]).save { result in
        switch result {
        case .success(let saved):
            print("The role removed successfully: \(saved)")
            print("Check \"users\" field in your \"Role\" class in Parse Dashboard.")

        case .failure(let error):
            print("Error saving role: \(error)")
        }
    }
} catch {
    print(error)
}

/*:
 Additional roles can be created and tied to already created roles.
 Lets create a "Member" role.
*/
//: This variable will store the saved role.
var savedRoleModerator: Role<User>?

do {
    //: Create the actual Role with a name and ACL.
    let memberRole = try Role<User>(name: "Member", acl: acl)
    memberRole.save { result in
        switch result {
        case .success(let saved):
            print("The role saved successfully: \(saved)")
            print("Check your \"Role\" class in Parse Dashboard.")

            //: Store the saved role so we can use it later...
            savedRoleModerator = saved

        case .failure(let error):
            print("Error saving role: \(error)")
        }
    }
} catch {
    print("Error: \(error)")
}

//: Lets check to see if our Role has saved
if savedRoleModerator != nil {
    print("We have a saved Role")
}

//: Roles can be added to our previously saved Role.
do {
    /*:
     `ParseRoles` have `ParseRelations` that relate them either
     `ParseUser` and `ParseRole` objects. The `ParseUser`
     relations can be accessed using `users`. We can then add
     `ParseUser`'s to the relation.
     */
    try savedRole!.roles?.add([savedRoleModerator!]).save { result in
        switch result {
        case .success(let saved):
            print("The role saved successfully: \(saved)")
            print("Check \"roles\" field in your \"Role\" class in Parse Dashboard.")

        case .failure(let error):
            print("Error saving role: \(error)")
        }
    }
} catch {
    print("Error: \(error)")
}

/*:
 To retrieve the users who are all Administrators,
 we need to query the relation. This time we will
 use a helper query from `ParseRole`.
 */
do {
    try savedRole!.queryRoles().find { result in
        switch result {
        case .success(let relatedRoles):
            print("""
                The following roles are part of the
                \"\(String(describing: savedRole!.name)) role: \(relatedRoles)
            """)

        case .failure(let error):
            print("Error querying role: \(error)")
        }
    }
} catch {
    print("Error: \(error)")
}

//: Of course, you can remove users from the roles as well.
do {
    try savedRole!.roles?.remove([savedRoleModerator!]).save { result in
        switch result {
        case .success(let saved):
            print("The role removed successfully: \(saved)")
            print("Check the \"roles\" field in your \"Role\" class in Parse Dashboard.")

        case .failure(let error):
            print("Error saving role: \(error)")
        }
    }
} catch {
    print(error)
}

/*:
 Using this relation, you can create one-to-many relationships
 with other `ParseObjecs`, similar to `users` and `roles`. All
 `ParseObject`s have a `ParseRelation` attribute that be used on
 instances. For example, the User has:
 */
var relation = User.current!.relation
let score1 = GameScore(points: 53)
let score2 = GameScore(points: 57)

//: Add new child relationships.
[score1, score2].saveAll { result in
    switch result {
    case .success(let savedScores):
        //: Make an array of all scores that were properly saved.
        let scores = savedScores.compactMap { try? $0.get() }
        do {
            guard let newRelations = try relation?.add("scores", objects: scores) else {
                print("Error: should have unwrapped relation")
                return
            }
            newRelations.save { result in
                switch result {
                case .success(let saved):
                    print("The relation saved successfully: \(saved)")
                    print("Check \"points\" field in your \"_User\" class in Parse Dashboard.")

                case .failure(let error):
                    print("Error saving role: \(error)")
                }
            }
        } catch {
            print(error)
        }
    case .failure(let error):
        print("Could not save scores. \(error)")
    }
}

//: You can also do
// let specificRelation = User.current!.relation("scores", className: "GameScore")
do {
    let specificRelation = try User.current!.relation("scores", child: score1)
    try (specificRelation.query() as Query<GameScore>).find { result in
        switch result {
        case .success(let scores):
            print("Found related scores: \(scores)")
        case .failure(let error):
            print("Error querying scores: \(error)")
        }
    }
} catch {
    print(error)
}

//: In addition, you can leverage the child to find scores related to the parent.
do {
    try GameScore.queryRelations("scores", parent: User.current!).find { result in
        switch result {
        case .success(let scores):
            print("Found related scores from child: \(scores)")
        case .failure(let error):
            print("Error querying scores from child: \(error)")
        }
    }
} catch {
    print(error)
}

//: Now we will see how to use the stored `ParseRelation on` property in User to create query
//: all of the relations to `scores`.
var updatedCurrentUser: User
do {
    //: Fetch the updated user since the previous relations were created on the server.
    updatedCurrentUser = try User.current!.fetch()
    print("Updated current user with relation: \(updatedCurrentUser)")
} catch {
    updatedCurrentUser = User.current!
    print("\(error.localizedDescription)")
}

do {
    let usableStoredRelation = try updatedCurrentUser.relation(updatedCurrentUser.scores, key: "scores")
    try (usableStoredRelation.query() as Query<GameScore>).find { result in
        switch result {
        case .success(let scores):
            print("Found related scores from stored ParseRelation: \(scores)")
        case .failure(let error):
            print("Error querying scores from stored ParseRelation: \(error)")
        }
    }
} catch {
    print("\(error.localizedDescription)")
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
