//
//  ParseInstagram+async.swift
//  ParseSwift
//
//  Created by Ulaş Sancak on 06/19/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParseInstagram {
    // MARK: Async/Await

    /**
     Login a `ParseUser` *asynchronously* using Instagram authentication.
     - parameter id: The **Instagram profile id** from **Instagram**.
     - parameter accessToken: Required **access_token** from **Instagram**.
     - parameter apiURL: The `Instagram's most recent graph api url` from **Instagram**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(id: String,
               accessToken: String,
               apiURL: String = Self.graphAPIBaseURL,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(id: id,
                       accessToken: accessToken,
                       apiURL: apiURL,
                       options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Instagram authentication.
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

public extension ParseInstagram {

    /**
     Link the *current* `ParseUser` *asynchronously* using Instagram authentication.
     - parameter id: The **Instagram profile id** from **Instagram**.
     - parameter accessToken: Required **access_token** from **Instagram**.
     - parameter apiURL: The `Instagram's most recent graph api url` from **Instagram**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func link(id: String,
              accessToken: String,
              apiURL: String = Self.graphAPIBaseURL,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(id: id,
                      accessToken: accessToken,
                      apiURL: apiURL,
                      options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Instagram authentication.
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
