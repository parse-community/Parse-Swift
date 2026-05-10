//
//  ParseMicrosoft.swift
//  ParseSwift
//
//  Created by Parse Community on 5/11/26.
//  Copyright © 2026 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with Microsoft User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with Microsoft](https://website.parseplatform.org/parse-server/api/8.1.0/MicrosoftAdapter.html).
 For information on acquiring Microsoft sign-in credentials to use with `ParseMicrosoft`, refer to [Microsoft's Documentation](https://learn.microsoft.com/en-us/graph/auth-v2-user).
 */
public struct ParseMicrosoft<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Microsoft authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case accessToken = "access_token"
        case code
        case redirectURI = "redirect_uri"

        /// Properly makes a secure authData dictionary with the required keys.
        /// - parameter code: Required authorization code from Microsoft.
        /// - parameter redirectURI: Required redirect URI used to acquire the authorization code.
        /// - returns: authData dictionary.
        func makeDictionary(code: String,
                            redirectURI: String) -> [String: String] {
            [
                AuthenticationKeys.code.rawValue: code,
                AuthenticationKeys.redirectURI.rawValue: redirectURI
            ]
        }

        /// Properly makes an insecure authData dictionary with the required keys.
        /// - parameter id: Required id for the user.
        /// - parameter accessToken: Required access token for Microsoft.
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
            let hasSecureKeys = authData[AuthenticationKeys.code.rawValue] != nil &&
                authData[AuthenticationKeys.redirectURI.rawValue] != nil
            let hasInsecureKeys = authData[AuthenticationKeys.id.rawValue] != nil &&
                authData[AuthenticationKeys.accessToken.rawValue] != nil

            return hasSecureKeys || hasInsecureKeys
        }
    }

    public static var __type: String { // swiftlint:disable:this identifier_name
        "microsoft"
    }

    public init() { }
}

// MARK: Login
public extension ParseMicrosoft {

    /**
     Login a `ParseUser` *asynchronously* using secure Microsoft authentication.
     - parameter code: The authorization code from **Microsoft**.
     - parameter redirectURI: The redirect URI used to acquire the authorization code from **Microsoft**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(code: String,
               redirectURI: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let microsoftAuthData = AuthenticationKeys.code
            .makeDictionary(code: code,
                            redirectURI: redirectURI)
        login(authData: microsoftAuthData,
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }

    /**
     Login a `ParseUser` *asynchronously* using insecure Microsoft authentication.
     - parameter id: The **id** from **Microsoft**.
     - parameter accessToken: Required **access_token** from **Microsoft**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(id: String,
               accessToken: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let microsoftAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken)
        login(authData: microsoftAuthData,
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }

    func login(authData: [String: String],
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData) else {
            callbackQueue.async {
                completion(.failure(.init(
                    code: .unknownError,
                    message: "Should have authData consisting of keys \"code\" and \"redirect_uri\" or \"id\" and \"access_token\"."
                )))
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
public extension ParseMicrosoft {

    /**
     Link the *current* `ParseUser` *asynchronously* using secure Microsoft authentication.
     - parameter code: The authorization code from **Microsoft**.
     - parameter redirectURI: The redirect URI used to acquire the authorization code from **Microsoft**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(code: String,
              redirectURI: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let microsoftAuthData = AuthenticationKeys.code
            .makeDictionary(code: code,
                            redirectURI: redirectURI)
        link(authData: microsoftAuthData,
             options: options,
             callbackQueue: callbackQueue,
             completion: completion)
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using insecure Microsoft authentication.
     - parameter id: The **id** from **Microsoft**.
     - parameter accessToken: Required **access_token** from **Microsoft**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(id: String,
              accessToken: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let microsoftAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken)
        link(authData: microsoftAuthData,
             options: options,
             callbackQueue: callbackQueue,
             completion: completion)
    }

    func link(authData: [String: String],
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData) else {
            callbackQueue.async {
                completion(.failure(.init(
                    code: .unknownError,
                    message: "Should have authData consisting of keys \"code\" and \"redirect_uri\" or \"id\" and \"access_token\"."
                )))
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

// MARK: 3rd Party Authentication - ParseMicrosoft
public extension ParseUser {

    /// A microsoft `ParseUser`.
    static var microsoft: ParseMicrosoft<Self> {
        ParseMicrosoft<Self>()
    }

    /// A microsoft `ParseUser`.
    var microsoft: ParseMicrosoft<Self> {
        Self.microsoft
    }
}
