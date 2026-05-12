//
//  ParsePhantAuth+async.swift
//  ParseSwift
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParsePhantAuth {
    // MARK: Async/Await

    /**
     Login a `ParseUser` *asynchronously* using PhantAuth authentication.
     - parameter id: The **id** from **PhantAuth**.
     - parameter accessToken: Required **access_token** from **PhantAuth**.
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
                       completion: { result in
                           continuation.resume(with: result)
                       })
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using PhantAuth authentication.
     - parameter authData: Dictionary containing key/values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(authData: [String: String],
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(authData: authData,
                       options: options,
                       completion: { result in
                           continuation.resume(with: result)
                       })
        }
    }
}

public extension ParsePhantAuth {

    /**
     Link the *current* `ParseUser` *asynchronously* using PhantAuth authentication.
     - parameter id: The **id** from **PhantAuth**.
     - parameter accessToken: Required **access_token** from **PhantAuth**.
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
                      completion: { result in
                          continuation.resume(with: result)
                      })
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using PhantAuth authentication.
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
                      completion: { result in
                          continuation.resume(with: result)
                      })
        }
    }
}
#endif
