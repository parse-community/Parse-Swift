//
//  ParseAuthentication+async.swift
//  ParseAuthentication+async
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency)
import Foundation

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension ParseAuthentication {

    // MARK: Convenience Implementations - Async/Await

    func unlink(_ user: AuthenticatedUser,
                options: API.Options = []) async throws -> AuthenticatedUser {
        try await user.unlink(__type, options: options)
    }

    func unlink(options: API.Options = []) async throws -> AuthenticatedUser {
        guard let current = AuthenticatedUser.current else {
            let error = ParseError(code: .invalidLinkedSession, message: "No current ParseUser.")
            return try await withCheckedThrowingContinuation { continuation in
                continuation.resume(with: .failure(error))
            }
        }
        return try await unlink(current, options: options)
    }
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension ParseUser {

    // MARK: 3rd Party Authentication - Login Async/Await

    /**
     Makes an *asynchronous* request to log in a user with specified credentials.
     Publishes an instance of the successfully logged in `ParseUser`.

     This also caches the user locally so that calls to *current* will use the latest logged in user.
     - parameter type: The authentication type.
     - parameter authData: The data that represents the authentication.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     */
    static func login(_ type: String,
                      authData: [String: String],
                      options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            Self.login(type,
                       authData: authData,
                       options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Unlink the authentication type *asynchronously*.
     - parameter type: The type to unlink. The user must be logged in on this device.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     */
    func unlink(_ type: String,
                options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.unlink(type,
                        options: options,
                        completion: continuation.resume)
        }
    }

    /**
     Makes an *asynchronous* request to link a user with specified credentials. The user should already be logged in.
     Publishes an instance of the successfully linked `ParseUser`.

     This also caches the user locally so that calls to *current* will use the latest logged in user.
     - parameter type: The authentication type.
     - parameter authData: The data that represents the authentication.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
    */
    static func link(_ type: String,
                     authData: [String: String],
                     options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            Self.link(type,
                      authData: authData,
                      options: options,
                      completion: continuation.resume)
        }
    }

}
#endif
