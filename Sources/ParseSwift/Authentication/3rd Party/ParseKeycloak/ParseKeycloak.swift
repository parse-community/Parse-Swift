//
//  ParseKeycloak.swift
//  ParseSwift
//
//  Created by Parse Community on 5/13/26.
//  Copyright (c) 2026 Parse Community. All rights reserved.
//

import Foundation

private let parseKeycloakInvalidAuthDataMessage = "Should have authData consisting of keys \"id\" and " +
    "\"access_token\"."

/**
 Provides utility functions for working with Keycloak User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for Keycloak authentication.

 The Parse Server Keycloak adapter also supports optional `roles` and `groups` arrays. Parse-Swift's
 authentication helpers currently model authData as string key-value pairs, so this helper captures the
 adapter's required `id` and `access_token` fields.

 If the Keycloak access token contains `roles` or `groups` claims that Parse Server validates, this helper
 cannot include those array-valued fields. Supporting that case requires a broader authData model change.
 */
public struct ParseKeycloak<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Keycloak authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case accessToken = "access_token"

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter id: Required Keycloak user subject (`sub`).
        /// - parameter accessToken: Required access_token from Keycloak.
        /// - returns: authData dictionary.
        func makeDictionary(id: String,
                            accessToken: String) -> [String: String] {
            [
                AuthenticationKeys.id.rawValue: id,
                AuthenticationKeys.accessToken.rawValue: accessToken
            ]
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: **true** if all the mandatory keys are present, **false** otherwise.
        func verifyMandatoryKeys(authData: [String: String]) -> Bool {
            guard authData[AuthenticationKeys.id.rawValue] != nil,
                  authData[AuthenticationKeys.accessToken.rawValue] != nil else {
                return false
            }
            return true
        }
    }

    /// The Parse Server authData provider type for Keycloak.
    public static var __type: String { // swiftlint:disable:this identifier_name
        "keycloak"
    }

    /// Creates a Keycloak authentication helper.
    public init() { }
}

// MARK: Login
public extension ParseKeycloak {

    /**
     Login a `ParseUser` *asynchronously* using Keycloak authentication.
     - parameter id: The Keycloak user subject (`sub`).
     - parameter accessToken: Required **access_token** from **Keycloak**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(id: String,
               accessToken: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let keycloakAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken)
        login(authData: keycloakAuthData,
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }

    /**
     Login a `ParseUser` *asynchronously* using Keycloak authData.
     - parameter authData: Dictionary containing the required Keycloak key/values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(authData: [String: String],
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: parseKeycloakInvalidAuthDataMessage)))
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
public extension ParseKeycloak {

    /**
     Link the *current* `ParseUser` *asynchronously* using Keycloak authentication.
     - parameter id: The Keycloak user subject (`sub`).
     - parameter accessToken: Required **access_token** from **Keycloak**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(id: String,
              accessToken: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let keycloakAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken)
        link(authData: keycloakAuthData,
             options: options,
             callbackQueue: callbackQueue,
             completion: completion)
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Keycloak authData.
     - parameter authData: Dictionary containing the required Keycloak key/values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(authData: [String: String],
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: parseKeycloakInvalidAuthDataMessage)))
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

// MARK: 3rd Party Authentication - ParseKeycloak
public extension ParseUser {

    /// A Keycloak `ParseUser`.
    static var keycloak: ParseKeycloak<Self> {
        ParseKeycloak<Self>()
    }
}
