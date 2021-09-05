//
//  ParseConfig+async.swift
//  ParseConfig+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5)
import Foundation

@available(macOS 12.0, iOS 15.0, macCatalyst 15.0, watchOS 9.0, tvOS 15.0, *)
public extension ParseConfig {

    // MARK: Fetchable - Async/Await

    /**
     Fetch the Config *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
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
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func save(options: API.Options = []) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            self.save(options: options,
                      completion: continuation.resume)
        }
    }
}

#endif