//
//  ParseSpotify+async.swift
//  ParseSwift
//
//  Created by Ulaş Sancak on 06/20/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParseSpotify {
    // MARK: Async/Await

    /**
     Login a `ParseUser` *asynchronously* using Spotify authentication.
     - parameter id: The **Spotify profile id** from **Spotify**.
     - parameter accessToken: Required **access_token** from **Spotify**.
     - parameter expiresIn: Optional **expires_in** in seconds from **Spotify**.
     - parameter refreshToken: Optional **refresh_token** from **Spotify**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(id: String,
               accessToken: String,
               expiresIn: Int? = nil,
               refreshToken: String? = nil,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(id: id,
                       accessToken: accessToken,
                       expiresIn: expiresIn,
                       refreshToken: refreshToken,
                       options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Spotify authentication.
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

public extension ParseSpotify {

    /**
     Link the *current* `ParseUser` *asynchronously* using Spotify authentication.
     - parameter id: The **Spotify profile id** from **Spotify**.
     - parameter accessToken: Required **access_token** from **Spotify**.
     - parameter expiresIn: Optional **expires_in** in seconds from **Spotify**.
     - parameter refreshToken: Optional **refresh_token** from **Spotify**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func link(id: String,
              accessToken: String,
              expiresIn: Int? = nil,
              refreshToken: String? = nil,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(id: id,
                      accessToken: accessToken,
                      expiresIn: expiresIn,
                      refreshToken: refreshToken,
                      options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Spotify authentication.
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
