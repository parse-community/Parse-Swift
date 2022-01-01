//
//  ParseLinkedIn.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/1/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with LinkedIn User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with LinkedIn](https://docs.parseplatform.org/parse-server/guide/#linkedin-authdata).
 For information on acquiring LinkedIn sign-in credentials to use with `ParseLinkedIn`, refer to [LinkedIn's Documentation](https://docs.microsoft.com/en-us/linkedin/shared/authentication/authentication?context=linkedin/consumer/context).
 */
public struct ParseLinkedIn<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for LinkedIn authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case accessToken = "access_token"
        case isMobileSDK = "is_mobile_sdk"

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter userId: Required id for the user.
        /// - parameter accessToken: Required identity token for LinkedIn.
        /// - returns: authData dictionary.
        func makeDictionary(userId: String,
                            accessToken: String,
                            isMobileSDK: Bool) -> [String: String] {

            let returnDictionary = [
                AuthenticationKeys.id.rawValue: userId,
                AuthenticationKeys.accessToken.rawValue: accessToken,
                AuthenticationKeys.isMobileSDK.rawValue: "\(isMobileSDK)"
            ]
            return returnDictionary
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: `true` if all the mandatory keys are present, `false` otherwise.
        func verifyMandatoryKeys(authData: [String: String]) -> Bool {
            guard authData[AuthenticationKeys.id.rawValue] != nil,
                  authData[AuthenticationKeys.accessToken.rawValue] != nil,
                  authData[AuthenticationKeys.isMobileSDK.rawValue] != nil else {
                return false
            }
            return false
        }
    }

    public static var __type: String { // swiftlint:disable:this identifier_name
        "linkedin"
    }

    public init() { }
}

// MARK: Login
public extension ParseLinkedIn {

    /**
     Login a `ParseUser` *asynchronously* using LinkedIn authentication for graph API login.
     - parameter userId: The `LinkedIn userId` from **LinkedIn**.
     - parameter accessToken: Required **access_token** from **LinkedIn**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(userId: String,
               accessToken: String,
               isMobileSDK: Bool,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let linkedInAuthData = AuthenticationKeys.id
                .makeDictionary(userId: userId,
                                accessToken: accessToken,
                                isMobileSDK: isMobileSDK)
        login(authData: linkedInAuthData,
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
                                          message: "Should have authData in consisting of keys \"id\", \"accessToken\", and \"isMobileSDK\".")))
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
public extension ParseLinkedIn {

    /**
     Link the *current* `ParseUser` *asynchronously* using LinkedIn authentication for graph API login.
     - parameter userId: The **id** from **LinkedIn**.
     - parameter accessToken: Required **access_token** from **LinkedIn**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(userId: String,
              accessToken: String,
              isMobileSDK: Bool,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let linkedInAuthData = AuthenticationKeys.id
            .makeDictionary(userId: userId,
                            accessToken: accessToken,
                            isMobileSDK: isMobileSDK)
        link(authData: linkedInAuthData,
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
                                          message: "Should have authData in consisting of keys \"id\", \"accessToken\", and \"isMobileSDK\".")))
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

// MARK: 3rd Party Authentication - ParseLinkedIn
public extension ParseUser {

    /// A linkedIn `ParseUser`.
    static var linkedIn: ParseLinkedIn<Self> {
        ParseLinkedIn<Self>()
    }

    /// An linkedIn `ParseUser`.
    var linkedIn: ParseLinkedIn<Self> {
        Self.linkedIn
    }
}
