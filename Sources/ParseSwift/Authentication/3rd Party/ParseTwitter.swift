//
//  ParseTwitter.swift
//  ParseSwift
//
//  Created by Abdulaziz Alhomaidhi on 3/17/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

// swiftlint:disable line_length

/**
 Provides utility functions for working with Twitter User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with Twitter](https://docs.parseplatform.org/parse-server/guide/#configuring-parse-server-for-sign-in-with-twitter).
 For information on acquiring Twitter sign-in credentials to use with `ParseTwitter`, refer to [Twitter's Documentation](https://developer.twitter.com/en/docs/authentication/guides/log-in-with-twitter.
 */
public struct ParseTwitter<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Twitter authentication.
    enum AuthenticationKeys: String, Codable {
        case id // swiftlint:disable:this identifier_name
        case token
        case tokenSecret

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter twitterId: Required id for the user.
        /// - parameter authToken: Required Twitter authToken obtained from Twitter SDK for the user.
        /// - parameter authTokenSecret: Required Twitter authSecretToken obtained from Twitter SDK for the user.
        /// - returns: Required authData dictionary.
        func makeDictionary(twitterId: String,
                            authToken: String,
                            authTokenSecret: String) -> [String: String]? {

            return [AuthenticationKeys.id.rawValue: twitterId,
             AuthenticationKeys.token.rawValue: authToken,
             AuthenticationKeys.tokenSecret.rawValue: authTokenSecret]
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: `true` if all the mandatory keys are present, `false` otherwise.
        func verifyMandatoryKeys(authData: [String: String]?) -> Bool {
            guard let authData = authData,
                  authData[AuthenticationKeys.id.rawValue] != nil,
                  authData[AuthenticationKeys.token.rawValue] != nil,
                  authData[AuthenticationKeys.tokenSecret.rawValue] != nil else {
                return false
            }
            return true
        }
    }
    public static var __type: String { // swiftlint:disable:this identifier_name
        "twitter"
    }
    public init() { }
}

// MARK: Login
public extension ParseTwitter {
    /**
     Login a `ParseUser` *asynchronously* using Twitter authentication.
     - parameter twitterId: The `Twitter userId` from `Twitter session`.
     - parameter username: The `Twitter username` from `Twitter session`.
     - parameter authToken: The Twitter `authToken` obtained from Twitter SDK for the user.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter SDK for the user
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */

    func login(withTwitterId: String,
               username: String,
               authToken: String,
               authTokenSecret: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        guard let twitterAuthData = AuthenticationKeys.id.makeDictionary(twitterId: withTwitterId, authToken: authToken, authTokenSecret: authTokenSecret) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: "Couldn't create authData.")))
            }
            return
        }
        login(authData: twitterAuthData,
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }

    func login(authData: [String: String]?,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData),
              let authData = authData else {
            let error = ParseError(code: .unknownError,
                                   message: "Should have authData in consisting of keys \"id\" and \"token\".")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        AuthenticatedUser.login(Self.__type,
                                authData: authData,
                                options: options,
                                callbackQueue: callbackQueue,
                                completion: completion)
    }
    
    #if canImport(Combine)

    /**
     Login a `ParseUser` *asynchronously* using Twitter authentication. Publishes when complete.
     - parameter user: The `user` from `Twitter SDK`.
     - parameter authToken: The Twitter `authToken` obtained from Twitter SDK for the user.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter SDK for the user
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func loginPublisher(user: String,
                        authToken: String,
                        authTokenSecret: String,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        guard let twitterAuthData = AuthenticationKeys.id.makeDictionary(twitterId: user, authToken: authToken, authTokenSecret: authTokenSecret) else {
            return Future { promise in
                promise(.failure(.init(code: .unknownError,
                                       message: "Couldn't create authData.")))
            }
        }
        return loginPublisher(authData: twitterAuthData,
                              options: options)
    }

    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func loginPublisher(authData: [String: String]?,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData),
              let authData = authData else {
            let error = ParseError(code: .unknownError,
                                   message: "Should have authData in consisting of keys \"id\" and \"token\".")
            return Future { promise in
                promise(.failure(error))
            }
        }
        return AuthenticatedUser.loginPublisher(Self.__type,
                                                authData: authData,
                                                options: options)
    }

    #endif
}

// MARK: Link
public extension ParseTwitter {

    /**
     Link the *current* `ParseUser` *asynchronously* using Twitter authentication.
     - parameter user: The `user` from `Twitter SDK`.
     - parameter authToken: The Twitter `authToken` obtained from Twitter SDK for the user.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter SDK for the user
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(user: String,
              authToken: String,
              authTokenSecret: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard let twitterAuthData = AuthenticationKeys.id.makeDictionary(twitterId: user, authToken: authToken, authTokenSecret: authTokenSecret) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: "Couldn't create authData.")))
            }
            return
        }
        link(authData: twitterAuthData,
             options: options,
             callbackQueue: callbackQueue,
             completion: completion)
    }

    func link(authData: [String: String]?,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData),
              let authData = authData else {
            let error = ParseError(code: .unknownError,
                                   message: "Should have authData in consisting of keys \"id\" and \"token\".")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        AuthenticatedUser.link(Self.__type,
                               authData: authData,
                               options: options,
                               callbackQueue: callbackQueue,
                               completion: completion)
    }

    #if canImport(Combine)

    /**
     Link the *current* `ParseUser` *asynchronously* using Twitter authentication. Publishes when complete.
     - parameter user: The `user` from `Twitter SDK`.
     - parameter authToken: The Twitter `authToken` obtained from Twitter SDK for the user.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter SDK for the user
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func linkPublisher(user: String,
                       authToken: String,
                       authTokenSecret: String,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        guard let twitterAuthData = AuthenticationKeys.id.makeDictionary(twitterId: user, authToken: authToken, authTokenSecret: authTokenSecret) else {
            return Future { promise in
                promise(.failure(.init(code: .unknownError,
                                       message: "Couldn't create authData.")))
            }
        }
        return linkPublisher(authData: twitterAuthData,
             options: options)
    }

    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func linkPublisher(authData: [String: String]?,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData),
              let authData = authData else {
            let error = ParseError(code: .unknownError,
                                   message: "Should have authData in consisting of keys \"id\" and \"token\".")
            return Future { promise in
                promise(.failure(error))
            }
        }
        return AuthenticatedUser.linkPublisher(Self.__type,
                                               authData: authData,
                                               options: options)
    }

    #endif
}

// MARK: 3rd Party Authentication - ParseTwitter
public extension ParseUser {

    /// A twitter `ParseUser`.
    static var twitter: ParseTwitter<Self> {
        ParseTwitter<Self>()
    }

    /// A twitter`ParseUser`.
    var twitter: ParseTwitter<Self> {
        Self.twitter
    }
}
