//
//  ParseAnonymous.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/14/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
 Provides utility functions for working with Anonymously logged-in users.
 
 Anonymous users have some unique characteristics:
 - Anonymous users don't need a user name or password.
 - Once logged out, an anonymous user cannot be recovered.
 - When the current user is anonymous, the following methods can be used to switch
 to a different user or convert the anonymous user into a regular one:
    - *signup* converts an anonymous user to a standard user with the given username and password.
 Data associated with the anonymous user is retained.
    - *login* switches users without converting the anonymous user.
 Data associated with the anonymous user will be lost.
    - Service *login* (e.g. Apple, Facebook, Twitter) will attempt to convert
 the anonymous user into a standard user by linking it to the service.
 If a user already exists that is linked to the service, it will instead switch to the existing user.
    - Service linking (e.g. Apple, Facebook, Twitter) will convert the anonymous user
 into a standard user by linking it to the service.
 */
public struct ParseAnonymous<AuthenticatedUser: ParseUser>: ParseAuthentication {

    enum AuthenticationKeys: String, Codable {
        case id

        func makeDictionary() -> [String: String] {
            [AuthenticationKeys.id.rawValue: UUID().uuidString.lowercased()]
        }
    }
    public static var __type: String { // swiftlint:disable:this identifier_name
        "anonymous"
    }
    public init() { }
}

// MARK: Login
public extension ParseAnonymous {

    /**
     Login a `ParseUser` *synchronously* using the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - returns: the linked `ParseUser`.
     */
    func login(options: API.Options = []) throws -> AuthenticatedUser {
        try self.login(authData: AuthenticationKeys.id.makeDictionary(),
                       options: options)
    }

    /**
     Login a `ParseUser` *synchronously* using the respective authentication type.
     - parameter authData: The authData for the respective authentication type. This will be ignored.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - returns: the linked `ParseUser`.
     */
    func login(authData: [String: String],
               options: API.Options = []) throws -> AuthenticatedUser {
        try AuthenticatedUser.login(__type,
                                    authData: authData,
                                    options: options)
    }

    /**
     Login a `ParseUser` *asynchronously* using the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        self.login(authData: AuthenticationKeys.id.makeDictionary(),
                   options: options,
                   callbackQueue: callbackQueue,
                   completion: completion)
    }

    /**
     Login a `ParseUser` *asynchronously* using the respective authentication type.
     - parameter authData: The authData for the respective authentication type. This will be ignored.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(authData: [String: String],
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        AuthenticatedUser.login(__type,
                                authData: authData,
                                options: options,
                                callbackQueue: callbackQueue,
                                completion: completion)
    }
}

// MARK: Link
public extension ParseAnonymous {
    /// Unavailable for `ParseAnonymous`. Will always return an error.
    func link(authData: [String: String],
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        callbackQueue.async {
            completion(.failure(ParseError(code: .unknownError, message: "Not supported")))
        }
    }
}

// MARK: ParseAnonymous
public extension ParseUser {

    /// An anonymous `ParseUser`.
    static var anonymous: ParseAnonymous<Self> {
        ParseAnonymous<Self>()
    }

    /// An anonymous `ParseUser`.
    var anonymous: ParseAnonymous<Self> {
        Self.anonymous
    }
}
