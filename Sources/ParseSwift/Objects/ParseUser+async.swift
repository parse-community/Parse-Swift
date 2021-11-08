//
//  ParseUser+async.swift
//  ParseUser+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency)
import Foundation

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension ParseUser {

    // MARK: Async/Await
    /**
     Signs up the user *asynchronously* and publishes value.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
    */
    @MainActor
    static func signup(username: String,
                       password: String,
                       options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            Self.signup(username: username,
                        password: password,
                        options: options,
                        completion: continuation.resume)
        }
    }

    /**
     Signs up the user *asynchronously* and publishes value.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
    */
    @MainActor
    func signup(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.signup(options: options,
                        completion: continuation.resume)
        }
    }

    /**
     Makes an *asynchronous* request to log in a user with specified credentials.
     Publishes an instance of the successfully logged in `ParseUser`.

     This also caches the user locally so that calls to *current* will use the latest logged in user.
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
    */
    @MainActor
    static func login(username: String,
                      password: String,
                      options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            Self.login(username: username,
                       password: password,
                       options: options,
                       completion: continuation.resume)
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
     - throws: `ParseError`.
    */
    @MainActor
    func become(sessionToken: String,
                options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.become(sessionToken: sessionToken, options: options, completion: continuation.resume)
        }
    }

    /**
     Logs out the currently logged in user *asynchronously*.

     This will also remove the session from the Keychain, log out of linked services
     and all future calls to `current` will return `nil`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
    */
    @MainActor
    static func logout(options: API.Options = []) async throws {
        _ = try await withCheckedThrowingContinuation { continuation in
            Self.logout(options: options, completion: continuation.resume)
        }
    }

    /**
     Requests *asynchronously* a password reset email to be sent to the specified email address
     associated with the user account. This email allows the user to securely reset their password on the web.
        - parameter email: The email address associated with the user that forgot their password.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - returns: A publisher that eventually produces a single value and then finishes or fails.
        - throws: `ParseError`.
    */
    @MainActor
    static func passwordReset(email: String,
                              options: API.Options = []) async throws {
        _ = try await withCheckedThrowingContinuation { continuation in
            Self.passwordReset(email: email, options: options, completion: continuation.resume)
        }
    }

    /**
     Requests *asynchronously* a verification email be sent to the specified email address
     associated with the user account.
        - parameter email: The email address associated with the user.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - returns: A publisher that eventually produces a single value and then finishes or fails.
        - throws: `ParseError`.
    */
    @MainActor
    static func verificationEmail(email: String,
                                  options: API.Options = []) async throws {
        _ = try await withCheckedThrowingContinuation { continuation in
            Self.verificationEmail(email: email, options: options, completion: continuation.resume)
        }
    }

    /**
     Fetches the `ParseUser` *aynchronously* with the current data from the server and sets an error if one occurs.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @MainActor
    func fetch(includeKeys: [String]? = nil,
               options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.fetch(includeKeys: includeKeys,
                       options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Saves the `ParseUser` *asynchronously*.
     - parameter isIgnoreCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.allowCustomObjectId = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    @MainActor
    func save(isIgnoreCustomObjectIdConfig: Bool = false,
              options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.save(isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig,
                      options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Deletes the `ParseUser` *asynchronously*.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
    @MainActor
    func delete(options: API.Options = []) async throws {
        _ = try await withCheckedThrowingContinuation { continuation in
            self.delete(options: options, completion: continuation.resume)
        }
    }
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension Sequence where Element: ParseUser {
    /**
     Fetches a collection of users *aynchronously* with the current data from the server and sets
     an error if one occurs.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
    */
    @MainActor
    func fetchAll(includeKeys: [String]? = nil,
                  options: API.Options = []) async throws -> [(Result<Self.Element, ParseError>)] {
        try await withCheckedThrowingContinuation { continuation in
            self.fetchAll(includeKeys: includeKeys,
                          options: options,
                          completion: continuation.resume)
        }
    }

    /**
     Saves a collection of users *asynchronously*.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter isIgnoreCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.allowCustomObjectId = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
    */
    @MainActor
    func saveAll(batchLimit limit: Int? = nil,
                 transaction: Bool = false,
                 isIgnoreCustomObjectIdConfig: Bool = false,
                 options: API.Options = []) async throws -> [(Result<Self.Element, ParseError>)] {
        try await withCheckedThrowingContinuation { continuation in
            self.saveAll(batchLimit: limit,
                         transaction: transaction,
                         isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig,
                         options: options,
                         completion: continuation.resume)
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
     - throws: `ParseError`.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
    */
    @MainActor
    func deleteAll(batchLimit limit: Int? = nil,
                   transaction: Bool = false,
                   options: API.Options = []) async throws -> [(Result<Void, ParseError>)] {
        try await withCheckedThrowingContinuation { continuation in
            self.deleteAll(batchLimit: limit,
                           transaction: transaction,
                           options: options,
                           completion: continuation.resume)
        }
    }
}

#endif
