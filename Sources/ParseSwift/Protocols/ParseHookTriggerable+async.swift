//
//  ParseHookTriggerable+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/19/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

#if compiler(>=5.5.2) && canImport(_Concurrency)
// MARK: Fetch
public extension ParseHookTriggerable {
    /**
     Fetches the Parse hook trigger *asynchronously*  from the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the fetched `ParseHookTriggerable`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     */
     func fetch(options: API.Options = []) async throws -> Self {
         try await withCheckedThrowingContinuation { continuation in
             self.fetch(options: options,
                        completion: continuation.resume)
         }
     }

    /**
     Fetches all of the Parse hook triggers *asynchronously*  from the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of fetched `ParseHookTriggerable`'s.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     */
     func fetchAll(options: API.Options = []) async throws -> [Self] {
         try await withCheckedThrowingContinuation { continuation in
             self.fetchAll(options: options,
                           completion: continuation.resume)
         }
     }
}

// MARK: Create
public extension ParseHookTriggerable {
    /**
     Creates the Parse hook trigger *asynchronously*  from the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the created `ParseHookTriggerable`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     */
     func create(options: API.Options = []) async throws -> Self {
         try await withCheckedThrowingContinuation { continuation in
             self.create(options: options,
                         completion: continuation.resume)
         }
     }
}

// MARK: Update
public extension ParseHookTriggerable {
    /**
     Updates the Parse hook trigger *asynchronously*  from the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the updated `ParseHookTriggerable`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     */
     func update(options: API.Options = []) async throws -> Self {
         try await withCheckedThrowingContinuation { continuation in
             self.update(options: options,
                         completion: continuation.resume)
         }
     }
}

// MARK: Delete
public extension ParseHookTriggerable {
    /**
     Deletes the Parse hook trigger *asynchronously*  from the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     */
     func delete(options: API.Options = []) async throws {
         let result = try await withCheckedThrowingContinuation { continuation in
             self.delete(options: options,
                         completion: continuation.resume)
         }
         if case let .failure(error) = result {
             throw error
         }
     }
}
#endif
