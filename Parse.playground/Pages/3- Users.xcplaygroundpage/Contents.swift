//: [Previous](@previous)
import PlaygroundSupport
import Foundation
PlaygroundPage.current.needsIndefiniteExecution = true


import Parse
Parse.initialize(applicationId: "applicationId",
                 clientKey: "clientKey",
                 masterKey: "masterKey",
                 serverURL: URL(string: "http://localhost:1337/1")!)

var str = "Hello, playground"


struct User: Parse.UserType {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ACL?

    var username: String?
    var email: String?
    var password: String?

    var customKey: String?
}

var user = User()
user.username = "YO Mamads!bdasdsa"
user.password = "mama!"
user.signup() { (result) in
    guard case .success(var user) = result else {
        if case .error(var error) = result {
            print("ERROR! \(error)")
        }
        assert(false)
        return
    }
    print(user.sessionToken)
    user.customKey = "YAY!"
    user.save() { (result) in
        guard case .success(var user) = result else {
            if case .error(var error) = result {
                print("ERROR! \(error)")
            }
            assert(false)
            return
        }
        print(user)
        print("OK!")
    }
}

//do {
//    try User.signup(username: "hello", password: "world").execute().success({ (user) in
//        print(user)
//    }).error({ (err) in
//        print(err)
//    })
//} catch let e {
//    print(e)
//}

//do {
//    try User.login(username: "hello", password: "world").execute().success({ (user) in
//        print(user)
//    }).error({ (err) in
//        print(err)
//    })
//} catch let e {
//    print(e)
//}

var acl = ACL()
acl.publicRead = true
acl.setReadAccess(userId: "dsas", value: true)
acl.setWriteAccess(userId: "dsas", value: true)

//: [Next](@next)
