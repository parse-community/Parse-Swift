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

do {
    let user = try User.signup(username: "hello10", password: "world")
    var loggedIn = try User.login(username: "hello", password: "workd")
    var acl = user.ACL
    acl?.publicRead = false
    acl?.publicWrite = true
    loggedIn.ACL = acl
    try loggedIn.save()
} catch let error {
    error
    error.localizedDescription
    fatalError("\(e.localizedDescription)")
}

//var acl = ACL()
//acl.publicRead = true
//acl.setReadAccess(userId: "dsas", value: true)
//acl.setWriteAccess(userId: "dsas", value: true)

//: [Next](@next)
