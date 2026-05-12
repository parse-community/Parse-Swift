//
//  ParseJanrainCapture.swift
//  ParseSwift
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with Janrain Capture User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for Janrain Capture authentication using the `janraincapture` auth adapter.
 Refer to Janrain Capture API documentation for information on acquiring credentials.
 */
public struct ParseJanrainCapture<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Janrain Capture authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case accessToken = "access_token"

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter id: Required Janrain Capture user id.
        /// - parameter accessToken: Required Janrain Capture access token.
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

    public static var __type: String { // swiftlint:disable:this identifier_name
        "janraincapture"
    }

    public init() { }
}

// MARK: Login
public extension ParseJanrainCapture {

    /**
     Login a `ParseUser` *asynchronously* using Janrain Capture authentication.
     - parameter id: The Janrain Capture user id.
     - parameter accessToken: Required Janrain Capture **access_token**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(id: String,
               accessToken: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let janrainCaptureAuthData = AuthenticationKeys.id
            .makeDictionary(id: id, accessToken: accessToken)
        login(authData: janrainCaptureAuthData,
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
                let message = "Should have authData consisting of keys \"id\" and \"access_token\"."
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
public extension ParseJanrainCapture {

    /**
     Link the *current* `ParseUser` *asynchronously* using Janrain Capture authentication.
     - parameter id: The Janrain Capture user id.
     - parameter accessToken: Required Janrain Capture **access_token**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(id: String,
              accessToken: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let janrainCaptureAuthData = AuthenticationKeys.id
            .makeDictionary(id: id, accessToken: accessToken)
        link(authData: janrainCaptureAuthData,
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
                let message = "Should have authData consisting of keys \"id\" and \"access_token\"."
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

// MARK: 3rd Party Authentication - ParseJanrainCapture
public extension ParseUser {

    /// A Janrain Capture `ParseUser`.
    static var janrainCapture: ParseJanrainCapture<Self> {
        ParseJanrainCapture<Self>()
    }

    /// A Janrain Capture `ParseUser`.
    var janrainCapture: ParseJanrainCapture<Self> {
        Self.janrainCapture
    }
}
