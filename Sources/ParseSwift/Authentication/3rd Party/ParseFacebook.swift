//
//  ParseFacebook.swift
//  ParseSwift
//
//  Created by Abdulaziz Alhomaidhi on 3/18/21.
//  Copyright © 2021 Parse Community. All rights reserved.

import Foundation
#if canImport(Combine)
import Combine
#endif

// swiftlint:disable line_length

/**
 Provides utility functions for working with Facebook User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with Facebook](https://docs.parseplatform.org/parse-server/guide/#configuring-parse-server-for-sign-in-with-facebook).
 For information on acquiring Facebook sign-in credentials to use with `ParseFacebook`, refer to [Facebook's Documentation](https://developers.facebook.com/docs/facebook-login/limited-login.
 */
public struct ParseFacebook<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Authentication keys required for Facebook authentication.
    enum AuthenticationKeys: String, Codable {
        case id // swiftlint:disable:this identifier_name
        case authenticationToken
        case accessToken
        case expirationDate

        enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
          case id // swiftlint:disable:this identifier_name
          case token
          case accessToken = "access_token"
          case expirationDate = "expiration_date"
        }

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter userId: Required id for the user.
        /// - parameter authenticationToken: Required identity token for the user for Facebook limited login.
        /// - parameter accessToken: Required identity token for the user for Facebook graph API
        /// - parameter expirationDate: required expiration data for user authentication for Facebook login
        /// - returns: Required authData dictionary.
        func makeDictionary(userId: String?, accessToken: String?, authenticationToken: String?, expirationDate: Date?) throws -> [String: String] {

            let validAuthenticationToken = authenticationToken != nil || accessToken != nil
            guard let  userId = userId, let expirationDate = expirationDate else {
                throw ParseError(code: .unknownError, message: "userId or expirationDate can't be empty")
            }
            let dateString = DateFormatter.facebookDateFormatter.string(from: expirationDate)

            var returnDictionary = [AuthenticationKeys.id.rawValue: userId,
                                    AuthenticationKeys.expirationDate.rawValue: dateString]
            guard validAuthenticationToken else {
                throw ParseError(code: .unknownError, message: "provide either accessToken or authenticationToken can't be empty")
            }

            if let accessToken = accessToken {
              returnDictionary[AuthenticationKeys.accessToken.rawValue] = accessToken
            } else if let authenticationToken = authenticationToken {
              returnDictionary[AuthenticationKeys.authenticationToken.rawValue] = authenticationToken
            }
            return returnDictionary
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: `true` if all the mandatory keys are present, `false` otherwise.
        func verifyMandatoryKeys(authData: [String: String]) -> Bool {
            guard authData[AuthenticationKeys.id.rawValue] != nil,
                  authData[AuthenticationKeys.expirationDate.rawValue] != nil else {
                return false
            }

            if let _ = authData[AuthenticationKeys.accessToken.rawValue] {
                return true
            } else if let _ = authData[AuthenticationKeys.authenticationToken.rawValue] {
                return true
            }
            return false
        }
    }
    public static var __type: String { // swiftlint:disable:this identifier_name
        "facebook"
    }
    public init() { }
}

// MARK: Login
public extension ParseFacebook {
    /**
     Login a `ParseUser` *asynchronously* using Facebook authentication for limited login.
     - parameter userId: The `Facebook userId` from `FacebookSDK`.
     - parameter authenticationToken: The `authenticationToken` from `FacebookSDK`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(userId: String,
               authenticationToken: String?,
               expirationDate: Date,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        guard let facebookAuthData = try? AuthenticationKeys.id.makeDictionary(userId: userId, accessToken: nil,
                                                                          authenticationToken: authenticationToken, expirationDate: expirationDate) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: "Couldn't create authData.")))
            }
            return
        }
        login(authData: facebookAuthData,
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }
    /**
     Login a `ParseUser` *asynchronously* using Facebook authentication for graph API login.
     - parameter userId: The `Facebook userId` from `FacebookSDK`.
     - parameter accessToken: The `accessToken` from `FacebookSDK`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(userId: String,
               accessToken: String?,
               expirationDate: Date,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {

        guard let facebookAuthData = try? AuthenticationKeys.id.makeDictionary(userId: userId, accessToken: accessToken,
                                                                          authenticationToken: nil, expirationDate: expirationDate) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: "Couldn't create authData.")))
            }
            return
        }
        login(authData: facebookAuthData,
              options: options,
              callbackQueue: callbackQueue,
              completion: completion)
    }
    func login(authData: [String: String],
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData) else {
            let error = ParseError(code: .unknownError,
                                   message: "Should have authData in consisting of keys \"id\", \"expirationDate\" and \"authentication keys\".")
            callbackQueue.async {
                completion(.failure(error))
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
     Login a `ParseUser` *asynchronously* using Facebook authentication for limited login. Publishes when complete.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter authenticationToken: The `authenticationToken` from `FacebookSDK`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func loginPublisher(userId: String,
                        authenticationToken: String,
                        expirationDate: Date,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(userId: userId,
                       authenticationToken: authenticationToken,
                       expirationDate: expirationDate,
                       options: options,
                       completion: promise)
        }
    }
    /**
     Login a `ParseUser` *asynchronously* using Facebook authentication for graph API login. Publishes when complete.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter accessToken: The `accessToken` from `FacebookSDK`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func loginPublisher(userId: String,
                        accessToken: String,
                        expirationDate: Date,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(userId: userId,
                       accessToken: accessToken,
                       expirationDate: expirationDate,
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
public extension ParseFacebook {

    /**
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for limited login.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter authenticationToken: The `authenticationToken` from `FacebookSDK`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(userId: String,
              authenticationToken: String,
              expirationDate: Date,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard let facebookAuthData = try? AuthenticationKeys.id.makeDictionary(userId: userId, accessToken: nil, authenticationToken: authenticationToken, expirationDate: expirationDate) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: "Couldn't create authData.")))
            }
            return
        }
        link(authData: facebookAuthData,
             options: options,
             callbackQueue: callbackQueue,
             completion: completion)
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for graph API login.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter accessToken: The `accessToken` from `FacebookSDK`.
     - parameter expirationDate: the `expirationDate` from `FacebookSDK`
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(userId: String,
              accessToken: String,
              expirationDate: Date,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard let facebookAuthData = try? AuthenticationKeys.id.makeDictionary(userId: userId, accessToken: accessToken, authenticationToken: nil, expirationDate: expirationDate) else {
            callbackQueue.async {
                completion(.failure(.init(code: .unknownError,
                                          message: "Couldn't create authData.")))
            }
            return
        }
        link(authData: facebookAuthData,
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
                                   message: "Should have authData in consisting of keys \"id\" and \"token\".")
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
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for limited login. Publishes when complete.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter authenticationToken: The `authenticationToken` from `FacebookSDK`.
     - parameter expirationDate: the `expirationDate` from `FacebookSDK`
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func linkPublisher(userId: String,
                       authenticationToken: String,
                       expirationDate: Date,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(userId: userId,
                      authenticationToken: authenticationToken,
                      expirationDate: expirationDate,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for graph API login. Publishes when complete.
     - parameter userId: The `userId` from `FacebookSDK`.
     - parameter accessToken: The `accessToken` from `FacebookSDK`.
     - parameter expirationDate: the `expirationDate` from `FacebookSDK`
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func linkPublisher(userId: String,
                       accessToken: String,
                       expirationDate: Date,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(userId: userId,
                      accessToken: accessToken,
                      expirationDate: expirationDate,
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

// MARK: 3rd Party Authentication - ParseFacebook
public extension ParseUser {

    /// A facebook `ParseUser`.
    static var facebook: ParseFacebook<Self> {
        ParseFacebook<Self>()
    }

    /// An facebook `ParseUser`.
    var facebook: ParseFacebook<Self> {
        Self.facebook
    }
}

// MARK: Convenience
internal extension DateFormatter {
    static let facebookDateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return dateFormatter
    }()
}
