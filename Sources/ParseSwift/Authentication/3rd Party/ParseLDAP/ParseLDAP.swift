//
//  ParseLDAP.swift
//  ParseSwift
//
//  Created by Corey Baker on 2/14/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with LDAP User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with LDAP](https://docs.parseplatform.org/parse-server/guide/#configuring-parse-server-for-ldap).
 */
public struct ParseLDAP<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for LDAP authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case password

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter id: Required id.
        /// - parameter password: Required password.
        /// - returns: authData dictionary.
        func makeDictionary(id: String,
                            password: String) -> [String: String] {
            [AuthenticationKeys.id.rawValue: id,
             AuthenticationKeys.password.rawValue: password]
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: `true` if all the mandatory keys are present, `false` otherwise.
        func verifyMandatoryKeys(authData: [String: String]) -> Bool {
            guard authData[AuthenticationKeys.id.rawValue] != nil,
                  authData[AuthenticationKeys.password.rawValue] != nil else {
                return false
            }
            return true
        }
    }
    public static var __type: String { // swiftlint:disable:this identifier_name
        "ldap"
    }
    public init() { }
}

// MARK: Login
public extension ParseLDAP {
    /**
     Login a `ParseUser` *asynchronously* using LDAP authentication.
     - parameter id: The id of the `user`.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(id: String,
               password: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        login(authData: AuthenticationKeys.id.makeDictionary(id: id,
                                                             password: password),
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
                                          message: "Should have authData in consisting of keys \"id\" and \"password\".")))
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
public extension ParseLDAP {

    /**
     Link the *current* `ParseUser` *asynchronously* using LDAP authentication.
     - parameter id: The id of the `user`.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(id: String,
              password: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        link(authData: AuthenticationKeys.id.makeDictionary(id: id, password: password),
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
                                   message: "Should have authData in consisting of keys \"id\" and \"password\".")
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

// MARK: 3rd Party Authentication - ParseLDAP
public extension ParseUser {

    /// An ldap `ParseUser`.
    static var ldap: ParseLDAP<Self> {
        ParseLDAP<Self>()
    }

    /// An ldap `ParseUser`.
    var ldap: ParseLDAP<Self> {
        Self.ldap
    }
}
