//
//  ParseFacebook+async.swift
//  ParseFacebook+async
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParseFacebook {
    // MARK: Async/Await

    /**
     Login a `ParseUser` *asynchronously* using Facebook authentication for limited login.
     - parameter userId: The **id** from **FacebookSDK**.
     - parameter authenticationToken: The `authenticationToken` from **FacebookSDK**.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
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
     - parameter userId: The **id** from **FacebookSDK**.
     - parameter accessToken: The `accessToken` from **FacebookSDK**.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
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

    /**
     Login a `ParseUser` *asynchronously* using Facebook authentication for graph API login.
     - parameter authData: Dictionary containing key/values.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
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

public extension ParseFacebook {
    /**
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for limited login.
     - parameter userId: The **id** from **FacebookSDK**.
     - parameter authenticationToken: The `authenticationToken` from **FacebookSDK**.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
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
     - parameter userId: The **id** from **FacebookSDK**.
     - parameter accessToken: The `accessToken` from **FacebookSDK**.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
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

    /**
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for graph API login.
     - parameter authData: Dictionary containing key/values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
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
