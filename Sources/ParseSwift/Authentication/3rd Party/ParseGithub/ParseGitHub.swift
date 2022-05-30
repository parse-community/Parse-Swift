//
//  ParseGitHub.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/1/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with GitHub User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with GitHub](https://docs.parseplatform.org/parse-server/guide/#github-authdata).
 For information on acquiring GitHub sign-in credentials to use with `ParseGitHub`, refer to [GitHub's Documentation](https://docs.github.com/en/developers/apps/building-oauth-apps/authorizing-oauth-apps).
 */
public struct ParseGitHub<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for GitHub authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case accessToken = "access_token"

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter id: Required id for the user.
        /// - parameter accessToken: Required identity token for GitHub.
        /// - returns: authData dictionary.
        func makeDictionary(id: String,
                            accessToken: String) -> [String: String] {

            let returnDictionary = [
                AuthenticationKeys.id.rawValue: id,
                AuthenticationKeys.accessToken.rawValue: accessToken
            ]
            return returnDictionary
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

    public static var __type: String { // swiftlint:disable:this identifier_name
        "github"
    }

    public init() { }
}

// MARK: Login
public extension ParseGitHub {

    /**
     Login a `ParseUser` *asynchronously* using GitHub authentication for graph API login.
     - parameter id: The `GitHub id` from **GitHub**.
     - parameter accessToken: Required **access_token** from **GitHub**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(id: String,
               accessToken: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let githubAuthData = AuthenticationKeys.id
                .makeDictionary(id: id,
                                accessToken: accessToken)
        login(authData: githubAuthData,
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
                                          message: "Should have authData in consisting of keys \"id\" and \"accessToken\".")))
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
public extension ParseGitHub {

    /**
     Link the *current* `ParseUser` *asynchronously* using GitHub authentication for graph API login.
     - parameter id: The **id** from **GitHub**.
     - parameter accessToken: Required **access_token** from **GitHub**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(id: String,
              accessToken: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let githubAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken)
        link(authData: githubAuthData,
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
                                          message: "Should have authData in consisting of keys \"id\" and \"accessToken\".")))
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

// MARK: 3rd Party Authentication - ParseGitHub
public extension ParseUser {

    /// A github `ParseUser`.
    static var github: ParseGitHub<Self> {
        ParseGitHub<Self>()
    }

    /// An github `ParseUser`.
    var github: ParseGitHub<Self> {
        Self.github
    }
}
