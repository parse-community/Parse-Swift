//
//  ParseApple.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/14/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

public struct ParseApple<AuthenticatedUser: ParseUser>: ParseAuthenticatable {

    public var __type: String = "apple" // swiftlint:disable:this identifier_name
    public init() { }

    public static func login(authData: [String: String]?,
                             options: API.Options = []) throws -> AuthenticatedUser {
        guard let authData = authData,
              authData["id"] != nil,
              authData["token"] != nil else {
            throw ParseError(code: .unknownError,
                             message: "Should have authData in consisting of keys \"id\" and \"token\".")
        }
        let appleUser = Self.init()
        return try AuthenticatedUser
            .login(appleUser.__type,
                   authData: authData,
                   options: options)
    }

    public static func login(authData: [String: String]?,
                             options: API.Options = [],
                             callbackQueue: DispatchQueue = .main,
                             completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard let authData = authData,
              authData["id"] != nil,
              authData["token"] != nil else {
            let error = ParseError(code: .unknownError,
                                   message: "Should have authData in consisting of keys \"id\" and \"token\".")
            completion(.failure(error))
            return
        }
        let appleUser = Self.init()
        AuthenticatedUser.login(appleUser.__type,
                                authData: authData,
                                options: options,
                                completion: completion)
    }

    public static func link(authData: [String: String]?,
                            options: API.Options = []) throws -> AuthenticatedUser {
        guard let authData = authData,
              authData["id"] != nil,
              authData["token"] != nil else {
            throw ParseError(code: .unknownError,
                             message: "Should have authData in consisting of keys \"id\" and \"token\".")
        }
        let appleUser = Self.init()
        return try AuthenticatedUser
            .link(appleUser.__type,
                  authData: authData,
                  options: options)
    }

    public static func link(authData: [String: String]?,
                            options: API.Options = [],
                            callbackQueue: DispatchQueue = .main,
                            completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        guard let authData = authData,
              authData["id"] != nil,
              authData["token"] != nil else {
            let error = ParseError(code: .unknownError,
                                   message: "Should have authData in consisting of keys \"id\" and \"token\".")
            completion(.failure(error))
            return
        }
        let appleUser = Self.init()
        AuthenticatedUser.link(appleUser.__type,
                               authData: authData,
                               options: options,
                               completion: completion)
    }

    public func restore(_ user: AuthenticatedUser) -> AuthenticatedUser {

        if !user.isLinked(with: __type) {
            var user = user
            let authData = [
                "id": UUID().uuidString.lowercased()
            ]
            if user.authData != nil {
                user.authData![__type] = authData
            } else {
                user.authData = [__type: authData]
            }
            return user
        }
        return user
    }
}

public extension ParseUser {

    // MARK: ParseApple

    /// An anonymous `ParseUser`.
    var apple: ParseAnonymous<Self> {
        ParseAnonymous<Self>()
    }

    /**
     Whether the `ParseUser` is logged in with the respective authentication type.
     - returns: `true` if the `ParseUser` is logged in via the repective
     authentication type. `false` if the user is not.
     */
    func isLinkedApple() -> Bool {
        apple.isLinked(with: self)
    }

    /**
     Unlink the `ParseUser` *asynchronously* from the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     */
    func unlinkApple(options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     completion: @escaping (Result<Self, ParseError>) -> Void) {
        apple.unlink(self, options: options, callbackQueue: callbackQueue, completion: completion)
    }

    /**
     Restores the respective authentication type to a given `ParseUser`.
     - returns: the user whose autentication type was restored. This modified user has not been saved.
     */
    func restoreApple() -> Self {
        apple.restore(self)
    }

    /**
     Strips the `ParseUser`of a respective authentication type.
     - returns: the user whose autentication type was restored. This modified user has not been saved.
     */
    func stripApple() -> Self {
        apple.strip(self)
    }
}
