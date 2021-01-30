//
//  ParseInstallation+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

// MARK: Combine
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseInstallation {

    // MARK: Fetchable - Combine
    /**
     Fetches the `ParseInstallation` *aynchronously* with the current data from the server
     and sets an error if one occurs. Publishes when complete.

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

    // MARK: Savable - Combine
    /**
     Saves the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    func savePublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            save(options: options,
                 completion: promise)
        }
    }

    // MARK: Deletable - Combine
    /**
     Deletes the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
    func deletePublisher(options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            delete(options: options, completion: promise)
        }
    }
}

#endif
