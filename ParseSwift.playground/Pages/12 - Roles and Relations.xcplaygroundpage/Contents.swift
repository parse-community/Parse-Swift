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
    //: These are required for `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: These are required for `ParseUser`.
    var username: String?
    var email: String?
    var password: String?
    var authData: [String: [String: String]?]?

    //: Your custom keys.
    var customKey: String?
}

struct Role<RoleUser: ParseUser>: ParseRole {

    //: Required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Provided by Role.
    var name: String

    init() {
        self.name = ""
    }
}

//: Roles can provide additional access/security to your apps.

//: This variable will store the saved role.
var savedRole: Role<User>?

//: Now we will create the Role.
if let currentUser = User.current {

    //: Every Role requires an ACL that can't be changed after saving.
    var acl = ParseACL()
    acl.setReadAccess(user: currentUser, value: true)
    acl.setWriteAccess(user: currentUser, value: true)

    do {
        //: Create the actual Role with a name and ACL.
        let adminRole = try Role<User>(name: "Administrator", acl: acl)
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
}

//: Lets check to see if our Role has saved.
if savedRole != nil {
    print("We have a saved Role")
}

//: Users can be added to our previously saved Role.
do {
    //: `ParseRoles` have `ParseRelations` that relate them either `ParseUser` and `ParseRole` objects.
    //: The `ParseUser` relations can be accessed using `users`. We can then add `ParseUser`'s to the relation.
    try savedRole!.users.add([User.current!]).save { result in
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

//: To retrieve the users who are all Administrators, we need to query the relation.
let templateUser = User()
do {
    try savedRole!.users.query(templateUser).find { result in
        switch result {
        case .success(let relatedUsers):
            print("The following users are part of the \"\(savedRole!.name) role: \(relatedUsers)")

        case .failure(let error):
            print("Error saving role: \(error)")
        }
    }
} catch {
    print(error)
}

//: Of course, you can remove users from the roles as well.
do {
    try savedRole!.users.remove([User.current!]).save { result in
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

//: Additional roles can be created and tied to already created roles. Lets create a "Member" role.

//: This variable will store the saved role.
var savedRoleModerator: Role<User>?

//: We need another ACL.
var acl = ParseACL()
acl.setReadAccess(user: User.current!, value: true)
acl.setWriteAccess(user: User.current!, value: false)

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
    //: `ParseRoles` have `ParseRelations` that relate them either `ParseUser` and `ParseRole` objects.
    //: The `ParseUser` relations can be accessed using `users`. We can then add `ParseUser`'s to the relation.
    try savedRole!.roles.add([savedRoleModerator!]).save { result in
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

//: To retrieve the users who are all Administrators, we need to query the relation.
//: This time we will use a helper query from `ParseRole`.
savedRole!.queryRoles?.find { result in
    switch result {
    case .success(let relatedRoles):
        print("The following roles are part of the \"\(savedRole!.name) role: \(relatedRoles)")

    case .failure(let error):
        print("Error saving role: \(error)")
    }
}

//: Of course, you can remove users from the roles as well.
do {
    try savedRole!.roles.remove([savedRoleModerator!]).save { result in
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

//: All `ParseObject`s have a `ParseRelation` attribute that be used on instances.
//: For example, the User has:
let relation = User.current!.relation

//: Example: relation.add(<#T##users: [ParseUser]##[ParseUser]#>)
//: Example: relation.remove(<#T##key: String##String#>, objects: <#T##[ParseObject]#>)

//: Using this relation, you can create many-to-many relationships with other `ParseObjecs`,
//: similar to `users` and `roles`.

PlaygroundPage.current.finishExecution()

//: [Next](@next)
