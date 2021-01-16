//
//  ParseAuthenticatable.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/14/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

public protocol ParseAuthenticatable: Codable {
    associatedtype AuthenticatedUser: ParseUser
    init()

    /// The type of authentication.
    var __type: String { get } // swiftlint:disable:this identifier_name

    /// Returns `true` if the *current* user is linked to the respective authentication type.
    var isLinked: Bool { get }

    /**
     Login a `ParseUser` *synchronously* using the respective authentication type.
     - parameter authData: The authData for the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: `ParseError`.
     - returns the linked `ParseUser`.
     */
    func login(authData: [String: String]?,
               options: API.Options) throws -> AuthenticatedUser

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
     Link the *current* `ParseUser` *synchronously* using the respective authentication type.
     - parameter authData: The authData for the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: `ParseError`.
     - returns the linked `ParseUser`.
     */
    func link(authData: [String: String]?, options: API.Options) throws -> AuthenticatedUser

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
     - parameter user: the `ParseUser` to check authentication type. The user must be logged in on this device.
     - returns: `true` if the `ParseUser` is logged in via the repective
     authentication type. `false` if the user is not.
     */
    func isLinked(with user: AuthenticatedUser) -> Bool

    /**
     Unlink the `ParseUser` *asynchronously* from the respective authentication type.
     - parameter user: the `ParseUser` to unlink. The user must be logged in on this device.
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
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     */
    func unlink(options: API.Options,
                callbackQueue: DispatchQueue,
                completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void)

    /**
     Strips the *current* user of a respective authentication type.
     - returns: the *current* user whose autentication type was stripped. Returns `nil`
     if there's no current user. This modified user has not been saved.
     */
    func strip() -> AuthenticatedUser?

    /**
     Strips the `ParseUser`of a respective authentication type.
     - parameter user: the `ParseUser` to strip. The user must be logged in on this device.
     - returns: the user whose autentication type was stripped. This modified user has not been saved.
     */
    func strip(_ user: AuthenticatedUser) -> AuthenticatedUser
}

// MARK: Convenience Implementations
public extension ParseAuthenticatable {

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
            completion(.failure(error))
            return
        }
        unlink(current, options: options, callbackQueue: callbackQueue, completion: completion)
    }

    func strip() -> AuthenticatedUser? {
        if isLinked {
            guard var user = AuthenticatedUser.current else {
                return nil
            }
            user.authData?[__type] = nil
            return user
        }
        return nil
    }

    func strip(_ user: AuthenticatedUser) -> AuthenticatedUser {
        if isLinked(with: user) {
            var user = user
            user.authData?[__type] = nil
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
                      options: API.Options = [],
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
    func isLinked(with type: String) -> Bool {
        authData?[type] != nil
    }

    func unlink(_ type: String,
                options: API.Options,
                callbackQueue: DispatchQueue,
                completion: @escaping (Result<Self, ParseError>) -> Void) {
        if isLinked(with: type) {
            var mutableUser = self
            mutableUser.authData?.removeValue(forKey: type)
            mutableUser.save(options: options, callbackQueue: callbackQueue, completion: completion)
        } else {
            completion(.success(self))
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
            completion(.failure(error))
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
                                         path: .users,
                                         body: body) { (data) -> Self in
            let user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)
            if let authData = user.authData {
                Self.current?.authData = authData
            } else {
                Self.current?.authData = body.authData
            }
            Self.saveCurrentContainerToKeychain()
            return user
        }
    }
}
