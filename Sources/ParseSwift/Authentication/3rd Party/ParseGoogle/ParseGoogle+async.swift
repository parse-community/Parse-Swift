//
//  ParseGoogle+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/1/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency)
import Foundation

public extension ParseGoogle {
    // MARK: Async/Await

    /**
     Login a `ParseUser` *asynchronously* using Google authentication for graph API login.
     - parameter userId: The **id** from **Google**.
     - parameter idToken: Optional **id_token** from **Google**.
     - parameter accessToken: Optional **access_token** from **Google**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(userId: String,
               idToken: String? = nil,
               accessToken: String? = nil,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(userId: userId,
                       idToken: idToken,
                       accessToken: accessToken,
                       options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Google authentication for graph API login.
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

public extension ParseGoogle {

    /**
     Link the *current* `ParseUser` *asynchronously* using Google authentication for graph API login.
     - parameter userId: The **id** from **Google**.
     - parameter idToken: Optional **id_token** from **Google**.
     - parameter accessToken: Optional **access_token** from **Google**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func link(userId: String,
              idToken: String? = nil,
              accessToken: String? = nil,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(userId: userId,
                      idToken: idToken,
                      accessToken: accessToken,
                      options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Google authentication for graph API login.
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
