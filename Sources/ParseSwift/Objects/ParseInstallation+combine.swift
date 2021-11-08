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

public extension ParseInstallation {

    // MARK: Combine
    /**
     Fetches the `ParseInstallation` *aynchronously* with the current data from the server
     and sets an error if one occurs. Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetchPublisher(includeKeys: [String]? = nil,
                        options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.fetch(includeKeys: includeKeys,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Saves the `ParseInstallation` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    func savePublisher(isIgnoreCustomObjectIdConfig: Bool = false,
                       options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.save(isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Deletes the `ParseInstallation` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
    func deletePublisher(options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            self.delete(options: options, completion: promise)
        }
    }
}

public extension Sequence where Element: ParseInstallation {
    /**
     Fetches a collection of installations *aynchronously* with the current data from the server and sets
     an error if one occurs. Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
    */
    func fetchAllPublisher(includeKeys: [String]? = nil,
                           options: API.Options = []) -> Future<[(Result<Self.Element, ParseError>)], ParseError> {
        Future { promise in
            self.fetchAll(includeKeys: includeKeys,
                          options: options,
                          completion: promise)
        }
    }

    /**
     Saves a collection of installations *asynchronously* and publishes when complete.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
    */
    func saveAllPublisher(batchLimit limit: Int? = nil,
                          transaction: Bool = false,
                          isIgnoreCustomObjectIdConfig: Bool = false,
                          options: API.Options = []) -> Future<[(Result<Self.Element, ParseError>)], ParseError> {
        Future { promise in
            self.saveAll(batchLimit: limit,
                         transaction: transaction,
                         isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig,
                         options: options,
                         completion: promise)
        }
    }

    /**
     Deletes a collection of installations *asynchronously* and publishes when complete.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
    */
    func deleteAllPublisher(batchLimit limit: Int? = nil,
                            transaction: Bool = false,
                            options: API.Options = []) -> Future<[(Result<Void, ParseError>)], ParseError> {
        Future { promise in
            self.deleteAll(batchLimit: limit,
                           transaction: transaction,
                           options: options,
                           completion: promise)
        }
    }
}

#endif
