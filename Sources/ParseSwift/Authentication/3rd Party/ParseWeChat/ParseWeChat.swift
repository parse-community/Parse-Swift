//
//  ParseWeChat.swift
//  ParseSwift
//
//  Created by Parse Community on 5/13/26.
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with WeChat User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with WeChat](https://docs.parseplatform.org/parse-server/guide/#wechat-authdata).
 For information on acquiring WeChat sign-in credentials to use with `ParseWeChat`, refer to [WeChat's documentation](https://developers.weixin.qq.com/doc/offiaccount/en/OA_Web_Apps/Wechat_webpage_authorization.html).
 */
public struct ParseWeChat<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for WeChat authentication.
    enum AuthenticationKeys: String, Codable {
        case id
        case accessToken = "access_token"
        case code

        /// Properly makes an authData dictionary with the secure WeChat auth code flow keys.
        /// - parameter code: Required authorization code from WeChat.
        /// - returns: authData dictionary.
        func makeDictionary(code: String) -> [String: String] {
            [AuthenticationKeys.code.rawValue: code]
        }

        /// Properly makes an authData dictionary with the deprecated WeChat token flow keys.
        /// - parameter id: Required id for the user.
        /// - parameter accessToken: Required access_token from WeChat.
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
            if authData[AuthenticationKeys.code.rawValue] != nil {
                return true
            }

            if authData[AuthenticationKeys.id.rawValue] != nil &&
                authData[AuthenticationKeys.accessToken.rawValue] != nil {
                return true
            }
            return false
        }
    }

    public static var __type: String { // swiftlint:disable:this identifier_name
        "wechat"
    }

    public init() { }
}

// MARK: Login
public extension ParseWeChat {

    /**
     Login a `ParseUser` *asynchronously* using WeChat authentication.
     - parameter code: The authorization code from **WeChat**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(code: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let weChatAuthData = AuthenticationKeys.code
            .makeDictionary(code: code)
        login(authData: weChatAuthData,
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }

    /**
     Login a `ParseUser` *asynchronously* using deprecated WeChat access token authentication.
     - parameter id: The **id** from **WeChat**.
     - parameter accessToken: The **access_token** from **WeChat**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    @available(*, deprecated, message: "Use login(code:) instead.")
    func login(id: String,
               accessToken: String,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        let weChatAuthData = AuthenticationKeys.id
            .makeDictionary(id: id, accessToken: accessToken)
        login(authData: weChatAuthData,
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }

    func login(authData: [String: String],
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.code.verifyMandatoryKeys(authData: authData) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: "Should have authData consisting of key \"code\", or keys \"id\" and \"access_token\".")))
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
public extension ParseWeChat {

    /**
     Link the *current* `ParseUser` *asynchronously* using WeChat authentication.
     - parameter code: The authorization code from **WeChat**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(code: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let weChatAuthData = AuthenticationKeys.code
            .makeDictionary(code: code)
        link(authData: weChatAuthData,
             options: options,
             callbackQueue: callbackQueue,
             completion: completion)
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using deprecated WeChat access token authentication.
     - parameter id: The **id** from **WeChat**.
     - parameter accessToken: The **access_token** from **WeChat**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    @available(*, deprecated, message: "Use link(code:) instead.")
    func link(id: String,
              accessToken: String,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let weChatAuthData = AuthenticationKeys.id
            .makeDictionary(id: id, accessToken: accessToken)
        link(authData: weChatAuthData,
             options: options,
             callbackQueue: callbackQueue,
             completion: completion)
    }

    func link(authData: [String: String],
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.code.verifyMandatoryKeys(authData: authData) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: "Should have authData consisting of key \"code\", or keys \"id\" and \"access_token\".")))
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

// MARK: 3rd Party Authentication - ParseWeChat
public extension ParseUser {

    /// A WeChat `ParseUser`.
    static var wechat: ParseWeChat<Self> {
        ParseWeChat<Self>()
    }

    /// A WeChat `ParseUser`.
    var wechat: ParseWeChat<Self> {
        Self.wechat
    }
}
