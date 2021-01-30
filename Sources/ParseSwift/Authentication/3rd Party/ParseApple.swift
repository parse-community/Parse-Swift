//
//  ParseApple.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/14/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

// swiftlint:disable line_length

/**
 Provides utility functions for working with Apple User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with Apple](https://docs.parseplatform.org/parse-server/guide/#configuring-parse-server-for-sign-in-with-apple).
 For information on acquiring Apple sign-in credentials to use with `ParseApple`, refer to [Apple's Documentation](https://developer.apple.com/documentation/authenticationservices/implementing_user_authentication_with_sign_in_with_apple).
 */
public struct ParseApple<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Apple authentication.
    enum AuthenticationKeys: String, Codable {
        case id // swiftlint:disable:this identifier_name
        case token

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter id: Required id.
        /// - parameter token: Required token.
        /// - returns: Required authData dictionary.
        func makeDictionary(user: String,
                            identityToken: String) -> [String: String] {
            [AuthenticationKeys.id.rawValue: user,
             AuthenticationKeys.token.rawValue: identityToken]
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
        "apple"
    }
    public init() { }
}

// MARK: Login
public extension ParseApple {
    /**
     Login a `ParseUser` *asynchronously* using Apple authentication.
     - parameter user: The `user` from `ASAuthorizationAppleIDCredential`.
     - parameter identityToken: The `identityToken` from `ASAuthorizationAppleIDCredential`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(user: String,
               identityToken: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        login(authData: AuthenticationKeys.id.makeDictionary(user: user, identityToken: identityToken),
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
     Login a `ParseUser` *asynchronously* using Apple authentication. Publishes when complete.
     - parameter user: The `user` from `ASAuthorizationAppleIDCredential`.
     - parameter identityToken: The `identityToken` from `ASAuthorizationAppleIDCredential`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func loginPublisher(user: String,
                        identityToken: String,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        loginPublisher(authData: AuthenticationKeys.id.makeDictionary(user: user, identityToken: identityToken),
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
public extension ParseApple {

    /**
     Link the *current* `ParseUser` *asynchronously* using Apple authentication.
     - parameter user: The `user` from `ASAuthorizationAppleIDCredential`.
     - parameter identityToken: The `identityToken` from `ASAuthorizationAppleIDCredential`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(user: String,
              identityToken: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        link(authData: AuthenticationKeys.id.makeDictionary(user: user, identityToken: identityToken),
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
     Link the *current* `ParseUser` *asynchronously* using Apple authentication. Publishes when complete.
     - parameter user: The `user` from `ASAuthorizationAppleIDCredential`.
     - parameter identityToken: The `identityToken` from `ASAuthorizationAppleIDCredential`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func linkPublisher(user: String,
                       identityToken: String,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        linkPublisher(authData: AuthenticationKeys.id.makeDictionary(user: user, identityToken: identityToken),
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

// MARK: 3rd Party Authentication - ParseApple
public extension ParseUser {

    /// An apple `ParseUser`.
    static var apple: ParseApple<Self> {
        ParseApple<Self>()
    }

    /// An apple `ParseUser`.
    var apple: ParseApple<Self> {
        Self.apple
    }
}
