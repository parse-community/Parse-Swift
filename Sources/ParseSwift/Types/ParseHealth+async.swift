//
//  ParseHealth+async.swift
//  ParseHealth+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency)
import Foundation

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension ParseHealth {

    // MARK: Async/Await

    /**
     Calls the health check function *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Status of ParseServer.
     - throws: `ParseError`.
    */
    static func check(options: API.Options = []) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Self.check(options: options,
                       completion: continuation.resume)
        }
    }
}

#endif
