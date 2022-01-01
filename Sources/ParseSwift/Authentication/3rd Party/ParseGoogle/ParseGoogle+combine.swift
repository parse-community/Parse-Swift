//
//  ParseGoogle+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/1/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseGoogle {
    // MARK: Combine
    /**
     Login a `ParseUser` *asynchronously* using Google authentication for graph API login. Publishes when complete.
     - parameter id: The **id** from **Google**.
     - parameter idToken: Optional **id_token** from **Google**.
     - parameter accessToken: Optional **access_token** from **Google**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(id: String,
                        idToken: String? = nil,
                        accessToken: String? = nil,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(id: id,
                       idToken: idToken,
                       accessToken: accessToken,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Google authentication for graph API login. Publishes when complete.
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

public extension ParseGoogle {
    /**
     Link the *current* `ParseUser` *asynchronously* using Google authentication for graph API login.
     Publishes when complete.
     - parameter id: The **id** from **Google**.
     - parameter idToken: Optional **id_token** from **Google**.
     - parameter accessToken: Optional **access_token** from **Google**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(id: String,
                       idToken: String? = nil,
                       accessToken: String? = nil,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(id: id,
                      idToken: idToken,
                      accessToken: accessToken,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Google authentication for graph API login.
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
