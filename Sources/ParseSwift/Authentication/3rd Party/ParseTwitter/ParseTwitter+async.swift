//
//  ParseTwitter+async.swift
//  ParseTwitter+async
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParseTwitter {
    // MARK: Async/Await

    /**
     Login a `ParseUser` *asynchronously* using Twitter authentication.
     - parameter user: The **id** from **Twitter**.
     - parameter screenName: The `user screenName` from **Twitter**.
     - parameter consumerKey: The `consumerKey` from **Twitter**.
     - parameter consumerSecret: The `consumerSecret` from **Twitter**.
     - parameter authToken: The Twitter `authToken` obtained from Twitter.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(userId: String,
               screenName: String? = nil,
               consumerKey: String,
               consumerSecret: String,
               authToken: String,
               authTokenSecret: String,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(userId: userId,
                       screenName: screenName,
                       authToken: consumerKey,
                       authTokenSecret: consumerSecret,
                       consumerKey: authToken,
                       consumerSecret: authTokenSecret,
                       options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Twitter authentication.
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
                       completion: continuation.resume)
        }
    }
}

public extension ParseTwitter {

    /**
     Link the *current* `ParseUser` *asynchronously* using Twitter authentication.
     - parameter user: The `user` from **Twitter**.
     - parameter screenName: The `user screenName` from **Twitter**.
     - parameter consumerKey: The `consumerKey` from **Twitter**.
     - parameter consumerSecret: The `consumerSecret` from **Twitter**.
     - parameter authToken: The Twitter `authToken` obtained from Twitter.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func link(userId: String,
              screenName: String? = nil,
              consumerKey: String,
              consumerSecret: String,
              authToken: String,
              authTokenSecret: String,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(userId: userId,
                      screenName: screenName,
                      consumerKey: consumerKey,
                      consumerSecret: consumerSecret,
                      authToken: authToken,
                      authTokenSecret: authTokenSecret,
                      options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Twitter authentication.
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
