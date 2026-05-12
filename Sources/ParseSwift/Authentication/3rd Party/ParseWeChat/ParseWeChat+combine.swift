//
//  ParseWeChat+combine.swift
//  ParseSwift
//
//  Created by Parse Community on 5/13/26.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseWeChat {
    // MARK: Combine
    /**
     Login a `ParseUser` *asynchronously* using WeChat authentication. Publishes when complete.
     - parameter code: The authorization code from **WeChat**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(code: String,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(code: code,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using deprecated WeChat access token authentication. Publishes when complete.
     - parameter id: The **id** from **WeChat**.
     - parameter accessToken: The **access_token** from **WeChat**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(*, deprecated, message: "Use loginPublisher(code:) instead.")
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
     Login a `ParseUser` *asynchronously* using WeChat authentication. Publishes when complete.
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

public extension ParseWeChat {
    /**
     Link the *current* `ParseUser` *asynchronously* using WeChat authentication. Publishes when complete.
     - parameter code: The authorization code from **WeChat**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(code: String,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(code: code,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using deprecated WeChat access token authentication.
     Publishes when complete.
     - parameter id: The **id** from **WeChat**.
     - parameter accessToken: The **access_token** from **WeChat**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(*, deprecated, message: "Use linkPublisher(code:) instead.")
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
     Link the *current* `ParseUser` *asynchronously* using WeChat authentication.
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
