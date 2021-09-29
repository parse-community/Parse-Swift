//
//  ParseFacebook+async.swift
//  ParseFacebook+async
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(_Concurrency)
import Foundation

@available(macOS 12.0, iOS 15.0, macCatalyst 15.0, watchOS 9.0, tvOS 15.0, *)
public extension ParseFacebook {
    // MARK: Login - Async/Await

    /**
     Login a `ParseUser` *asynchronously* using Facebook authentication for limited login.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter authenticationToken: The `authenticationToken` from `FacebookSDK`.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     */
    func login(userId: String,
               authenticationToken: String,
               expiresIn: Int? = nil,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(userId: userId,
                       authenticationToken: authenticationToken,
                       expiresIn: expiresIn,
                       options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Facebook authentication for graph API login.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter accessToken: The `accessToken` from `FacebookSDK`.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     */
    func login(userId: String,
               accessToken: String,
               expiresIn: Int? = nil,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(userId: userId,
                       accessToken: accessToken,
                       expiresIn: expiresIn,
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
public extension ParseFacebook {
    // MARK: Link - Async/Await
    /**
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for limited login.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter authenticationToken: The `authenticationToken` from `FacebookSDK`.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     */
    func link(userId: String,
              authenticationToken: String,
              expiresIn: Int? = nil,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(userId: userId,
                      authenticationToken: authenticationToken,
                      expiresIn: expiresIn,
                      options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for graph API login.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter accessToken: The `accessToken` from `FacebookSDK`.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     */
    func link(userId: String,
              accessToken: String,
              expiresIn: Int? = nil,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(userId: userId,
                      accessToken: accessToken,
                      expiresIn: expiresIn,
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
