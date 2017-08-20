//: [Previous](@previous)
import PlaygroundSupport
import Foundation
PlaygroundPage.current.needsIndefiniteExecution = true

import ParseSwift
initializeParse()

struct User: ParseSwift.UserType {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ACL?

    // provided by User
    var username: String?
    var email: String?
    var password: String?

    // Your custom keys
    var customKey: String?
}

//var user = User()
//user.username = "YO Mamads!bdasdsa"
//user.password = "mama!"
//user.signup() { (result) in
//    guard case .success(var user) = result else {
//        if case .error(var error) = result {
//            print("ERROR! \(error)")
//        }
//        return
//    }
//    print(user.sessionToken)
//    user.customKey = "YAY!"
//    user.save() { (result) in
//        guard case .success(var user) = result else {
//            if case .error(var error) = result {
//                print("ERROR! \(error)")
//            }
//            return
//        }
//        print(user)
//        print("OK!")
//    }
//}

User.signup(username: "hello10", password: "world") { (response) in
    guard case .success(var user) = response else { return }
    print(user)
}

User.login(username: "hello", password: "world") { (response) in
    guard case .success(var user) = response else { return }
    var acl = user.ACL
    acl?.publicRead = false
    acl?.publicWrite = true
    user.ACL = acl
    user.save() { response in
        switch response {
        case .success(let _):
            assert(true)
        case .error(let _):
            assert(false)
        default: break
        }
    }
}

var acl = ACL()
acl.publicRead = true
acl.setReadAccess(userId: "dsas", value: true)
acl.setWriteAccess(userId: "dsas", value: true)

//: [Next](@next)
