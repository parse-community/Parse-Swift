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
public struct ParseAnonymous<AuthenticatedUser: ParseUser>: ParseAuthenticatable {

    enum AuthenticationKeys: String, Codable {
        case id // swiftlint:disable:this identifier_name

        func makeDictionary() -> [String: String] {
            [AuthenticationKeys.id.rawValue: UUID().uuidString.lowercased()]
        }
    }

    public var __type: String = "anonymous" // swiftlint:disable:this identifier_name
    public init() { }
}

// MARK: Login
public extension ParseAnonymous {
    /**
     Login a `ParseUser` *synchronously* using the respective authentication type.
     - parameter authData: The authData for the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: `ParseError`.
     - returns the linked `ParseUser`.
     */
    func login(authData: [String: String]? = nil,
               options: API.Options = []) throws -> AuthenticatedUser {
        let anonymousUser = Self.init()
        return try AuthenticatedUser
            .login(anonymousUser.__type,
                   authData: AuthenticationKeys.id.makeDictionary(),
                   options: options)
    }

    func login(authData: [String: String]? = nil,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        let anonymousUser = Self.init()
        AuthenticatedUser.login(anonymousUser.__type,
                                authData: AuthenticationKeys.id.makeDictionary(),
                                options: options,
                                completion: completion)
    }
}

// MARK: Link
public extension ParseAnonymous {

    func link(authData: [String: String]? = nil,
              options: API.Options = [],
              callbackQueue: DispatchQueue = .main,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        completion(.failure(ParseError(code: .unknownError, message: "Not supported")))
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
