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
struct Book: ParseObject, ParseQueryScorable {
    //: These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var score: Double?
    var originalData: Data?

    //: Your own properties.
    var title: String?
    var relatedBook: Pointer<Book>?

    /*:
     Optional - implement your own version of merge
     for faster decoding after updating your `ParseObject`.
     */
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.title,
                                     original: object) {
            updated.title = object.title
        }
        if updated.shouldRestoreKey(\.relatedBook,
                                     original: object) {
            updated.relatedBook = object.relatedBook
        }
        return updated
    }
}

/*:
 It's recommended to place custom initializers in an extension
 to preserve the memberwise initializer.
 */
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
    var originalData: Data?

    //: Your own properties.
    var name: String?
    var book: Book?
    var otherBooks: [Book]?

    /*:
     Optional - implement your own version of merge
     for faster decoding after updating your `ParseObject`.
     */
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.name,
                                     original: object) {
            updated.name = object.name
        }
        if updated.shouldRestoreKey(\.book,
                                     original: object) {
            updated.book = object.book
        }
        if updated.shouldRestoreKey(\.otherBooks,
                                     original: object) {
            updated.otherBooks = object.otherBooks
        }
        return updated
    }
}

/*:
 It's recommended to place custom initializers in an extension
 to preserve the memberwise initializer.
 */
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

        print("Saved: \(savedAuthorAndBook)")
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

        /*:
         Notice the pointer objects have not been updated on the
         client.If you want the latest pointer objects, fetch and include them.
         */
        print("Saved: \(savedAuthorAndBook)")

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

/*:
 You will notice in the query above, the fields `book` and `otherBooks` only contain
 arrays consisting of key/value pairs of `objectId`. These are called Pointers
 in `Parse`.
 
 If you want to retrieve the complete object pointed to in `book`, you need to add
 the field names containing the objects specifically in `include` in your query.
*/

/*:
 Here, we include `book`. If you wanted `book` and `otherBook`, you
 could have used: `.include(["book", "otherBook"])`.
*/
let query2 = Author.query("name" == "Bruce")
    .include("book")

query2.first { results in
    switch results {
    case .success(let author):
        //: Save the book to use later
        if let book = author.book {
            newBook = book
        }

        print("Found author and included \"book\": \(author)")

    case .failure(let error):
        assertionFailure("Error querying: \(error)")
    }
}

/*:
 When you have many fields that are pointing to objects, it may become tedious
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
            /*:
             Setup related books. Using `.mergeable` or `set()`
             allows you to only send the updated keys to the
             parse server as opposed to the whole object.
            */
            var modifiedNewBook = newBook.mergeable
            modifiedNewBook.relatedBook = try? author.otherBooks?.first?.toPointer()

            modifiedNewBook.save { result in
                switch result {
                case .success(let updatedBook):
                    assert(updatedBook.objectId != nil)
                    assert(updatedBook.createdAt != nil)
                    assert(updatedBook.updatedAt != nil)
                    assert(updatedBook.relatedBook != nil)

                    print("Saved: \(updatedBook)")
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

//: Batching saves with saved and unsaved pointer items.
var author3 = Author(name: "Logan", book: newBook)
let otherBook3 = Book(title: "I like this book")
let otherBook4 = Book(title: "I like this book also")
author3.otherBooks = [otherBook3, otherBook4]

[author3].saveAll { result in
    switch result {
    case .success(let savedAuthorsAndBook):
        savedAuthorsAndBook.forEach { eachResult in
            switch eachResult {
            case .success(let savedAuthorAndBook):
                assert(savedAuthorAndBook.objectId != nil)
                assert(savedAuthorAndBook.createdAt != nil)
                assert(savedAuthorAndBook.updatedAt != nil)
                assert(savedAuthorAndBook.otherBooks?.count == 2)

                /*:
                 Notice the pointer objects have not been updated on the
                 client.If you want the latest pointer objects, fetch and include them.
                 */
                print("Saved \(savedAuthorAndBook)")
            case .failure(let error):
                assertionFailure("Error saving: \(error)")
            }
        }

    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: Batching saves with unsaved pointer items.
var newBook2 = Book(title: "world")
var author4 = Author(name: "Scott", book: newBook2)
author4.otherBooks = [otherBook3, otherBook4]

[author4].saveAll { result in
    switch result {
    case .success(let savedAuthorsAndBook):
        savedAuthorsAndBook.forEach { eachResult in
            switch eachResult {
            case .success(let savedAuthorAndBook):
                assert(savedAuthorAndBook.objectId != nil)
                assert(savedAuthorAndBook.createdAt != nil)
                assert(savedAuthorAndBook.updatedAt != nil)
                assert(savedAuthorAndBook.otherBooks?.count == 2)
                author4 = savedAuthorAndBook
                /*:
                 Notice the pointer objects have not been updated on the
                 client.If you want the latest pointer objects, fetch and include them.
                 */
                print("Saved: \(savedAuthorAndBook)")
            case .failure(let error):
                assertionFailure("Error saving: \(error)")
            }
        }

    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: Batching saves by updating an already saved object.
author4.fetch { result in
    switch result {
    case .success(var fetchedAuthor):
        print("The latest author: \(fetchedAuthor)")
        fetchedAuthor.name = "R.L. Stine"
        [fetchedAuthor].saveAll { result in
            switch result {
            case .success(let savedAuthorsAndBook):
                savedAuthorsAndBook.forEach { eachResult in
                    switch eachResult {
                    case .success(let savedAuthorAndBook):
                        assert(savedAuthorAndBook.objectId != nil)
                        assert(savedAuthorAndBook.createdAt != nil)
                        assert(savedAuthorAndBook.updatedAt != nil)
                        assert(savedAuthorAndBook.otherBooks?.count == 2)

                        print("Updated: \(savedAuthorAndBook)")
                    case .failure(let error):
                        assertionFailure("Error saving: \(error)")
                    }
                }

            case .failure(let error):
                assertionFailure("Error saving: \(error)")
            }
        }
    case .failure(let error):
        assertionFailure("Error fetching: \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
