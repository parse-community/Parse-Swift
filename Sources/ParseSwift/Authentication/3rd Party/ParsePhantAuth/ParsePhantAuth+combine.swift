//
//  ParsePhantAuth+combine.swift
//  ParseSwift
//
//  Created by DENGXUELIN on 05/13/26.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParsePhantAuth {
    // MARK: Combine
    /**
     Login a `ParseUser` *asynchronously* using PhantAuth authentication. Publishes when complete.
     - parameter id: The **PhantAuth profile id** from **PhantAuth**.
     - parameter accessToken: Required **access_token** from **PhantAuth**.
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
     Login a `ParseUser` *asynchronously* using PhantAuth authentication. Publishes when complete.
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

public extension ParsePhantAuth {
    /**
     Link the *current* `ParseUser` *asynchronously* using PhantAuth authentication.
     Publishes when complete.
     - parameter id: The **PhantAuth profile id** from **PhantAuth**.
     - parameter accessToken: Required **access_token** from **PhantAuth**.
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
     Link the *current* `ParseUser` *asynchronously* using PhantAuth authentication.
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
