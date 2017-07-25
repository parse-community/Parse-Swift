//: Playground - noun: a place where people can play
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

import Parse

struct OtherObject: Parse.Object {
    static var className: String {
        return "MyOtherObject"
    }
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: CodingKey {}
}

struct MyObject: Object {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?

    var aDate: Date?
    var file: File?
    var point: GeoPoint?
    var otherObject: Pointer<OtherObject>?
    var aString: String?
    var aList: [String]?

    enum CodingKeys: String, CodingKey {
        case file, point, otherObject, aDate, aString, aList
    }
}

Parse.initialize(applicationId: "hello", clientKey: "bla", masterKey: "world", serverURL: URL(string: "http://localhost:1337/1")!)

var obj = MyObject()
obj.aDate = Date()
obj.point = GeoPoint(latitude: -10, longitude: -1)
obj.aString = "YO"
obj.otherObject = Pointer(OtherObject(objectId: "Hello", createdAt: nil, updatedAt: nil))
(try? obj.save())?
    .useMasterKey()
    .success {
        print($0)
    }
    .error {
        print($0)
    }
    .execute()

func printString<T>(_ codable: T) where T: Encodable {
    let str = String(data: try! JSONEncoder().encode(codable), encoding: .utf8)!
    print(str)
}

var mutation = obj.mutable
mutation.increment("key", by: 1)
mutation.addUnique("yo", objects: ["mama"])
mutation.addUnique("aList", objects: ["Encodable"], keyPath: \MyObject.aList)

printString(mutation)

var anObject = MyObject()
anObject.aList = ["a", "b", "c"]
printString(anObject)

let keypath = \MyObject.aList

var otherQuery = MyObject.query()

var query: Query<MyObject> = Query("aString" == "YO",
                    "aDate" == Date(),
                    "other" == otherQuery)



query.first()
    .error {
        print($0)
    }
    .success { (res: MyObject?) in
       // print(res)
    }.execute()


otherQuery.count().success({ (val) in
    print("\(val)")
}).execute()
//print(try query.queryString())
// try query.queryString()
