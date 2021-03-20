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
// swiftlint:disable function_parameter_count

/**
 Provides utility functions for working with Twitter User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with Twitter](https://docs.parseplatform.org/parse-server/guide/#configuring-parse-server-for-sign-in-with-twitter).
 For information on acquiring Twitter sign-in credentials to use with `ParseTwitter`, refer to [Twitter's Documentation](https://developer.twitter.com/en/docs/authentication/guides/log-in-with-twitter.
 */
public struct ParseTwitter<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Twitter authentication.
    enum AuthenticationKeys: String, Codable {
        case id // swiftlint:disable:this identifier_name
        case consumerKey
        case consumerSecret
        case authToken
        case authTokenSecret
        case screenName

        enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
          case id // swiftlint:disable:this identifier_name
          case consumerKey = "consumer_key"
          case consumerSecret = "consumer_secret"
          case authToken = "auth_token"
          case authTokenSecret = "auth_token_secret"
          case screenName  = "screen_name"
        }

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter twitterId: Required id for the user.
        /// - parameter screenName: The `Twitter screenName` from `Twitter session`.
        /// - parameter consumerKey: The `Twitter consumerKey` from `Twitter SDK`
        /// - parameter consumerSecret: The `Twitter consumerSecret` from `Twitter SDK`..
        /// - parameter authToken: Required Twitter authToken obtained from Twitter SDK for the user.
        /// - parameter authTokenSecret: Required Twitter authSecretToken obtained from Twitter SDK for the user.
        /// - returns: authData dictionary.
        func makeDictionary(twitterId: String,
                            screenName: String,
                            consumerKey: String,
                            consumerSecret: String,
                            authToken: String,
                            authTokenSecret: String) -> [String: String] {

            return [AuthenticationKeys.id.rawValue: twitterId,
                    AuthenticationKeys.screenName.rawValue: screenName,
                    AuthenticationKeys.consumerKey.rawValue: consumerKey,
                    AuthenticationKeys.consumerSecret.rawValue: consumerSecret,
             AuthenticationKeys.authToken.rawValue: authToken,
             AuthenticationKeys.authTokenSecret.rawValue: authTokenSecret]
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: `true` if all the mandatory keys are present, `false` otherwise.
        func verifyMandatoryKeys(authData: [String: String]) -> Bool {
            guard authData[AuthenticationKeys.id.rawValue] != nil,
                  authData[AuthenticationKeys.consumerKey.rawValue] != nil,
                  authData[AuthenticationKeys.consumerSecret.rawValue] != nil,
                  authData[AuthenticationKeys.authToken.rawValue] != nil,
                  authData[AuthenticationKeys.authTokenSecret.rawValue] != nil else {
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
     - parameter screenName: The `Twitter screenName` from `Twitter session`.
     - parameter consumerKey: The `Twitter consumerKey` from `Twitter SDK`
     - parameter consumerSecret: The `Twitter consumerSecret` from `Twitter SDK`..
     - parameter authToken: The Twitter `authToken` obtained from Twitter SDK for the user.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter SDK for the user
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(twitterId: String,
               screenName: String,
               authToken: String,
               authTokenSecret: String,
               consumerKey: String,
               consumerSecret: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let twitterAuthData = AuthenticationKeys.id
            .makeDictionary(twitterId: twitterId,
                            screenName: screenName,
                            consumerKey: consumerKey,
                            consumerSecret: consumerSecret,
                            authToken: authToken,
                            authTokenSecret: authTokenSecret)
        login(authData: twitterAuthData,
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }

    func login(authData: [String: String],
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData) else {
            let error = ParseError(code: .unknownError,
                                   message:
                                    """
                                    Should have authData consisting of keys \"id,\"
                                    \"screenName,\" \"consumerKey,\" \"consumerSecret,\"
                                    \"authToken,\" and \"authTokenSecret\".
                                    """)
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
     - parameter screenName: The `user screenName` from `Twitter session`.
     - parameter consumerKey: The `consumerKey` from `Twitter SDK`.
     - parameter consumerSecret: The `consumerSecret` from `Twitter SDK`.
     - parameter authToken: The Twitter `authToken` obtained from Twitter SDK for the user.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter SDK for the user
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func loginPublisher(user: String,
                        screenName: String,
                        consumerKey: String,
                        consumerSecret: String,
                        authToken: String,
                        authTokenSecret: String,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(twitterId: user,
                       screenName: screenName,
                       authToken: consumerKey,
                       authTokenSecret: consumerSecret,
                       consumerKey: authToken,
                       consumerSecret: authTokenSecret,
                       options: options,
                       completion: promise)
        }
    }

    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func loginPublisher(authData: [String: String],
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(authData: authData,
                       options: options,
                       completion: promise)
        }
    }

    #endif
}

// MARK: Link
public extension ParseTwitter {

    /**
     Link the *current* `ParseUser` *asynchronously* using Twitter authentication. Publishes when complete.
     - parameter user: The `user` from `Twitter SDK`.
     - parameter screenName: The `user screenName` from `Twitter session`.
     - parameter consumerKey: The `consumerKey` from `Twitter SDK`.
     - parameter consumerSecret: The `consumerSecret` from `Twitter SDK`.
     - parameter authToken: The Twitter `authToken` obtained from Twitter SDK for the user.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter SDK for the user
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func link(user: String,
              screenName: String,
              consumerKey: String,
              consumerSecret: String,
              authToken: String,
              authTokenSecret: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let twitterAuthData = AuthenticationKeys.id
            .makeDictionary(twitterId: user,
                            screenName: screenName,
                            consumerKey: consumerKey,
                            consumerSecret: consumerKey,
                            authToken: authToken,
                            authTokenSecret: authTokenSecret)
        link(authData: twitterAuthData,
             options: options,
             callbackQueue: callbackQueue,
             completion: completion)
    }

    func link(authData: [String: String],
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData) else {
            let error = ParseError(code: .unknownError,
                                   message:
                                    """
                                    Should have authData consisting of keys \"id,\"
                                    \"screenName,\" \"consumerKey,\" \"consumerSecret,\"
                                    \"authToken,\" and \"authTokenSecret\".
                                    """)
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
     - parameter screenName: The `user screenName` from `Twitter session`.
     - parameter consumerKey: The `consumerKey` from `Twitter SDK`.
     - parameter consumerSecret: The `consumerSecret` from `Twitter SDK`.
     - parameter authToken: The Twitter `authToken` obtained from Twitter SDK for the user.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter SDK for the user
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func linkPublisher(user: String,
                       screenName: String,
                       consumerKey: String,
                       consumerSecret: String,
                       authToken: String,
                       authTokenSecret: String,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(user: user,
                      screenName: screenName,
                      consumerKey: consumerKey,
                      consumerSecret: consumerSecret,
                      authToken: authToken,
                      authTokenSecret: authTokenSecret,
                      options: options,
                      completion: promise)
        }
    }

    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func linkPublisher(authData: [String: String],
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(authData: authData,
                      options: options,
                      completion: promise)
        }
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