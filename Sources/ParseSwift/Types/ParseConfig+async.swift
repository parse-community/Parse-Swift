//
//  ParseConfig+async.swift
//  ParseConfig+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParseConfig {

    // MARK: Fetchable - Async/Await

    /**
     Fetch the Config *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: The return type of self.
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

    // MARK: Savable - Async/Await

    /**
     Update the Config *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: **true** if saved, **false** if save is unsuccessful.
     - throws: An error of type `ParseError`.
    */
    func save(options: API.Options = []) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            self.save(options: options,
                      completion: continuation.resume)
        }
    }
}

#endif
