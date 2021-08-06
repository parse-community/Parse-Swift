//
//  ParseHealth+async.swift
//  ParseHealth+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5)
import Foundation

@available(macOS 12.0, iOS 15.0, macCatalyst 15.0, watchOS 9.0, tvOS 15.0, *)
public extension ParseHealth {

    // MARK: Async/Await

    /**
     Calls the health check function *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    static func check(options: API.Options = []) async throws -> Result<String, ParseError> {
        try await withCheckedThrowingContinuation { continuation in
            Self.check(options: options,
                       completion: continuation.resume)
        }
    }
}

#endif
