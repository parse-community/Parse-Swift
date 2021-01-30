//
//  ParseAuthentication.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/14/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

/**
 Objects that conform to the `ParseAuthentication` protocol provide
 convenience implementations for using 3rd party authentication methods.
 The authentication methods supported by the Parse Server can be found
 [here](https://docs.parseplatform.org/parse-server/guide/#oauth-and-3rd-party-authentication).
 */
public protocol ParseAuthentication: Codable {
    associatedtype AuthenticatedUser: ParseUser
    init()

    /// The type of authentication.
    static var __type: String { get } // swiftlint:disable:this identifier_name

    /// Returns `true` if the *current* user is linked to the respective authentication type.
    var isLinked: Bool { get }

    /**
     Login a `ParseUser` *asynchronously* using the respective authentication type.
     - parameter authData: The authData for the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(authData: [String: String]?,
               options: API.Options,
               callbackQueue: DispatchQueue,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void)

    /**
     Link the *current* `ParseUser` *asynchronously* using the respective authentication type.
     - parameter authData: The authData for the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(authData: [String: String]?,
              options: API.Options,
              callbackQueue: DispatchQueue,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void)

    /**
     Whether the `ParseUser` is logged in with the respective authentication type.
     - parameter user: The `ParseUser` to check authentication type. The user must be logged in on this device.
     - returns: `true` if the `ParseUser` is logged in via the repective
     authentication type. `false` if the user is not.
     */
    func isLinked(with user: AuthenticatedUser) -> Bool

    /**
     Unlink the `ParseUser` *asynchronously* from the respective authentication type.
     - parameter user: The `ParseUser` to unlink. The user must be logged in on this device.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     */
    func unlink(_ user: AuthenticatedUser,
                options: API.Options,
                callbackQueue: DispatchQueue,
                completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void)

    /**
     Unlink the *current* `ParseUser` *asynchronously* from the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<AuthenticatedUser, ParseError>)`.
     */
    func unlink(options: API.Options,
                callbackQueue: DispatchQueue,
                completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void)

    /**
     Strips the *current* user of a respective authentication type.
     - returns: The *current* user whose autentication type was stripped. Returns `nil`
     if there's no current user. This modified user has not been saved.
     */
    func strip()

    /**
     Strips the `ParseUser`of a respective authentication type.
     - parameter user: The `ParseUser` to strip. The user must be logged in on this device.
     - returns: The user whose autentication type was stripped. This modified user has not been saved.
     */
    func strip(_ user: AuthenticatedUser) -> AuthenticatedUser

    #if canImport(Combine)
    /**
     Login a `ParseUser` *asynchronously* using the respective authentication type.
     - parameter authData: The authData for the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func loginPublisher(authData: [String: String]?,
                        options: API.Options) -> Future<AuthenticatedUser, ParseError>

    /**
     Link the *current* `ParseUser` *asynchronously* using the respective authentication type.
     - parameter authData: The authData for the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func linkPublisher(authData: [String: String]?,
                       options: API.Options) -> Future<AuthenticatedUser, ParseError>

    /**
     Unlink the `ParseUser` *asynchronously* from the respective authentication type.
     - parameter user: The `ParseUser` to unlink. The user must be logged in on this device.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func unlinkPublisher(_ user: AuthenticatedUser,
                         options: API.Options) -> Future<AuthenticatedUser, ParseError>

    /**
     Unlink the *current* `ParseUser` *asynchronously* from the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    func unlinkPublisher(options: API.Options) -> Future<AuthenticatedUser, ParseError>

    #endif
}

// MARK: Convenience Implementations
public extension ParseAuthentication {

    var __type: String { // swiftlint:disable:this identifier_name
        Self.__type
    }

    var isLinked: Bool {
        guard let current = AuthenticatedUser.current else {
            return false
        }
        return current.isLinked(with: __type)
    }

    func isLinked(with user: AuthenticatedUser) -> Bool {
        user.isLinked(with: __type)
    }

    func unlink(_ user: AuthenticatedUser,
                options: API.Options = [],
                callbackQueue: DispatchQueue = .main,
                completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        user.unlink(__type, options: options, callbackQueue: callbackQueue, completion: completion)
    }

    func unlink(options: API.Options = [],
                callbackQueue: DispatchQueue = .main,
                completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard let current = AuthenticatedUser.current else {
            let error = ParseError(code: .invalidLinkedSession, message: "No current ParseUser.")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        unlink(current, options: options, callbackQueue: callbackQueue, completion: completion)
    }

    func strip() {
        guard let user = AuthenticatedUser.current else {
            return
        }
        AuthenticatedUser.current = strip(user)
    }

    func strip(_ user: AuthenticatedUser) -> AuthenticatedUser {
        if isLinked(with: user) {
            var user = user
            user.authData?.updateValue(nil, forKey: __type)
            return user
        }
        return user
    }
}

public extension ParseUser {

    // MARK: 3rd Party Authentication - Login
    /**
     Makes a *synchronous* request to login a user with specified credentials.

     Returns an instance of the successfully logged in `ParseUser`.
     This also caches the user locally so that calls to *current* will use the latest logged in user.

     - parameter type: The authentication type.
     - parameter authData: The data that represents the authentication.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - returns: An instance of the logged in `ParseUser`.
     If login failed due to either an incorrect password or incorrect username, it throws a `ParseError`.
    */
    static func login(_ type: String,
                      authData: [String: String],
                      options: API.Options) throws -> Self {
        let body = SignupLoginBody(authData: [type: authData])
        return try signupCommand(body: body).execute(options: options)
    }

    /**
     Makes an *asynchronous* request to log in a user with specified credentials.
     Returns an instance of the successfully logged in `ParseUser`.

     This also caches the user locally so that calls to *current* will use the latest logged in user.
     - parameter type: The authentication type.
     - parameter authData: The data that represents the authentication.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    static func login(_ type: String,
                      authData: [String: String],
                      options: API.Options,
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<Self, ParseError>) -> Void) {

        let body = SignupLoginBody(authData: [type: authData])
        signupCommand(body: body)
            .executeAsync(options: options) { result in
                callbackQueue.async {
                    completion(result)
                }
            }
    }

    // MARK: 3rd Party Authentication - Link
    /**
     Whether the `ParseUser` is logged in with the respective authentication string type.
     - parameter type: The authentication type to check. The user must be logged in on this device.
     - returns: `true` if the `ParseUser` is logged in via the repective
     authentication type. `false` if the user is not.
     */
    func isLinked(with type: String) -> Bool {
        guard let authData = self.authData?[type] else {
            return false
        }
        return authData != nil
    }

    /**
     Unlink the authentication type *asynchronously*.
     - parameter type: The type to unlink. The user must be logged in on this device.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     */
    func unlink(_ type: String,
                options: API.Options = [],
                callbackQueue: DispatchQueue = .main,
                completion: @escaping (Result<Self, ParseError>) -> Void) {

        guard let current = Self.current,
              current.authData != nil else {
            let error = ParseError(code: .unknownError, message: "Must be logged in to unlink user")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }

        if current.isLinked(with: type) {
            guard let authData = current.apple.strip(current).authData else {
                let error = ParseError(code: .unknownError, message: "Missing authData.")
                callbackQueue.async {
                    completion(.failure(error))
                }
                return
            }
            let body = SignupLoginBody(authData: authData)
            current.linkCommand(body: body)
                .executeAsync(options: options) { result in
                    callbackQueue.async {
                        completion(result)
                    }
                }
        } else {
            callbackQueue.async {
                completion(.success(self))
            }
        }
    }

    /**
     Makes a *synchronous* request to link a user with specified credentials. The user should already be logged in.

     Returns an instance of the successfully linked `ParseUser`.
     This also caches the user locally so that calls to *current* will use the latest logged in user.

     - parameter type: The authentication type.
     - parameter authData: The data that represents the authentication.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - returns: An instance of the logged in `ParseUser`.
     If login failed due to either an incorrect password or incorrect username, it throws a `ParseError`.
    */
    static func link(_ type: String,
                     authData: [String: String],
                     options: API.Options) throws -> Self {
        guard let current = Self.current else {
            throw ParseError(code: .unknownError, message: "Must be logged in to link user")
        }
        let body = SignupLoginBody(authData: [type: authData])
        return try current.linkCommand(body: body).execute(options: options)
    }

    /**
     Makes an *asynchronous* request to link a user with specified credentials. The user should already be logged in.
     Returns an instance of the successfully linked `ParseUser`.

     This also caches the user locally so that calls to *current* will use the latest logged in user.
     - parameter type: The authentication type.
     - parameter authData: The data that represents the authentication.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    static func link(_ type: String,
                     authData: [String: String],
                     options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     completion: @escaping (Result<Self, ParseError>) -> Void) {
        guard let current = Self.current else {
            let error = ParseError(code: .unknownError, message: "Must be logged in to link user")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        let body = SignupLoginBody(authData: [type: authData])
        current.linkCommand(body: body)
            .executeAsync(options: options) { result in
                callbackQueue.async {
                    completion(result)
                }
            }
    }

    internal func linkCommand(body: SignupLoginBody) -> API.NonParseBodyCommand<SignupLoginBody, Self> {

        return API.NonParseBodyCommand<SignupLoginBody, Self>(method: .PUT,
                                         path: endpoint,
                                         body: body) { (data) -> Self in
            let user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)
            if let authData = body.authData {
                Self.current?.anonymous.strip()
                if Self.current?.authData == nil {
                    Self.current?.authData = authData
                } else {
                    authData.forEach { (key, value) in
                        Self.current?.authData?[key] = value
                    }
                }
                if let updatedAt = user.updatedAt {
                    Self.current?.updatedAt = updatedAt
                }
            }
            Self.saveCurrentContainerToKeychain()
            guard let current = Self.current else {
                throw ParseError(code: .unknownError, message: "Should have a current user.")
            }
            return current
        }
    }
}
