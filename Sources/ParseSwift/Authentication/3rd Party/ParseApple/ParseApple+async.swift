//
//  ParseApple+async.swift
//  ParseApple+async
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency)
import Foundation

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension ParseApple {
    // MARK: Async/Await

    /**
     Login a `ParseUser` *asynchronously* using Apple authentication.
     - parameter user: The `user` from `ASAuthorizationAppleIDCredential`.
     - parameter identityToken: The `identityToken` from `ASAuthorizationAppleIDCredential`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: `ParseError`.
     */
    func login(user: String,
               identityToken: Data,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(user: user,
                       identityToken: identityToken,
                       options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Apple authentication.
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
public extension ParseApple {

    /**
     Link the *current* `ParseUser` *asynchronously* using Apple authentication.
     - parameter user: The `user` from `ASAuthorizationAppleIDCredential`.
     - parameter identityToken: The `identityToken` from `ASAuthorizationAppleIDCredential`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: `ParseError`.
     */
    func link(user: String,
              identityToken: Data,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(user: user,
                      identityToken: identityToken,
                      options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Apple authentication.
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
