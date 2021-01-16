//
//  ParseApple.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/14/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

public struct ParseApple<AuthenticatedUser: ParseUser>: ParseAuthenticatable {

    /// Authentication keys required for Apple authentication.
    enum AuthenticationKeys: String, Codable {
        case id // swiftlint:disable:this identifier_name
        case token

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter id: Required id.
        /// - parameter token: Required token.
        /// - returns: required authData dictionary.
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

    public var __type: String = "apple" // swiftlint:disable:this identifier_name
    public init() { }
}

// MARK: Login
public extension ParseApple {
    static func login(user: String,
                      identityToken: String,
                      options: API.Options = []) throws -> AuthenticatedUser {
        try ParseApple
            .login(authData: AuthenticationKeys.id.makeDictionary(user: user, identityToken: identityToken),
                   options: options)
    }

    static func login(user: String,
                      identityToken: String,
                      options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        ParseApple.login(authData: AuthenticationKeys.id.makeDictionary(user: user, identityToken: identityToken),
                         options: options,
                         callbackQueue: callbackQueue,
                         completion: completion)
    }

    static func login(authData: [String: String]?,
                      options: API.Options = []) throws -> AuthenticatedUser {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData),
              let authData = authData else {
            throw ParseError(code: .unknownError,
                             message: "Should have authData in consisting of keys \"id\" and \"token\".")
        }
        let appleUser = Self.init()
        return try AuthenticatedUser
            .login(appleUser.__type,
                   authData: authData,
                   options: options)
    }

    static func login(authData: [String: String]?,
                      options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData),
              let authData = authData else {
            let error = ParseError(code: .unknownError,
                                   message: "Should have authData in consisting of keys \"id\" and \"token\".")
            completion(.failure(error))
            return
        }
        let appleUser = Self.init()
        AuthenticatedUser.login(appleUser.__type,
                                authData: authData,
                                options: options,
                                completion: completion)
    }
}

// MARK: Link
public extension ParseApple {
    static func link(user: String,
                     identityToken: String,
                     options: API.Options = []) throws -> AuthenticatedUser {
        try ParseApple
            .link(authData: AuthenticationKeys.id.makeDictionary(user: user, identityToken: identityToken),
                  options: options)
    }

    static func link(user: String,
                     identityToken: String,
                     options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        ParseApple.link(authData: AuthenticationKeys.id.makeDictionary(user: user, identityToken: identityToken),
                        options: options,
                        callbackQueue: callbackQueue,
                        completion: completion)
    }

    static func link(authData: [String: String]?,
                     options: API.Options = []) throws -> AuthenticatedUser {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData),
              let authData = authData else {
            throw ParseError(code: .unknownError,
                             message: "Should have authData in consisting of keys \"id\" and \"token\".")
        }
        let appleUser = Self.init()
        return try AuthenticatedUser
            .link(appleUser.__type,
                  authData: authData,
                  options: options)
    }

    static func link(authData: [String: String]?,
                     options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData),
              let authData = authData else {
            let error = ParseError(code: .unknownError,
                                   message: "Should have authData in consisting of keys \"id\" and \"token\".")
            completion(.failure(error))
            return
        }
        let appleUser = Self.init()
        AuthenticatedUser.link(appleUser.__type,
                               authData: authData,
                               options: options,
                               completion: completion)
    }
}

// MARK: ParseApple
public extension ParseUser {

    /// An anonymous `ParseUser`.
    var apple: ParseApple<Self> {
        ParseApple<Self>()
    }

    /**
     Whether the `ParseUser` is logged in with the respective authentication type.
     - returns: `true` if the `ParseUser` is logged in via the repective
     authentication type. `false` if the user is not.
     */
    func isLinkedApple() -> Bool {
        apple.isLinked(with: self)
    }

    /**
     Unlink the `ParseUser` *asynchronously* from the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     */
    func unlinkApple(options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     completion: @escaping (Result<Self, ParseError>) -> Void) {
        apple.unlink(self, options: options, callbackQueue: callbackQueue, completion: completion)
    }

    /**
     Strips the `ParseUser`of a respective authentication type.
     - returns: the user whose autentication type was stripped. This modified user has not been saved.
     */
    func stripApple() -> Self {
        apple.strip(self)
    }
}
