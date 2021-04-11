//
//  ParseUser+publisher.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseUser {

    // MARK: Signing Up - Combine
    /**
     Signs up the user *asynchronously* and publishes value.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    static func signupPublisher(username: String,
                                password: String,
                                options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            Self.signup(username: username,
                        password: password,
                        options: options,
                        completion: promise)
        }
    }

    /**
     Signs up the user *asynchronously* and publishes value.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func signupPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.signup(options: options,
                        completion: promise)
        }
    }

    // MARK: Logging In - Combine
    /**
     Makes an *asynchronous* request to log in a user with specified credentials.
     Publishes an instance of the successfully logged in `ParseUser`.

     This also caches the user locally so that calls to *current* will use the latest logged in user.
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    static func loginPublisher(username: String,
                               password: String,
                               options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            Self.login(username: username,
                       password: password,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Logs in a `ParseUser` *asynchronously* with a session token.
     Publishes an instance of the successfully logged in `ParseUser`.
     If successful, this saves the session to the keychain, so you can retrieve the currently logged in user
     using *current*.

     - parameter sessionToken: The sessionToken of the user to login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func becomePublisher(sessionToken: String, options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.become(sessionToken: sessionToken, options: options, completion: promise)
        }
    }

    // MARK: Logging Out - Combine
    /**
     Logs out the currently logged in user *asynchronously*. Publishes when complete.

     This will also remove the session from the Keychain, log out of linked services
     and all future calls to `current` will return `nil`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    static func logoutPublisher(options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            Self.logout(options: options, completion: promise)
        }
    }

    // MARK: Password Reset - Combine
    /**
     Requests *asynchronously* a password reset email to be sent to the specified email address
     associated with the user account. This email allows the user to securely reset their password on the web.
     Publishes when complete.
        - parameter email: The email address associated with the user that forgot their password.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    static func passwordResetPublisher(email: String,
                                       options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            Self.passwordReset(email: email, options: options, completion: promise)
        }
    }

    // MARK: Verification Email Request - Combine
    /**
     Requests *asynchronously* a verification email be sent to the specified email address
     associated with the user account. Publishes when complete.
        - parameter email: The email address associated with the user.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    static func verificationEmailPublisher(email: String,
                                           options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            Self.verificationEmail(email: email, options: options, completion: promise)
        }
    }

    // MARK: Fetchable - Combine
    /**
     Fetches the `ParseUser` *aynchronously* with the current data from the server and sets an error if one occurs.
     Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
    */
    func fetchPublisher(includeKeys: [String]? = nil,
                        options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.fetch(includeKeys: includeKeys,
                       options: options,
                       completion: promise)
        }
    }

    // MARK: Savable - Combine
    /**
     Saves the `ParseUser` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    func savePublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.save(options: options,
                      completion: promise)
        }
    }

    // MARK: Deletable - Combine
    /**
     Deletes the `ParseUser` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
    func deletePublisher(options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            self.delete(options: options, completion: promise)
        }
    }
}

// MARK: Batch Support - Combine
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
public extension Sequence where Element: ParseUser {
    /**
     Fetches a collection of users *aynchronously* with the current data from the server and sets
     an error if one occurs. Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
    */
    func fetchAllPublisher(includeKeys: [String]? = nil,
                           options: API.Options = []) -> Future<[(Result<Self.Element, ParseError>)], ParseError> {
        Future { promise in
            self.fetchAll(includeKeys: includeKeys,
                          options: options,
                          completion: promise)
        }
    }

    /**
     Saves a collection of users *asynchronously* and publishes when complete.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
    */
    func saveAllPublisher(batchLimit limit: Int? = nil,
                          transaction: Bool = false,
                          options: API.Options = []) -> Future<[(Result<Self.Element, ParseError>)], ParseError> {
        Future { promise in
            self.saveAll(batchLimit: limit,
                         transaction: transaction,
                         options: options,
                         completion: promise)
        }
    }

    /**
     Deletes a collection of users *asynchronously* and publishes when complete.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
    */
    func deleteAllPublisher(batchLimit limit: Int? = nil,
                            transaction: Bool = false,
                            options: API.Options = []) -> Future<[(Result<Void, ParseError>)], ParseError> {
        Future { promise in
            self.deleteAll(batchLimit: limit,
                           transaction: transaction,
                           options: options,
                           completion: promise)
        }
    }
}
#endif
