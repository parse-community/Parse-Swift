//
//  ParseLDAP+async.swift
//  ParseLDAP+async
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5)
import Foundation

@available(macOS 12.0, iOS 15.0, macCatalyst 15.0, watchOS 9.0, tvOS 15.0, *)
public extension ParseLDAP {
    // MARK: Login - Async/Await
    /**
     Login a `ParseUser` *asynchronously* using LDAP authentication. Publishes when complete.
     - parameter id: The id of the `user`.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func login(id: String, // swiftlint:disable:this identifier_name
               password: String,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(id: id,
                       password: password,
                       options: options,
                       completion: continuation.resume)
        }
    }

    func login(authData: [String: String],
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(authData: authData,
                       options: options,
                       completion: continuation.resume)
        }
    }
}

@available(macOS 12.0, iOS 15.0, macCatalyst 15.0, watchOS 9.0, tvOS 15.0, *)
public extension ParseLDAP {
    // MARK: Link - Async/Await
    /**
     Link the *current* `ParseUser` *asynchronously* using LDAP authentication. Publishes when complete.
     - parameter id: The id of the `user`.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func link(id: String, // swiftlint:disable:this identifier_name
              password: String,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(id: id,
                      password: password,
                      options: options,
                      completion: continuation.resume)
        }
    }

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
