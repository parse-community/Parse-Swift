//
//  ParseLDAP.swift
//  ParseSwift
//
//  Created by Corey Baker on 2/14/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

// swiftlint:disable line_length

/**
 Provides utility functions for working with LDAP User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with LDAP](https://docs.parseplatform.org/parse-server/guide/#configuring-parse-server-for-ldap).
 */
public struct ParseLDAP<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for LDAP authentication.
    enum AuthenticationKeys: String, Codable {
        case id // swiftlint:disable:this identifier_name
        case password

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter id: Required id.
        /// - parameter password: Required password.
        /// - returns: authData dictionary.
        func makeDictionary(id: String, // swiftlint:disable:this identifier_name
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
    func login(id: String, // swiftlint:disable:this identifier_name
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

    #if canImport(Combine)

    /**
     Login a `ParseUser` *asynchronously* using LDAP authentication. Publishes when complete.
     - parameter id: The id of the `user`.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func loginPublisher(id: String, // swiftlint:disable:this identifier_name
                        password: String,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(id: id,
                       password: password,
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
public extension ParseLDAP {

    /**
     Link the *current* `ParseUser` *asynchronously* using LDAP authentication.
     - parameter id: The id of the `user`.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(id: String, // swiftlint:disable:this identifier_name
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

    #if canImport(Combine)

    /**
     Link the *current* `ParseUser` *asynchronously* using LDAP authentication. Publishes when complete.
     - parameter id: The id of the `user`.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func linkPublisher(id: String, // swiftlint:disable:this identifier_name
                       password: String,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(id: id,
                      password: password,
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
