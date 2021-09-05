//
//  ParseTwitter+async.swift
//  ParseTwitter+async
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5)
import Foundation

@available(macOS 12.0, iOS 15.0, macCatalyst 15.0, watchOS 9.0, tvOS 15.0, *)
public extension ParseTwitter {
    // MARK: Login - Async/Await

    /**
     Login a `ParseUser` *asynchronously* using Twitter authentication. Publishes when complete.
     - parameter user: The `userId` from `Twitter`.
     - parameter screenName: The `user screenName` from `Twitter`.
     - parameter consumerKey: The `consumerKey` from `Twitter`.
     - parameter consumerSecret: The `consumerSecret` from `Twitter`.
     - parameter authToken: The Twitter `authToken` obtained from Twitter.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
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

    func login(authData: [String: String],
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(authData: authData,
                       options: options,
                       completion: continuation.resume)
        }
    }
}

@available(macOS 12.0, iOS 15.0, macCatalyst 15.0, watchOS 9.0, tvOS 15.0, *)
public extension ParseTwitter {
    // MARK: Link - Async/Await

    /**
     Link the *current* `ParseUser` *asynchronously* using Twitter authentication. Publishes when complete.
     - parameter user: The `user` from `Twitter`.
     - parameter screenName: The `user screenName` from `Twitter`.
     - parameter consumerKey: The `consumerKey` from `Twitter`.
     - parameter consumerSecret: The `consumerSecret` from `Twitter`.
     - parameter authToken: The Twitter `authToken` obtained from Twitter.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
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