//
//  ParsePhantAuth.swift
//  ParseSwift
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with PhantAuth User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with PhantAuth](https://docs.parseplatform.org/parse-server/guide/#phantauth-authdata).
 */
public struct ParsePhantAuth<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for PhantAuth authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case accessToken = "access_token"

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter id: Required id for the user.
        /// - parameter accessToken: Required access token for PhantAuth.
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
        "phantauth"
    }

    public init() { }
}

// MARK: Login
public extension ParsePhantAuth {

    /**
     Login a `ParseUser` *asynchronously* using PhantAuth authentication.
     - parameter id: The **id** from **PhantAuth**.
     - parameter accessToken: Required **access_token** from **PhantAuth**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(id: String,
               accessToken: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let phantAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken)
        login(authData: phantAuthData,
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
public extension ParsePhantAuth {

    /**
     Link the *current* `ParseUser` *asynchronously* using PhantAuth authentication.
     - parameter id: The **id** from **PhantAuth**.
     - parameter accessToken: Required **access_token** from **PhantAuth**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(id: String,
              accessToken: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let phantAuthData = AuthenticationKeys.id
            .makeDictionary(id: id,
                            accessToken: accessToken)
        link(authData: phantAuthData,
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

// MARK: 3rd Party Authentication - ParsePhantAuth
public extension ParseUser {

    /// A PhantAuth `ParseUser`.
    static var phantAuth: ParsePhantAuth<Self> {
        ParsePhantAuth<Self>()
    }

    /// A PhantAuth `ParseUser`.
    var phantAuth: ParsePhantAuth<Self> {
        Self.phantAuth
    }
}
