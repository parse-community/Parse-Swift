//
//  ParseWeibo.swift
//  ParseSwift
//
//  Created by Moe Kanan on 5/12/26.
//  Copyright © 2026 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with Weibo User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with Weibo](https://docs.parseplatform.org/parse-server/guide/#oauth-and-3rd-party-authentication).
 For information on acquiring Weibo sign-in credentials to use with `ParseWeibo`, refer to [Weibo's Documentation](https://open.weibo.com/wiki/Oauth2/access_token).
 */
public struct ParseWeibo<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Weibo authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case accessToken = "access_token"
        case code
        case redirectURI = "redirect_uri"

        /// Properly makes an authData dictionary for secure Weibo authentication.
        /// - parameter code: Required authorization code from Weibo.
        /// - parameter redirectURI: Required redirect URI registered for Weibo.
        /// - returns: authData dictionary.
        static func makeDictionary(code: String,
                                   redirectURI: String) -> [String: String] {
            [AuthenticationKeys.code.rawValue: code,
             AuthenticationKeys.redirectURI.rawValue: redirectURI]
        }

        /// Properly makes an authData dictionary for deprecated insecure Weibo authentication.
        /// - parameter id: Required id for the user.
        /// - parameter accessToken: Required access token for Weibo.
        /// - returns: authData dictionary.
        static func makeDictionary(id: String,
                                   accessToken: String) -> [String: String] {
            [AuthenticationKeys.id.rawValue: id,
             AuthenticationKeys.accessToken.rawValue: accessToken]
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: **true** if all the mandatory keys are present, **false** otherwise.
        static func verifyMandatoryKeys(authData: [String: String]) -> Bool {
            let hasSecureKeys = authData[AuthenticationKeys.code.rawValue] != nil &&
                authData[AuthenticationKeys.redirectURI.rawValue] != nil
            let hasInsecureKeys = authData[AuthenticationKeys.id.rawValue] != nil &&
                authData[AuthenticationKeys.accessToken.rawValue] != nil
            return hasSecureKeys || hasInsecureKeys
        }
    }

    public static var __type: String { // swiftlint:disable:this identifier_name
        "weibo"
    }

    public init() { }
}

// MARK: Login
public extension ParseWeibo {

    /**
     Login a `ParseUser` *asynchronously* using secure Weibo authentication.
     - parameter code: The authorization code from Weibo.
     - parameter redirectURI: The redirect URI registered for Weibo.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(code: String,
               redirectURI: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        login(authData: AuthenticationKeys.makeDictionary(code: code,
                                                          redirectURI: redirectURI),
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }

    /**
     Login a `ParseUser` *asynchronously* using deprecated insecure Weibo authentication.
     - parameter id: The id from Weibo.
     - parameter accessToken: The access token from Weibo.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(id: String,
               accessToken: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        login(authData: AuthenticationKeys.makeDictionary(id: id,
                                                          accessToken: accessToken),
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }

    func login(authData: [String: String],
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.verifyMandatoryKeys(authData: authData) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: "Should have authData consisting of keys \"code\" and \"redirectURI\", or \"id\" and \"accessToken\".")))
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
public extension ParseWeibo {

    /**
     Link the *current* `ParseUser` *asynchronously* using secure Weibo authentication.
     - parameter code: The authorization code from Weibo.
     - parameter redirectURI: The redirect URI registered for Weibo.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(code: String,
              redirectURI: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        link(authData: AuthenticationKeys.makeDictionary(code: code,
                                                         redirectURI: redirectURI),
             options: options,
             callbackQueue: callbackQueue,
             completion: completion)
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using deprecated insecure Weibo authentication.
     - parameter id: The id from Weibo.
     - parameter accessToken: The access token from Weibo.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(id: String,
              accessToken: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        link(authData: AuthenticationKeys.makeDictionary(id: id,
                                                         accessToken: accessToken),
             options: options,
             callbackQueue: callbackQueue,
             completion: completion)
    }

    func link(authData: [String: String],
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.verifyMandatoryKeys(authData: authData) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: "Should have authData consisting of keys \"code\" and \"redirectURI\", or \"id\" and \"accessToken\".")))
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

// MARK: 3rd Party Authentication - ParseWeibo
public extension ParseUser {

    /// A Weibo `ParseUser`.
    static var weibo: ParseWeibo<Self> {
        ParseWeibo<Self>()
    }

    /// A Weibo `ParseUser`.
    var weibo: ParseWeibo<Self> {
        Self.weibo
    }
}
