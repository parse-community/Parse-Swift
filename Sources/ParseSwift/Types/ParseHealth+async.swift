//
//  ParseHealth+async.swift
//  ParseHealth+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParseHealth {

    // MARK: Async/Await

    /**
     Calls the health check function *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Status of ParseServer.
     - throws: An error of type `ParseError`.
    */
    static func check(options: API.Options = []) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Self.check(options: options,
                       completion: continuation.resume)
        }
    }
}

#endif
