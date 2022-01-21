//
//  ParseAuthentication+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/30/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseAuthentication {

    // MARK: Convenience Implementations - Combine

    func unlinkPublisher(_ user: AuthenticatedUser,
                         options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        user.unlinkPublisher(__type, options: options)
    }

    func unlinkPublisher(options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        guard let current = AuthenticatedUser.current else {
            let error = ParseError(code: .invalidLinkedSession, message: "No current ParseUser.")
            return Future { promise in
                promise(.failure(error))
            }
        }
        return unlinkPublisher(current, options: options)
    }
}

public extension ParseUser {

    // MARK: 3rd Party Authentication - Login Combine

    /**
     Makes an *asynchronous* request to log in a user with specified credentials.
     Publishes an instance of the successfully logged in `ParseUser`.

     This also caches the user locally so that calls to *current* will use the latest logged in user.
     - parameter type: The authentication type.
     - parameter authData: The data that represents the authentication.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    static func loginPublisher(_ type: String,
                               authData: [String: String],
                               options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            Self.login(type,
                       authData: authData,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Unlink the authentication type *asynchronously*. Publishes when complete.
     - parameter type: The type to unlink. The user must be logged in on this device.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func unlinkPublisher(_ type: String,
                         options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.unlink(type,
                        options: options,
                        completion: promise)
        }
    }

    /**
     Makes an *asynchronous* request to link a user with specified credentials. The user should already be logged in.
     Publishes an instance of the successfully linked `ParseUser`.

     This also caches the user locally so that calls to *current* will use the latest logged in user.
     - parameter type: The authentication type.
     - parameter authData: The data that represents the authentication.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    static func linkPublisher(_ type: String,
                              authData: [String: String],
                              options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            Self.link(type,
                      authData: authData,
                      options: options,
                      completion: promise)
        }
    }
}

#endif
