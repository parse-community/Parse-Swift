//
//  ParseFacebook+combine.swift
//  ParseFacebook+combine
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseFacebook {
    // MARK: Login - Combine
    /**
     Login a `ParseUser` *asynchronously* using Facebook authentication for limited login. Publishes when complete.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter authenticationToken: The `authenticationToken` from `FacebookSDK`.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(userId: String,
                        authenticationToken: String,
                        expiresIn: Int? = nil,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(userId: userId,
                       authenticationToken: authenticationToken,
                       expiresIn: expiresIn,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Facebook authentication for graph API login. Publishes when complete.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter accessToken: The `accessToken` from `FacebookSDK`.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(userId: String,
                        accessToken: String,
                        expiresIn: Int? = nil,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(userId: userId,
                       accessToken: accessToken,
                       expiresIn: expiresIn,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Facebook authentication for graph API login. Publishes when complete.
     - parameter authData: Dictionary containing key/values.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(authData: [String: String],
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(authData: authData,
                       options: options,
                       completion: promise)
        }
    }
}

@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseFacebook {
    // MARK: Link - Combine
    /**
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for limited login.
     Publishes when complete.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter authenticationToken: The `authenticationToken` from `FacebookSDK`.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(userId: String,
                       authenticationToken: String,
                       expiresIn: Int? = nil,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(userId: userId,
                      authenticationToken: authenticationToken,
                      expiresIn: expiresIn,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for graph API login.
     Publishes when complete.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter accessToken: The `accessToken` from `FacebookSDK`.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(userId: String,
                       accessToken: String,
                       expiresIn: Int? = nil,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(userId: userId,
                      accessToken: accessToken,
                      expiresIn: expiresIn,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for graph API login.
     Publishes when complete.
     - parameter authData: Dictionary containing key/values.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(authData: [String: String],
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(authData: authData,
                      options: options,
                      completion: promise)
        }
    }
}

#endif
