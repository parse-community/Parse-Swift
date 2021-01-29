//
//  ParseUser+publisher.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if !os(Linux)
import Foundation
import Combine

// MARK: Combine
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseUser {

    /**
     Signs up the user *asynchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Future<Self, ParseError>.
    */
    static func signup(username: String,
                       password: String,
                       options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            Self.signup(username: username,
                        password: password,
                        options: options,
                        completion: promise)
        }
    }

    static func login(username: String,
                      password: String,
                      options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            Self.login(username: username,
                       password: password,
                       options: options,
                       completion: promise)
        }
    }

    func become(sessionToken: String, options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            become(sessionToken: sessionToken, options: options, completion: promise)
        }
    }
}

#endif
