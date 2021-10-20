//
//  ParseFacebook.swift
//  ParseSwift
//
//  Created by Abdulaziz Alhomaidhi on 3/18/21.
//  Copyright © 2021 Parse Community. All rights reserved.

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with Facebook User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with Facebook](https://docs.parseplatform.org/parse-server/guide/#configuring-parse-server-for-sign-in-with-facebook).
 For information on acquiring Facebook sign-in credentials to use with `ParseFacebook`, refer to [Facebook's Documentation](https://developers.facebook.com/docs/facebook-login/limited-login).
 */
public struct ParseFacebook<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Facebook authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case authenticationToken = "token"
        case accessToken = "access_token"
        case expirationDate = "expiration_date"

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter userId: Required id for the user.
        /// - parameter authenticationToken: Required identity token for Facebook limited login.
        /// - parameter accessToken: Required identity token for Facebook graph API.
        /// - parameter expiresIn: Optional expiration in seconds for Facebook login.
        /// - returns: authData dictionary.
        func makeDictionary(userId: String,
                            accessToken: String?,
                            authenticationToken: String?,
                            expiresIn: Int? = nil) -> [String: String] {

            var returnDictionary = [AuthenticationKeys.id.rawValue: userId]
            if let expiresIn = expiresIn,
                let expirationDate = Calendar.current.date(byAdding: .second,
                                                             value: expiresIn,
                                                             to: Date()) {
                let dateString = ParseCoding.dateFormatter.string(from: expirationDate)
                returnDictionary[AuthenticationKeys.expirationDate.rawValue] = dateString
            }

            if let accessToken = accessToken {
              returnDictionary[AuthenticationKeys.accessToken.rawValue] = accessToken
            } else if let authenticationToken = authenticationToken {
              returnDictionary[AuthenticationKeys.authenticationToken.rawValue] = authenticationToken
            }
            return returnDictionary
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: `true` if all the mandatory keys are present, `false` otherwise.
        func verifyMandatoryKeys(authData: [String: String]) -> Bool {
            guard authData[AuthenticationKeys.id.rawValue] != nil else {
                return false
            }

            if authData[AuthenticationKeys.accessToken.rawValue] != nil ||
                authData[AuthenticationKeys.authenticationToken.rawValue] != nil {
                return true
            }
            return false
        }
    }

    public static var __type: String { // swiftlint:disable:this identifier_name
        "facebook"
    }

    public init() { }
}

// MARK: Login
public extension ParseFacebook {

    /**
     Login a `ParseUser` *asynchronously* using Facebook authentication for limited login.
     - parameter userId: The `Facebook userId` from `FacebookSDK`.
     - parameter authenticationToken: The `authenticationToken` from `FacebookSDK`.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(userId: String,
               authenticationToken: String,
               expiresIn: Int? = nil,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let facebookAuthData = AuthenticationKeys.id
                .makeDictionary(userId: userId, accessToken: nil,
                                authenticationToken: authenticationToken,
                                expiresIn: expiresIn)
        login(authData: facebookAuthData,
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }

    /**
     Login a `ParseUser` *asynchronously* using Facebook authentication for graph API login.
     - parameter userId: The `Facebook userId` from `FacebookSDK`.
     - parameter accessToken: The `accessToken` from `FacebookSDK`.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(userId: String,
               accessToken: String,
               expiresIn: Int? = nil,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let facebookAuthData = AuthenticationKeys.id
                .makeDictionary(userId: userId,
                                accessToken: accessToken,
                                authenticationToken: nil,
                                expiresIn: expiresIn)
        login(authData: facebookAuthData,
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
                                          message: "Should have authData in consisting of keys \"id\", \"expirationDate\" and \"authenticationToken\" or \"accessToken\".")))
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
public extension ParseFacebook {

    /**
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for limited login.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter authenticationToken: The `authenticationToken` from `FacebookSDK`.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(userId: String,
              authenticationToken: String,
              expiresIn: Int? = nil,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let facebookAuthData = AuthenticationKeys.id
            .makeDictionary(userId: userId,
                            accessToken: nil,
                            authenticationToken: authenticationToken,
                            expiresIn: expiresIn)
        link(authData: facebookAuthData,
             options: options,
             callbackQueue: callbackQueue,
             completion: completion)
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for graph API login.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter accessToken: The `accessToken` from `FacebookSDK`.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(userId: String,
              accessToken: String,
              expiresIn: Int? = nil,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let facebookAuthData = AuthenticationKeys.id
            .makeDictionary(userId: userId,
                            accessToken: accessToken,
                            authenticationToken: nil,
                            expiresIn: expiresIn)
        link(authData: facebookAuthData,
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
                                          message: "Should have authData in consisting of keys \"id\", \"expirationDate\" and \"authenticationToken\" or \"accessToken\".")))
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

// MARK: 3rd Party Authentication - ParseFacebook
public extension ParseUser {

    /// A facebook `ParseUser`.
    static var facebook: ParseFacebook<Self> {
        ParseFacebook<Self>()
    }

    /// An facebook `ParseUser`.
    var facebook: ParseFacebook<Self> {
        Self.facebook
    }
}
