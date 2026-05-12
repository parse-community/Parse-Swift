//
//  ParseQQ+combine.swift
//  ParseSwift
//
//  Created by Parse Community on 5/13/26.
//  Copyright (c) 2026 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseQQ {
    // MARK: Combine
    /**
     Login a `ParseUser` *asynchronously* using secure QQ OAuth code authentication. Publishes when complete.
     - parameter code: The **code** from **QQ**.
     - parameter redirectURI: The **redirect_uri** used for the QQ OAuth exchange.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(code: String,
                        redirectURI: String,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(code: code,
                       redirectURI: redirectURI,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using deprecated insecure QQ access token authentication.
     Publishes when complete.
     - parameter id: The **id** from **QQ**.
     - parameter accessToken: The **access_token** from **QQ**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(*, deprecated, message: "Use loginPublisher(code:redirectURI:) instead.")
    func loginPublisher(id: String,
                        accessToken: String,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        let qqAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken)
        return Future { promise in
            self.login(authData: qqAuthData,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using QQ authentication. Publishes when complete.
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

public extension ParseQQ {
    /**
     Link the *current* `ParseUser` *asynchronously* using secure QQ OAuth code authentication. Publishes when complete.
     - parameter code: The **code** from **QQ**.
     - parameter redirectURI: The **redirect_uri** used for the QQ OAuth exchange.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(code: String,
                       redirectURI: String,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(code: code,
                      redirectURI: redirectURI,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using deprecated insecure QQ access token authentication.
     Publishes when complete.
     - parameter id: The **id** from **QQ**.
     - parameter accessToken: The **access_token** from **QQ**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(*, deprecated, message: "Use linkPublisher(code:redirectURI:) instead.")
    func linkPublisher(id: String,
                       accessToken: String,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        let qqAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken)
        return Future { promise in
            self.link(authData: qqAuthData,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using QQ authentication. Publishes when complete.
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
