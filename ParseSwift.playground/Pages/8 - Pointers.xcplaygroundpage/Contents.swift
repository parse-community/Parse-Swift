//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

//: Create your own value typed `ParseObject`.
struct Book: ParseObject {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties.
    var title: String

    init(title: String) {
        self.title = title
    }
}

struct Author: ParseObject {
    //: Those are required for Object.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties.
    var name: String
    var book: Book
    var otherBooks: [Book]?

    init(name: String, book: Book) {
        self.name = name
        self.book = book
    }
}

let newBook = Book(title: "hello")
let author = Author(name: "Alice", book: newBook)

author.save { result in
    switch result {
    case .success(let savedAuthorAndBook):
        assert(savedAuthorAndBook.objectId != nil)
        assert(savedAuthorAndBook.createdAt != nil)
        assert(savedAuthorAndBook.updatedAt != nil)
        assert(savedAuthorAndBook.ACL == nil)

        /*: To modify, need to make it a var as the value type
            was initialized as immutable.
        */
        print("Saved \(savedAuthorAndBook)")
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: Pointer array.
let otherBook1 = Book(title: "I like this book")
let otherBook2 = Book(title: "I like this book also")
var author2 = Author(name: "Bruce", book: newBook)
author2.otherBooks = [otherBook1, otherBook2]
author2.save { result in
    switch result {
    case .success(let savedAuthorAndBook):
        assert(savedAuthorAndBook.objectId != nil)
        assert(savedAuthorAndBook.createdAt != nil)
        assert(savedAuthorAndBook.updatedAt != nil)
        assert(savedAuthorAndBook.ACL == nil)
        assert(savedAuthorAndBook.otherBooks?.count == 2)

        /*: To modify, need to make it a var as the value type
            was initialized as immutable.
        */
        print("Saved \(savedAuthorAndBook)")
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
