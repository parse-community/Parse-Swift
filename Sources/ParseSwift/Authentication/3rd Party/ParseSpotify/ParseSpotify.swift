//
//  ParseSpotify.swift
//  ParseSwift
//
//  Created by Ulaş Sancak on 06/20/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with Spotify User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with Spotify](https://docs.parseplatform.org/parse-server/guide/#spotify-authdata)
 For information on acquiring Spotify sign-in credentials to use with `ParseSpotify`, refer to [Spotify's Documentation](https://developer.spotify.com/documentation/general/guides/authorization/)
 */
public struct ParseSpotify<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Spotify authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case accessToken = "access_token"

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter id: Required id for the user.
        /// - parameter accessToken: Required access token for Spotify.
        /// - returns: authData dictionary.
        func makeDictionary(id: String,
                            accessToken: String) -> [String: String] {

            let returnDictionary = [
                AuthenticationKeys.id.rawValue: id,
                AuthenticationKeys.accessToken.rawValue: accessToken
            ]
            return returnDictionary
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: **true** if all the mandatory keys are present, **false** otherwise.
        func verifyMandatoryKeys(authData: [String: String]) -> Bool {
            guard authData[AuthenticationKeys.id.rawValue] != nil,
                  authData[AuthenticationKeys.accessToken.rawValue] != nil else {
                return false
            }
            return true
        }
    }

    public static var __type: String { // swiftlint:disable:this identifier_name
        "spotify"
    }

    public init() { }
}

// MARK: Login
public extension ParseSpotify {

    /**
     Login a `ParseUser` *asynchronously* using Spotify authentication.
     - parameter id: The **Spotify profile id** from **Spotify**.
     - parameter accessToken: Required **access_token** from **Spotify**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(id: String,
               accessToken: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let spotifyAuthData = AuthenticationKeys.id
                .makeDictionary(id: id,
                                accessToken: accessToken)
//        print(spotifyAuthData)
        login(authData: spotifyAuthData,
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
                                          message: "Should have authData in consisting of keys \"id\" and \"accessToken\".")))
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
public extension ParseSpotify {

    /**
     Link the *current* `ParseUser` *asynchronously* using Spotify authentication.
     - parameter id: The **Spotify profile id** from **Spotify**.
     - parameter accessToken: Required **access_token** from **Spotify**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(id: String,
              accessToken: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let spotifyAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken)
        link(authData: spotifyAuthData,
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
                                          message: "Should have authData in consisting of keys \"id\" and \"accessToken\".")))
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

// MARK: 3rd Party Authentication - ParseSpotify
public extension ParseUser {

    /// A Spotify `ParseUser`.
    static var spotify: ParseSpotify<Self> {
        ParseSpotify<Self>()
    }

    /// An Spotify `ParseUser`.
    var spotify: ParseSpotify<Self> {
        Self.spotify
    }
}
