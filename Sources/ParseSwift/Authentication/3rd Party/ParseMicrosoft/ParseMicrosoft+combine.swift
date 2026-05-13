//
//  ParseMicrosoft+combine.swift
//  ParseSwift
//
//  Created by DENGXUELIN on 5/13/26.
//  Copyright © 2026 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseMicrosoft {
    // MARK: Combine
    /**
     Login a `ParseUser` *asynchronously* using Microsoft authentication. Publishes when complete.
     - parameter code: Required **code** from **Microsoft**.
     - parameter redirectURI: Required **redirect_uri** from **Microsoft**.
     - parameter id: Optional **id** from **Microsoft**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(code: String,
                        redirectURI: String,
                        id: String? = nil,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(code: code,
                       redirectURI: redirectURI,
                       id: id,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Microsoft authentication in Parse Server's insecure auth mode.
     Publishes when complete.
     - parameter id: Required **id** from **Microsoft**.
     - parameter accessToken: Required **access_token** from **Microsoft**.
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
     Login a `ParseUser` *asynchronously* using Microsoft authentication. Publishes when complete.
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

public extension ParseMicrosoft {
    /**
     Link the *current* `ParseUser` *asynchronously* using Microsoft authentication.
     Publishes when complete.
     - parameter code: Required **code** from **Microsoft**.
     - parameter redirectURI: Required **redirect_uri** from **Microsoft**.
     - parameter id: Optional **id** from **Microsoft**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(code: String,
                       redirectURI: String,
                       id: String? = nil,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(code: code,
                      redirectURI: redirectURI,
                      id: id,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Microsoft authentication in Parse Server's insecure auth mode.
     Publishes when complete.
     - parameter id: Required **id** from **Microsoft**.
     - parameter accessToken: Required **access_token** from **Microsoft**.
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
     Link the *current* `ParseUser` *asynchronously* using Microsoft authentication.
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
