//
//  ParseTwitter.swift
//  ParseSwift
//
//  Created by Abdulaziz Alhomaidhi on 3/17/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length
// swiftlint:disable function_parameter_count

/**
 Provides utility functions for working with Twitter User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with Twitter](https://docs.parseplatform.org/parse-server/guide/#configuring-parse-server-for-sign-in-with-twitter).
 For information on acquiring Twitter sign-in credentials to use with `ParseTwitter`, refer to [Twitter's Documentation](https://developer.twitter.com/en/docs/authentication/guides/log-in-with-twitter).
 */
public struct ParseTwitter<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Twitter authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case consumerKey = "consumer_key"
        case consumerSecret = "consumer_secret"
        case authToken = "auth_token"
        case authTokenSecret = "auth_token_secret"
        case screenName  = "screen_name"

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter userId: Required id.
        /// - parameter screenName: The `Twitter screenName` from `Twitter`.
        /// - parameter consumerKey: The `Twitter consumerKey` from `Twitter`.
        /// - parameter consumerSecret: The `Twitter consumerSecret` from `Twitter`.
        /// - parameter authToken: Required Twitter authToken obtained from Twitter.
        /// - parameter authTokenSecret: Required Twitter authSecretToken obtained from Twitter.
        /// - returns: authData dictionary.
        func makeDictionary(userId: String,
                            screenName: String?,
                            consumerKey: String,
                            consumerSecret: String,
                            authToken: String,
                            authTokenSecret: String) -> [String: String] {
            var dictionary = [AuthenticationKeys.id.rawValue: userId,
                              AuthenticationKeys.consumerKey.rawValue: consumerKey,
                              AuthenticationKeys.consumerSecret.rawValue: consumerSecret,
                              AuthenticationKeys.authToken.rawValue: authToken,
                              AuthenticationKeys.authTokenSecret.rawValue: authTokenSecret]
            if let screenName = screenName {
                dictionary[AuthenticationKeys.screenName.rawValue] = screenName
            }
            return dictionary
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
     - parameter userId: The `Twitter userId` from `Twitter`.
     - parameter screenName: The `Twitter screenName` from `Twitter`.
     - parameter consumerKey: The `Twitter consumerKey` from `Twitter`.
     - parameter consumerSecret: The `Twitter consumerSecret` from `Twitter`.
     - parameter authToken: The Twitter `authToken` obtained from Twitter.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(userId: String,
               screenName: String? = nil,
               authToken: String,
               authTokenSecret: String,
               consumerKey: String,
               consumerSecret: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let twitterAuthData = AuthenticationKeys.id
            .makeDictionary(userId: userId,
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
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message:
                                           """
                                           Should have authData consisting of keys \"id,\"
                                           \"screenName,\" \"consumerKey,\" \"consumerSecret,\"
                                           \"authToken,\" and \"authTokenSecret\".
                                           """)))
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
public extension ParseTwitter {

    /**
     Link the *current* `ParseUser` *asynchronously* using Twitter authentication. Publishes when complete.
     - parameter user: The `userId` from `Twitter`.
     - parameter screenName: The `user screenName` from `Twitter`.
     - parameter consumerKey: The `consumerKey` from `Twitter`.
     - parameter consumerSecret: The `consumerSecret` from `Twitter`.
     - parameter authToken: The Twitter `authToken` obtained from Twitter.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func link(userId: String,
              screenName: String? = nil,
              consumerKey: String,
              consumerSecret: String,
              authToken: String,
              authTokenSecret: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let twitterAuthData = AuthenticationKeys.id
            .makeDictionary(userId: userId,
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
