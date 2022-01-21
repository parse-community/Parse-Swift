//
//  ParseApple+combine.swift
//  ParseApple+combine
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseApple {
    // MARK: Combine

    /**
     Login a `ParseUser` *asynchronously* using Apple authentication. Publishes when complete.
     - parameter user: The `user` from `ASAuthorizationAppleIDCredential`.
     - parameter identityToken: The **identityToken** from `ASAuthorizationAppleIDCredential`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(user: String,
                        identityToken: Data,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(user: user,
                       identityToken: identityToken,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Apple authentication. Publishes when complete.
     - parameter authData: Dictionary containing key/values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
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

public extension ParseApple {

    /**
     Link the *current* `ParseUser` *asynchronously* using Apple authentication. Publishes when complete.
     - parameter user: The `user` from `ASAuthorizationAppleIDCredential`.
     - parameter identityToken: The **identityToken** from `ASAuthorizationAppleIDCredential`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(user: String,
                       identityToken: Data,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(user: user,
                      identityToken: identityToken,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Apple authentication. Publishes when complete.
     - parameter authData: Dictionary containing key/values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
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
