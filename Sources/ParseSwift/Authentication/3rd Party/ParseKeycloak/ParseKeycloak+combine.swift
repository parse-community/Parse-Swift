//
//  ParseKeycloak+combine.swift
//  ParseSwift
//
//  Created by Parse Community on 5/13/26.
//  Copyright (c) 2026 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseKeycloak {
    // MARK: Combine

    /**
     Login a `ParseUser` *asynchronously* using Keycloak authentication. Publishes when complete.
     - parameter id: The Keycloak user subject (`sub`).
     - parameter accessToken: Required **access_token** from **Keycloak**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(id: String,
                        accessToken: String,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(id: id,
                       accessToken: accessToken,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Keycloak authentication. Publishes when complete.
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

public extension ParseKeycloak {
    /**
     Link the *current* `ParseUser` *asynchronously* using Keycloak authentication.
     Publishes when complete.
     - parameter id: The Keycloak user subject (`sub`).
     - parameter accessToken: Required **access_token** from **Keycloak**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(id: String,
                       accessToken: String,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(id: id,
                      accessToken: accessToken,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Keycloak authentication.
     Publishes when complete.
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
