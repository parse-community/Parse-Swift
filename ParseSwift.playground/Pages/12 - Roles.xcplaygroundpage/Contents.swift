//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

struct User: ParseUser {
    //: These are required for ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: These are required for ParseUser
    var username: String?
    var email: String?
    var password: String?
    var authData: [String: [String: String]?]?

    //: Your custom keys
    var customKey: String?
}

struct Role<RoleUser: ParseUser>: ParseRole {

    // required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    // provided by Role
    var name: String

    init() {
        self.name = ""
    }
}

//: Roles can provide additional access/security to your apps.

//: This variable will store the saved role
var savedRole: Role<User>?

//: Now we will create the Role.
if let currentUser = User.current {

    //: Every Role requires an ACL that can't be changed after saving.
    var acl = ParseACL()
    acl.setReadAccess(user: currentUser, value: true)
    acl.setWriteAccess(user: currentUser, value: true)

    do {
        //: Create the actual Role with a name and ACL.
        var adminRole = try Role<User>(name: "Administrator", acl: acl)
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

//: Lets check to see if our Role has saved
if savedRole != nil {
    print("We have a saved Role")
}

//: Users can be added to our previously saved Role.
do {
    //try savedRole!.addUsers([User.current!])
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

PlaygroundPage.current.finishExecution()

//: [Next](@next)
