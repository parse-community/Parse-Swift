//
//  ParseMicrosoft.swift
//  ParseSwift
//
//  Created by DENGXUELIN on 5/13/26.
//  Copyright © 2026 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with Microsoft User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with Microsoft](https://docs.parseplatform.org/parse-server/guide/#microsoft-authdata)
 For information on acquiring Microsoft sign-in credentials to use with `ParseMicrosoft`, refer to [Microsoft Graph's Documentation](https://learn.microsoft.com/en-us/graph/auth/).
 */
public struct ParseMicrosoft<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Microsoft authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case code
        case redirectURI = "redirect_uri"
        case accessToken = "access_token"

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter code: Required code for Microsoft.
        /// - parameter redirectURI: Required redirect URI for Microsoft.
        /// - parameter id: Optional id for the user.
        /// - returns: authData dictionary.
        func makeDictionary(code: String,
                            redirectURI: String,
                            id: String? = nil) -> [String: String] {

            var returnDictionary = [
                AuthenticationKeys.code.rawValue: code,
                AuthenticationKeys.redirectURI.rawValue: redirectURI
            ]
            if let id = id {
                returnDictionary[AuthenticationKeys.id.rawValue] = id
            }
            return returnDictionary
        }

        /// Properly makes an authData dictionary with the keys used by Parse Server's insecure auth mode.
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
        "microsoft"
    }

    public init() { }
}

// MARK: Login
public extension ParseMicrosoft {

    /**
     Login a `ParseUser` *asynchronously* using Microsoft authentication.
     - parameter code: Required **code** from **Microsoft**.
     - parameter redirectURI: Required **redirect_uri** from **Microsoft**.
     - parameter id: Optional **id** from **Microsoft**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(code: String,
               redirectURI: String,
               id: String? = nil,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let microsoftAuthData = AuthenticationKeys.id
            .makeDictionary(code: code,
                            redirectURI: redirectURI,
                            id: id)
        login(authData: microsoftAuthData,
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }

    /**
     Login a `ParseUser` *asynchronously* using Microsoft authentication in Parse Server's insecure auth mode.
     - parameter id: Required **id** from **Microsoft**.
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
public extension ParseMicrosoft {

    /**
     Link the *current* `ParseUser` *asynchronously* using Microsoft authentication.
     - parameter code: Required **code** from **Microsoft**.
     - parameter redirectURI: Required **redirect_uri** from **Microsoft**.
     - parameter id: Optional **id** from **Microsoft**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(code: String,
              redirectURI: String,
              id: String? = nil,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let microsoftAuthData = AuthenticationKeys.id
            .makeDictionary(code: code,
                            redirectURI: redirectURI,
                            id: id)
        link(authData: microsoftAuthData,
             options: options,
             callbackQueue: callbackQueue,
             completion: completion)
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Microsoft authentication in Parse Server's insecure auth mode.
     - parameter id: Required **id** from **Microsoft**.
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

// MARK: 3rd Party Authentication - ParseMicrosoft
public extension ParseUser {

    /// A Microsoft `ParseUser`.
    static var microsoft: ParseMicrosoft<Self> {
        ParseMicrosoft<Self>()
    }

    /// A Microsoft `ParseUser`.
    var microsoft: ParseMicrosoft<Self> {
        Self.microsoft
    }
}
