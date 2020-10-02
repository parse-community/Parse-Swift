//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

//: Create your own ValueTyped ParseObject
struct Book: ParseObject {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties
    var title: String

    init(title: String) {
        self.title = title
    }
}

struct Author: ParseObject {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties
    var name: String
    var book: Book

    init(name: String, book: Book) {
        self.name = name
        self.book = book
    }
}

let newBook = Book(title: "hello")
let author = Author(name: "alice", book: newBook)

author.save { result in
    switch result {
    case .success(let savedAuthorAndBook):
        assert(author.objectId != nil)
        assert(author.createdAt != nil)
        assert(author.updatedAt != nil)
        assert(author.ACL == nil)

        /*: To modify, need to make it a var as the Value Type
            was initialized as immutable
        */
        print("Saved \(savedAuthorAndBook)")
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: [Next](@next)
