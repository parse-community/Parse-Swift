//
//  ParseMicrosoft+async.swift
//  ParseSwift
//
//  Created by DENGXUELIN on 5/13/26.
//  Copyright © 2026 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParseMicrosoft {
    // MARK: Async/Await

    /**
     Login a `ParseUser` *asynchronously* using Microsoft authentication.
     - parameter code: Required **code** from **Microsoft**.
     - parameter redirectURI: Required **redirect_uri** from **Microsoft**.
     - parameter id: Optional **id** from **Microsoft**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(code: String,
               redirectURI: String,
               id: String? = nil,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(code: code,
                       redirectURI: redirectURI,
                       id: id,
                       options: options,
                       completion: continuation.resume(with:))
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Microsoft authentication in Parse Server's insecure auth mode.
     - parameter id: Required **id** from **Microsoft**.
     - parameter accessToken: Required **access_token** from **Microsoft**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(id: String,
               accessToken: String,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(id: id,
                       accessToken: accessToken,
                       options: options,
                       completion: continuation.resume(with:))
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Microsoft authentication.
     - parameter authData: Dictionary containing key/values.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(authData: [String: String],
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(authData: authData,
                       options: options,
                       completion: continuation.resume(with:))
        }
    }
}

public extension ParseMicrosoft {

    /**
     Link the *current* `ParseUser` *asynchronously* using Microsoft authentication.
     - parameter code: Required **code** from **Microsoft**.
     - parameter redirectURI: Required **redirect_uri** from **Microsoft**.
     - parameter id: Optional **id** from **Microsoft**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func link(code: String,
              redirectURI: String,
              id: String? = nil,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(code: code,
                      redirectURI: redirectURI,
                      id: id,
                      options: options,
                      completion: continuation.resume(with:))
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Microsoft authentication in Parse Server's insecure auth mode.
     - parameter id: Required **id** from **Microsoft**.
     - parameter accessToken: Required **access_token** from **Microsoft**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func link(id: String,
              accessToken: String,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(id: id,
                      accessToken: accessToken,
                      options: options,
                      completion: continuation.resume(with:))
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Microsoft authentication.
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
                      completion: continuation.resume(with:))
        }
    }
}
#endif
