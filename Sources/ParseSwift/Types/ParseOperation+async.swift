//
//  ParseOperation+async.swift
//  ParseOperation+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency)
import Foundation

public extension ParseOperation {

    // MARK: Async/Await

    /**
     Saves the operations on the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A saved `ParseFile`.
     - throws: An error of type `ParseError`.
    */
    func save(options: API.Options = []) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            self.save(options: options,
                      completion: continuation.resume)
        }
    }
}

#endif
