//
//  ParseJanrainEngage.swift
//  ParseSwift
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with Janrain Engage User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for Janrain Engage authentication using the `janrainengage` auth adapter.
 The Parse Server Janrain Engage adapter is deprecated and requires insecure auth adapters to be enabled server-side.
 */
public struct ParseJanrainEngage<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Janrain Engage authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case authToken = "auth_token"

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter id: Required Janrain Engage profile identifier.
        /// - parameter authToken: Required Janrain Engage auth token.
        /// - returns: authData dictionary.
        func makeDictionary(id: String,
                            authToken: String) -> [String: String] {
            [
                AuthenticationKeys.id.rawValue: id,
                AuthenticationKeys.authToken.rawValue: authToken
            ]
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: **true** if all the mandatory keys are present, **false** otherwise.
        func verifyMandatoryKeys(authData: [String: String]) -> Bool {
            guard authData[AuthenticationKeys.id.rawValue] != nil,
                  authData[AuthenticationKeys.authToken.rawValue] != nil else {
                return false
            }
            return true
        }
    }

    public static var __type: String { // swiftlint:disable:this identifier_name
        "janrainengage"
    }

    public init() { }
}

// MARK: Login
public extension ParseJanrainEngage {

    /**
     Login a `ParseUser` *asynchronously* using Janrain Engage authentication.
     - parameter id: The Janrain Engage profile identifier.
     - parameter authToken: Required Janrain Engage **auth_token**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(id: String,
               authToken: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let janrainEngageAuthData = AuthenticationKeys.id
            .makeDictionary(id: id, authToken: authToken)
        login(authData: janrainEngageAuthData,
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
                let message = "Should have authData consisting of keys \"id\" and \"auth_token\"."
                completion(.failure(.init(code: .unknownError, message: message)))
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
public extension ParseJanrainEngage {

    /**
     Link the *current* `ParseUser` *asynchronously* using Janrain Engage authentication.
     - parameter id: The Janrain Engage profile identifier.
     - parameter authToken: Required Janrain Engage **auth_token**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(id: String,
              authToken: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let janrainEngageAuthData = AuthenticationKeys.id
            .makeDictionary(id: id, authToken: authToken)
        link(authData: janrainEngageAuthData,
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
                let message = "Should have authData consisting of keys \"id\" and \"auth_token\"."
                completion(.failure(.init(code: .unknownError, message: message)))
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

// MARK: 3rd Party Authentication - ParseJanrainEngage
public extension ParseUser {

    /// A Janrain Engage `ParseUser`.
    static var janrainEngage: ParseJanrainEngage<Self> {
        ParseJanrainEngage<Self>()
    }

    /// A Janrain Engage `ParseUser`.
    var janrainEngage: ParseJanrainEngage<Self> {
        Self.janrainEngage
    }
}
