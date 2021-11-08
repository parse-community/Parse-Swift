//
//  ParseAnonymous+async.swift
//  ParseAnonymous+async
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency)
import Foundation

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension ParseAnonymous {

    // MARK: Async/Await
    /**
     Login a `ParseUser` *asynchronously* using the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: `ParseError`.
     */
    func login(options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using the respective authentication type.
     - parameter authData: The authData for the respective authentication type. This will be ignored.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: `ParseError`.
     */
    func login(authData: [String: String],
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(authData: authData,
                       options: options,
                       completion: continuation.resume)
        }
    }
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension ParseAnonymous {

    func link(authData: [String: String],
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(authData: authData,
                      options: options,
                      completion: continuation.resume)
        }
    }
}

#endif
