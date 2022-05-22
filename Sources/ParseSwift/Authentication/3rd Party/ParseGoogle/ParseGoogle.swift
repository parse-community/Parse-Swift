//
//  ParseGoogle.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/1/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with Google User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with Google](https://docs.parseplatform.org/parse-server/guide/#google-authdata).
 For information on acquiring Google sign-in credentials to use with `ParseGoogle`, refer to [Google's Documentation](https://developers.google.com/identity/protocols/oauth2).
 */
public struct ParseGoogle<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Google authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case idToken = "id_token"
        case accessToken = "access_token"

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter id: Required id for the user.
        /// - parameter idToken: Optional identity token for Google.
        /// - parameter accessToken: Optional identity token for Google.
        /// - returns: authData dictionary.
        func makeDictionary(id: String,
                            idToken: String? = nil,
                            accessToken: String? = nil) -> [String: String] {

            var returnDictionary = [AuthenticationKeys.id.rawValue: id]
            if let accessToken = accessToken {
              returnDictionary[AuthenticationKeys.accessToken.rawValue] = accessToken
            } else if let idToken = idToken {
              returnDictionary[AuthenticationKeys.idToken.rawValue] = idToken
            }
            return returnDictionary
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: **true** if all the mandatory keys are present, **false** otherwise.
        func verifyMandatoryKeys(authData: [String: String]) -> Bool {
            guard authData[AuthenticationKeys.id.rawValue] != nil else {
                return false
            }

            if authData[AuthenticationKeys.accessToken.rawValue] != nil ||
                authData[AuthenticationKeys.idToken.rawValue] != nil {
                return true
            }
            return false
        }
    }

    public static var __type: String { // swiftlint:disable:this identifier_name
        "google"
    }

    public init() { }
}

// MARK: Login
public extension ParseGoogle {

    /**
     Login a `ParseUser` *asynchronously* using Google authentication for graph API login.
     - parameter id: The `id` from **Google**.
     - parameter idToken: Optional **id_token** from **Google**.
     - parameter accessToken: Optional **access_token** from **Google**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(id: String,
               idToken: String? = nil,
               accessToken: String? = nil,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let googleAuthData = AuthenticationKeys.id
                .makeDictionary(id: id,
                                idToken: idToken,
                                accessToken: accessToken)
        login(authData: googleAuthData,
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
                                          message: "Should have authData in consisting of keys \"id\", \"idToken\" or \"accessToken\".")))
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
public extension ParseGoogle {

    /**
     Link the *current* `ParseUser` *asynchronously* using Google authentication for graph API login.
     - parameter id: The **id** from **Google**.
     - parameter idToken: Optional **id_token** from **Google**.
     - parameter accessToken: Optional **access_token** from **Google**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(id: String,
              idToken: String? = nil,
              accessToken: String? = nil,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let googleAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            idToken: idToken,
                            accessToken: accessToken)
        link(authData: googleAuthData,
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
                                          message: "Should have authData in consisting of keys \"id\", \"idToken\" or \"accessToken\".")))
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

// MARK: 3rd Party Authentication - ParseGoogle
public extension ParseUser {

    /// A google `ParseUser`.
    static var google: ParseGoogle<Self> {
        ParseGoogle<Self>()
    }

    /// An google `ParseUser`.
    var google: ParseGoogle<Self> {
        Self.google
    }
}
