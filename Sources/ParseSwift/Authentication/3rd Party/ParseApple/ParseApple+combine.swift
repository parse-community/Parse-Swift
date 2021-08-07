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

@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseApple {
    // MARK: Login - Combine

    /**
     Login a `ParseUser` *asynchronously* using Apple authentication. Publishes when complete.
     - parameter user: The `user` from `ASAuthorizationAppleIDCredential`.
     - parameter identityToken: The `identityToken` from `ASAuthorizationAppleIDCredential`.
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
public extension ParseApple {
    // MARK: Link - Combine

    /**
     Link the *current* `ParseUser` *asynchronously* using Apple authentication. Publishes when complete.
     - parameter user: The `user` from `ASAuthorizationAppleIDCredential`.
     - parameter identityToken: The `identityToken` from `ASAuthorizationAppleIDCredential`.
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
