//
//  ParseWeChat+async.swift
//  ParseSwift
//
//  Created by Parse Community on 5/13/26.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParseWeChat {
    // MARK: Async/Await

    /**
     Login a `ParseUser` *asynchronously* using WeChat authentication.
     - parameter code: The authorization code from **WeChat**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(code: String,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(code: code,
                       options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using deprecated WeChat access token authentication.
     - parameter id: The **id** from **WeChat**.
     - parameter accessToken: The **access_token** from **WeChat**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    @available(*, deprecated, message: "Use login(code:) instead.")
    func login(id: String,
               accessToken: String,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(id: id,
                       accessToken: accessToken,
                       options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using WeChat authentication.
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

public extension ParseWeChat {

    /**
     Link the *current* `ParseUser` *asynchronously* using WeChat authentication.
     - parameter code: The authorization code from **WeChat**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func link(code: String,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(code: code,
                      options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using deprecated WeChat access token authentication.
     - parameter id: The **id** from **WeChat**.
     - parameter accessToken: The **access_token** from **WeChat**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    @available(*, deprecated, message: "Use link(code:) instead.")
    func link(id: String,
              accessToken: String,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(id: id,
                      accessToken: accessToken,
                      options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using WeChat authentication.
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
