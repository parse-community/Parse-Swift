//
//  ParseLDAP+async.swift
//  ParseLDAP+async
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency)
import Foundation

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension ParseLDAP {
    // MARK: Async/Await
    /**
     Login a `ParseUser` *asynchronously* using LDAP authentication.
     - parameter id: The id of the `user`.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: `ParseError`.
     */
    func login(id: String,
               password: String,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(id: id,
                       password: password,
                       options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using LDAP authentication.
     - parameter authData: Dictionary containing key/values.
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
public extension ParseLDAP {
    /**
     Link the *current* `ParseUser` *asynchronously* using LDAP authentication.
     - parameter id: The id of the `user`.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: `ParseError`.
     */
    func link(id: String,
              password: String,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(id: id,
                      password: password,
                      options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using LDAP authentication.
     - parameter authData: Dictionary containing key/values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: `ParseError`.
     */
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
