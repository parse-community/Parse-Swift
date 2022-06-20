//
//  ParseHookFunctionable+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/19/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

#if compiler(>=5.5.2) && canImport(_Concurrency)

// MARK: Fetch
extension ParseHookFunctionable {
    /**
     Fetches the Parse hook function *asynchronously*  from the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     */
     func fetch(options: API.Options = []) async throws -> Self {
         try await withCheckedThrowingContinuation { continuation in
             self.fetch(options: options,
                        completion: continuation.resume)
         }
     }

    /**
     Fetches all of the Parse hook functions *asynchronously*  from the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     */
     func fetchAll(options: API.Options = []) async throws -> [Self] {
         try await withCheckedThrowingContinuation { continuation in
             self.fetchAll(options: options,
                           completion: continuation.resume)
         }
     }
}

// MARK: Create
extension ParseHookFunctionable {
    /**
     Creates the Parse hook function *asynchronously*  from the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     */
     func create(options: API.Options = []) async throws -> Self {
         try await withCheckedThrowingContinuation { continuation in
             self.create(options: options,
                         completion: continuation.resume)
         }
     }
}

// MARK: Update
extension ParseHookFunctionable {
    /**
     Updates the Parse hook function *asynchronously*  from the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     */
     func update(options: API.Options = []) async throws -> Self {
         try await withCheckedThrowingContinuation { continuation in
             self.update(options: options,
                         completion: continuation.resume)
         }
     }
}

// MARK: Delete
extension ParseHookFunctionable {
    /**
     Deletes the Parse hook function *asynchronously*  from the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
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
