//
//  ParseQQ+async.swift
//  ParseSwift
//
//  Created by Parse Community on 5/13/26.
//  Copyright (c) 2026 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParseQQ {
    // MARK: Async/Await

    /**
     Login a `ParseUser` *asynchronously* using secure QQ OAuth code authentication.
     - parameter code: The **code** from **QQ**.
     - parameter redirectURI: The **redirect_uri** used for the QQ OAuth exchange.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(code: String,
               redirectURI: String,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(code: code,
                       redirectURI: redirectURI,
                       options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using deprecated insecure QQ access token authentication.
     - parameter id: The **id** from **QQ**.
     - parameter accessToken: The **access_token** from **QQ**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    @available(*, deprecated, message: "Use login(code:redirectURI:) instead.")
    func login(id: String,
               accessToken: String,
               options: API.Options = []) async throws -> AuthenticatedUser {
        let qqAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken)
        return try await login(authData: qqAuthData,
                               options: options)
    }

    /**
     Login a `ParseUser` *asynchronously* using QQ authentication.
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

public extension ParseQQ {

    /**
     Link the *current* `ParseUser` *asynchronously* using secure QQ OAuth code authentication.
     - parameter code: The **code** from **QQ**.
     - parameter redirectURI: The **redirect_uri** used for the QQ OAuth exchange.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func link(code: String,
              redirectURI: String,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(code: code,
                      redirectURI: redirectURI,
                      options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using deprecated insecure QQ access token authentication.
     - parameter id: The **id** from **QQ**.
     - parameter accessToken: The **access_token** from **QQ**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    @available(*, deprecated, message: "Use link(code:redirectURI:) instead.")
    func link(id: String,
              accessToken: String,
              options: API.Options = []) async throws -> AuthenticatedUser {
        let qqAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken)
        return try await link(authData: qqAuthData,
                              options: options)
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using QQ authentication.
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
