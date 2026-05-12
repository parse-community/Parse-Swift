//
//  ParseQQ.swift
//  ParseSwift
//
//  Created by Parse Community on 5/13/26.
//  Copyright (c) 2026 Parse Community. All rights reserved.
//

import Foundation

private let parseQQInvalidAuthDataMessage = "Should have authData consisting of keys \"code\" and " +
    "\"redirect_uri\", or keys \"id\" and \"access_token\"."

/**
 Provides utility functions for working with QQ User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for QQ authentication.
 For information on acquiring QQ sign-in credentials to use with `ParseQQ`,
 refer to [QQ's Documentation](https://wiki.connect.qq.com/).
 */
public struct ParseQQ<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for QQ authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case accessToken = "access_token"
        case code
        case redirectURI = "redirect_uri"

        /// Properly makes an authData dictionary for secure QQ OAuth code authentication.
        /// - parameter code: Required code from QQ.
        /// - parameter redirectURI: Required redirect_uri used for the QQ OAuth exchange.
        /// - returns: authData dictionary.
        func makeDictionary(code: String,
                            redirectURI: String) -> [String: String] {
            [
                AuthenticationKeys.code.rawValue: code,
                AuthenticationKeys.redirectURI.rawValue: redirectURI
            ]
        }

        /// Properly makes an authData dictionary for insecure QQ access token authentication.
        /// - parameter id: Required id for the user.
        /// - parameter accessToken: Required access_token from QQ.
        /// - returns: authData dictionary.
        func makeDictionary(id: String,
                            accessToken: String) -> [String: String] {
            [
                AuthenticationKeys.id.rawValue: id,
                AuthenticationKeys.accessToken.rawValue: accessToken
            ]
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: **true** if all the mandatory keys are present, **false** otherwise.
        func verifyMandatoryKeys(authData: [String: String]) -> Bool {
            if authData[AuthenticationKeys.code.rawValue] != nil,
               authData[AuthenticationKeys.redirectURI.rawValue] != nil {
                return true
            }

            if authData[AuthenticationKeys.id.rawValue] != nil,
               authData[AuthenticationKeys.accessToken.rawValue] != nil {
                return true
            }

            return false
        }
    }

    public static var __type: String { // swiftlint:disable:this identifier_name
        "qq"
    }

    public init() { }
}

// MARK: Login
public extension ParseQQ {

    /**
     Login a `ParseUser` *asynchronously* using secure QQ OAuth code authentication.
     - parameter code: The **code** from **QQ**.
     - parameter redirectURI: The **redirect_uri** used for the QQ OAuth exchange.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(code: String,
               redirectURI: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let qqAuthData = AuthenticationKeys.code
            .makeDictionary(code: code,
                            redirectURI: redirectURI)
        login(authData: qqAuthData,
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }

    /**
     Login a `ParseUser` *asynchronously* using deprecated insecure QQ access token authentication.
     - parameter id: The **id** from **QQ**.
     - parameter accessToken: The **access_token** from **QQ**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    @available(*, deprecated, message: "Use login(code:redirectURI:) instead.")
    func login(id: String,
               accessToken: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let qqAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken)
        login(authData: qqAuthData,
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }

    func login(authData: [String: String],
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.code.verifyMandatoryKeys(authData: authData) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: parseQQInvalidAuthDataMessage)))
            }
            return
        }
        AuthenticatedUser.login(Self.__type,
                                authData: authData,
                                options: options,
                                callbackQueue: callbackQueue,
                                completion: completion)
    }
}

// MARK: Link
public extension ParseQQ {

    /**
     Link the *current* `ParseUser` *asynchronously* using secure QQ OAuth code authentication.
     - parameter code: The **code** from **QQ**.
     - parameter redirectURI: The **redirect_uri** used for the QQ OAuth exchange.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(code: String,
              redirectURI: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let qqAuthData = AuthenticationKeys.code
            .makeDictionary(code: code,
                            redirectURI: redirectURI)
        link(authData: qqAuthData,
             options: options,
             callbackQueue: callbackQueue,
             completion: completion)
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using deprecated insecure QQ access token authentication.
     - parameter id: The **id** from **QQ**.
     - parameter accessToken: The **access_token** from **QQ**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    @available(*, deprecated, message: "Use link(code:redirectURI:) instead.")
    func link(id: String,
              accessToken: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let qqAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken)
        link(authData: qqAuthData,
             options: options,
             callbackQueue: callbackQueue,
             completion: completion)
    }

    func link(authData: [String: String],
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.code.verifyMandatoryKeys(authData: authData) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: parseQQInvalidAuthDataMessage)))
            }
            return
        }
        AuthenticatedUser.link(Self.__type,
                               authData: authData,
                               options: options,
                               callbackQueue: callbackQueue,
                               completion: completion)
    }
}

// MARK: 3rd Party Authentication - ParseQQ
public extension ParseUser {

    /// A QQ `ParseUser`.
    static var qq: ParseQQ<Self> {
        ParseQQ<Self>()
    }

    /// A QQ `ParseUser`.
    var qq: ParseQQ<Self> {
        Self.qq
    }
}
