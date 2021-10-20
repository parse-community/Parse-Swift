//
//  ParseApple.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/14/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with Apple User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with Apple](https://docs.parseplatform.org/parse-server/guide/#configuring-parse-server-for-sign-in-with-apple).
 For information on acquiring Apple sign-in credentials to use with `ParseApple`, refer to [Apple's Documentation](https://developer.apple.com/documentation/authenticationservices/implementing_user_authentication_with_sign_in_with_apple).
 */
public struct ParseApple<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Apple authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case token

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter user: Required id for the user.
        /// - parameter identityToken: Required identity token for the user.
        /// - returns: authData dictionary.
        /// - throws: `ParseError` if the `identityToken` can't be converted
        /// to a string.
        func makeDictionary(user: String,
                            identityToken: Data) throws -> [String: String] {
            guard let identityTokenString = String(data: identityToken, encoding: .utf8) else {
                throw ParseError(code: .unknownError, message: "Couldn't convert identityToken to String")
            }
            return [AuthenticationKeys.id.rawValue: user,
             AuthenticationKeys.token.rawValue: identityTokenString]
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: `true` if all the mandatory keys are present, `false` otherwise.
        func verifyMandatoryKeys(authData: [String: String]) -> Bool {
            guard authData[AuthenticationKeys.id.rawValue] != nil,
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
               identityToken: Data,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        guard let appleAuthData = try? AuthenticationKeys.id.makeDictionary(user: user, identityToken: identityToken) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: "Couldn't create authData.")))
            }
            return
        }
        login(authData: appleAuthData,
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
                                          message: "Should have authData in consisting of keys \"id\" and \"token\".")))
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
              identityToken: Data,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard let appleAuthData = try? AuthenticationKeys.id.makeDictionary(user: user, identityToken: identityToken) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: "Couldn't create authData.")))
            }
            return
        }
        link(authData: appleAuthData,
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
