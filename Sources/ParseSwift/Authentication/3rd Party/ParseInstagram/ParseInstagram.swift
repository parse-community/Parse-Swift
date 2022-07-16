//
//  ParseInstagram.swift
//  ParseSwift
//
//  Created by Ulaş Sancak on 06/19/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with Instagram User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with Instagram](https://docs.parseplatform.org/parse-server/guide/#instagram-authdata).
 For information on acquiring Instagram sign-in credentials to use with `ParseInstagram`, refer to [Facebook's Documentation](https://developers.facebook.com/docs/instagram-basic-display-api/overview).
 */
public struct ParseInstagram<AuthenticatedUser: ParseUser>: ParseAuthentication {

    public static var graphAPIBaseURL: String {
        "https://graph.instagram.com/"
    }

    /// Authentication keys required for Instagram authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case accessToken = "access_token"
        case apiURL

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter id: Required id for the user.
        /// - parameter accessToken: Required access token for Instagram.
        /// - returns: authData dictionary.
        func makeDictionary(id: String,
                            accessToken: String,
                            apiURL: String = ParseInstagram.graphAPIBaseURL) -> [String: String] {

            let returnDictionary = [
                AuthenticationKeys.id.rawValue: id,
                AuthenticationKeys.accessToken.rawValue: accessToken,
                AuthenticationKeys.apiURL.rawValue: apiURL
            ]
            return returnDictionary
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: **true** if all the mandatory keys are present, **false** otherwise.
        func verifyMandatoryKeys(authData: [String: String]) -> Bool {
            guard authData[AuthenticationKeys.id.rawValue] != nil,
                  authData[AuthenticationKeys.accessToken.rawValue] != nil,
                  authData[AuthenticationKeys.apiURL.rawValue] != nil else {
                return false
            }
            return true
        }
    }

    public static var __type: String { // swiftlint:disable:this identifier_name
        "instagram"
    }

    public init() { }
}

// MARK: Login
public extension ParseInstagram {

    /**
     Login a `ParseUser` *asynchronously* using Instagram authentication.
     - parameter id: The **Instagram profile id** from **Instagram**.
     - parameter accessToken: Required **access_token** from **Instagram**.
     - parameter apiURL: The `Instagram's most recent graph api url` from **Instagram**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(id: String,
               accessToken: String,
               apiURL: String = Self.graphAPIBaseURL,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let instagramAuthData = AuthenticationKeys.id
                .makeDictionary(id: id,
                                accessToken: accessToken,
                                apiURL: apiURL)
        login(authData: instagramAuthData,
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
                                          message: "Should have authData in consisting of keys \"id\", \"accessToken\", and \"isMobileSDK\".")))
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
public extension ParseInstagram {

    /**
     Link the *current* `ParseUser` *asynchronously* using Instagram authentication.
     - parameter id: The **Instagram profile id** from **Instagram**.
     - parameter accessToken: Required **access_token** from **Instagram**.
     - parameter apiURL: The `Instagram's most recent graph api url` from **Instagram**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(id: String,
              accessToken: String,
              apiURL: String = Self.graphAPIBaseURL,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let instagramAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken,
                            apiURL: apiURL)
        link(authData: instagramAuthData,
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
                                          message: "Should have authData in consisting of keys \"id\", \"accessToken\", and \"isMobileSDK\".")))
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

// MARK: 3rd Party Authentication - ParseInstagram
public extension ParseUser {

    /// A Instagram `ParseUser`.
    static var instagram: ParseInstagram<Self> {
        ParseInstagram<Self>()
    }

    /// An Instagram `ParseUser`.
    var instagram: ParseInstagram<Self> {
        Self.instagram
    }
}
