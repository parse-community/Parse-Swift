//
//  ParseCloud+async.swift
//  ParseCloud+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency)
import Foundation

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension ParseCloud {

    // MARK: Aysnc/Await

    /**
     Calls a Cloud Code function *asynchronously* and returns a result of it's execution.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: The return type.
     - throws: `ParseError`.
    */
    func runFunction(options: API.Options = []) async throws -> ReturnType {
        try await withCheckedThrowingContinuation { continuation in
            self.runFunction(options: options,
                             completion: continuation.resume)
        }
    }

    /**
     Starts a Cloud Code Job *asynchronously* and returns a result with the jobStatusId of the job.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
    */
    func startJob(options: API.Options = []) async throws -> ReturnType {
        try await withCheckedThrowingContinuation { continuation in
            self.startJob(options: options,
                          completion: continuation.resume)
        }
    }
}
#endif
