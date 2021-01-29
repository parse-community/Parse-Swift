//
//  ParseObject+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if !os(Linux)
import Foundation
import Combine

// MARK: Combine
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseObject {

    /**
     Fetches the `ParseUser` *aynchronously* with the current data from the server and sets an error if one occurs.
     Publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
    */
    func fetchPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            fetch(options: options,
                  completion: promise)
        }
    }

    /**
     Saves the `ParseUser` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    func savePublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            save(options: options,
                  completion: promise)
        }
    }

    /**
     Deletes the `ParseUser` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
    func deletePublisher(email: String, options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            delete(options: options, completion: promise)
        }
    }
}

#endif
