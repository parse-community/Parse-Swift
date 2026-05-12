//
//  ParseMeetup+async.swift
//  ParseSwift
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParseMeetup {
    // MARK: Async/Await

    /**
     Login a `ParseUser` *asynchronously* using Meetup authentication.
     - parameter id: The **id** from **Meetup**.
     - parameter accessToken: Required **access_token** from **Meetup**.
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
     Login a `ParseUser` *asynchronously* using Meetup authentication.
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

public extension ParseMeetup {

    /**
     Link the *current* `ParseUser` *asynchronously* using Meetup authentication.
     - parameter id: The **id** from **Meetup**.
     - parameter accessToken: Required **access_token** from **Meetup**.
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
     Link the *current* `ParseUser` *asynchronously* using Meetup authentication.
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
