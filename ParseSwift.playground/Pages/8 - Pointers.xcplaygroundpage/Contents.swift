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

//: Create your own value typed `ParseObject`.
struct Book: ParseObject {
    //: These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var score: Double?
    var relatedBook: Pointer<Book>?

    //: Your own properties.
    var title: String?
}

//: It's recommended to place custom initializers in an extension
//: to preserve the convenience initializer.
extension Book {

    init(title: String) {
        self.title = title
    }
}

struct Author: ParseObject {
    //: These are required by ParseObject.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var score: Double?

    //: Your own properties.
    var name: String
    var book: Book
    var otherBooks: [Book]?

    init() {
        self.name = "hello"
        self.book = Book()
    }
}

//: It's recommended to place custom initializers in an extension
//: to preserve the convenience initializer.
extension Author {
    init(name: String, book: Book) {
        self.name = name
        self.book = book
    }
}

var newBook = Book(title: "hello")
let author = Author(name: "Alice", book: newBook)

author.save { result in
    switch result {
    case .success(let savedAuthorAndBook):
        assert(savedAuthorAndBook.objectId != nil)
        assert(savedAuthorAndBook.createdAt != nil)
        assert(savedAuthorAndBook.updatedAt != nil)

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
        assert(savedAuthorAndBook.otherBooks?.count == 2)

        //: Notice the pointer objects haven't been updated on the client.
        print("Saved \(savedAuthorAndBook)")

    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: Query for your new saved author
let query1 = Author.query("name" == "Bruce")

query1.first { results in
    switch results {
    case .success(let author):
        print("Found author: \(author)")

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

/*: You will notice in the query above, the fields `book` and `otherBooks` only contain
 arrays consisting of key/value pairs of `objectId`. These are called Pointers
 in `Parse`.
 
 If you want to retrieve the complete object pointed to in `book`, you need to add
 the field names containing the objects specifically in `include` in your query.
*/

/*: Here, we include `book`. If you wanted `book` and `otherBook`, you
 could have used: `.include(["book", "otherBook"])`.
*/
let query2 = Author.query("name" == "Bruce")
    .include("book")

query2.first { results in
    switch results {
    case .success(let author):
        //: Save the book to use later
        newBook = author.book

        print("Found author and included \"book\": \(author)")

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

/*: When you have many fields that are pointing to objects, it may become tedious
 to add all of them to the list. You can quickly retreive all pointer objects by
 using `includeAll`. You can also use `include("*")` to retrieve all pointer
 objects.
*/
let query3 = Author.query("name" == "Bruce")
    .includeAll()

query3.first { results in
    switch results {
    case .success(let author):
        print("Found author and included all: \(author)")

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

//: You can also check if a field is equal to a ParseObject.
do {
    let query4 = try Author.query("book" == newBook)
        .includeAll()

    query4.first { results in
        switch results {
        case .success(let author):
            print("Found author and included all: \(author)")

        case .failure(let error):
            assertionFailure("Error querying: \(error)")
        }
    }
} catch {
    print("\(error)")
}

//: Here's an example of saving Pointers as properties.
do {
    //: First we query
    let query5 = try Author.query("book" == newBook)
        .include("book")

    query5.first { results in
        switch results {
        case .success(let author):
            print("Found author and included \"book\": \(author)")
            //: Setup related books.
            newBook.relatedBook = try? author.otherBooks?.first?.toPointer()

            newBook.save { result in
                switch result {
                case .success(let updatedBook):
                    assert(updatedBook.objectId != nil)
                    assert(updatedBook.createdAt != nil)
                    assert(updatedBook.updatedAt != nil)
                    assert(updatedBook.ACL == nil)
                    assert(updatedBook.relatedBook != nil)

                    print("Saved \(updatedBook)")
                case .failure(let error):
                    assertionFailure("Error saving: \(error)")
                }
            }
        case .failure(let error):
            assertionFailure("Error querying: \(error)")
        }
    }
} catch {
    print("\(error)")
}

//: Here's an example of querying using matchesText.
do {
    let query6 = try Book.query(matchesText(key: "title",
                                            text: "like",
                                            options: [:]))
        .include(["*"])
        .sortByTextScore()

    query6.find { results in
        switch results {
        case .success(let books):
            print("Found books and included all: \(books)")
        case .failure(let error):
            assertionFailure("Error querying: \(error)")
        }
    }
} catch {
    print("\(error)")
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
