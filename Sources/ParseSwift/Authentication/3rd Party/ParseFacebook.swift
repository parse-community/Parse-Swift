//
//  ParseFacebook.swift
//  ParseSwift
//
//  Created by Abdulaziz Alhomaidhi on 3/18/21.
//  Copyright © 2021 Parse Community. All rights reserved.

import Foundation
#if canImport(Combine)
import Combine
#endif

// swiftlint:disable line_length

/**
 Provides utility functions for working with Facebook User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with Facebook](https://docs.parseplatform.org/parse-server/guide/#configuring-parse-server-for-sign-in-with-facebook).
 For information on acquiring Facebook sign-in credentials to use with `ParseFacebook`, refer to [Facebook's Documentation](https://developers.facebook.com/docs/facebook-login/limited-login.
 */
public struct ParseFacebook<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Facebook authentication.
    enum AuthenticationKeys: String, Codable {
        case id // swiftlint:disable:this identifier_name
        case token

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter facebookId: Required id for the user.
        /// - parameter authToken: Required identity token for the user.
        /// - returns: Required authData dictionary.
        func makeDictionary(facebookId: String,
                            authToken: String) -> [String: String]? {

            return [AuthenticationKeys.id.rawValue: facebookId,
             AuthenticationKeys.token.rawValue: authToken]
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: `true` if all the mandatory keys are present, `false` otherwise.
        func verifyMandatoryKeys(authData: [String: String]?) -> Bool {
            guard let authData = authData,
                  authData[AuthenticationKeys.id.rawValue] != nil,
                  authData[AuthenticationKeys.token.rawValue] != nil else {
                return false
            }
            return true
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
     Login a `ParseUser` *asynchronously* using Facebook authentication.
     - parameter withFacebookId: The `Facebook userId` from `FacebookSDK`.
     - parameter authToken: The `authToken` from `FacebookSDK`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */

    func login(withFacebookId: String,
               authToken: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        guard let facebookAuthData = AuthenticationKeys.id.makeDictionary(facebookId: withFacebookId, authToken: authToken) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: "Couldn't create authData.")))
            }
            return
        }
        login(authData: facebookAuthData,
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
     Login a `ParseUser` *asynchronously* using Facebook authentication. Publishes when complete.
     - parameter user: The `user` from `FacebookSDK`.
     - parameter authToken: The `authToken` from `FacebookSDK`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func loginPublisher(user: String,
                        authToken: String,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        guard let facebookAuthData = AuthenticationKeys.id.makeDictionary(facebookId: user, authToken: authToken) else {
            return Future { promise in
                promise(.failure(.init(code: .unknownError,
                                       message: "Couldn't create authData.")))
            }
        }
        return loginPublisher(authData: facebookAuthData,
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
public extension ParseFacebook {

    /**
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication.
     - parameter user: The `user` from `FacebookSDK`.
     - parameter authToken: The `authToken` from `FacebookSDK`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(user: String,
              authToken: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard let facebookAuthData = AuthenticationKeys.id.makeDictionary(facebookId: user, authToken: authToken) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: "Couldn't create authData.")))
            }
            return
        }
        link(authData: facebookAuthData,
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
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication. Publishes when complete.
     - parameter user: The `user` from `FacebookSDK`.
     - parameter authToken: The `authToken` from `FacebookSDK`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func linkPublisher(user: String,
                       authToken: String,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        guard let facebookAuthData = AuthenticationKeys.id.makeDictionary(facebookId: user, authToken: authToken) else {
            return Future { promise in
                promise(.failure(.init(code: .unknownError,
                                       message: "Couldn't create authData.")))
            }
        }
        return linkPublisher(authData: facebookAuthData,
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
