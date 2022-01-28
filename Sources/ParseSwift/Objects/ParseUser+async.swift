//
//  ParseUser+async.swift
//  ParseUser+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParseUser {

    // MARK: Async/Await
    /**
     Signs up the user *asynchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the signed in `ParseUser`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
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
     Signs up the user *asynchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the signed in `ParseUser`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func signup(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.signup(options: options,
                        completion: continuation.resume)
        }
    }

    /**
     Makes an *asynchronous* request to log in a user with specified credentials.
     Returns an instance of the successfully logged in `ParseUser`.

     This also caches the user locally so that calls to *current* will use the latest logged in user.
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
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
     Returns an instance of the successfully logged in `ParseUser`.
     If successful, this saves the session to the keychain, so you can retrieve the currently logged in user
     using *current*.

     - parameter sessionToken: The sessionToken of the user to login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
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
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static func logout(options: API.Options = []) async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            Self.logout(options: options, completion: continuation.resume)
        }
        if case let .failure(error) = result {
            throw error
        }
    }

    /**
     Requests *asynchronously* a password reset email to be sent to the specified email address
     associated with the user account. This email allows the user to securely reset their password on the web.
     - parameter email: The email address associated with the user that forgot their password.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static func passwordReset(email: String,
                              options: API.Options = []) async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            Self.passwordReset(email: email, options: options, completion: continuation.resume)
        }
        if case let .failure(error) = result {
            throw error
        }
    }

    /**
     Verifies *asynchronously* whether the specified password associated with the user account is valid.
        
     - parameter password: The password to be verified.
     - parameter usingPost: Set to **true** to use **POST** for sending. Will use **GET**
     otherwise. Defaults to **true**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: `usePost == true` requires Parse Server > 5.0.0. Othewise you should set
     `userPost = false`.
    */
    static func verifyPassword(password: String,
                               usingPost: Bool = true,
                               options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            Self.verifyPassword(password: password,
                                usingPost: usingPost,
                                options: options, completion: continuation.resume)
        }
    }

    /**
     Requests *asynchronously* a verification email be sent to the specified email address
     associated with the user account.
     - parameter email: The email address associated with the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static func verificationEmail(email: String,
                                  options: API.Options = []) async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            Self.verificationEmail(email: email, options: options, completion: continuation.resume)
        }
        if case let .failure(error) = result {
            throw error
        }
    }

    /**
     Fetches the `ParseUser` *aynchronously* with the current data from the server and sets an error if one occurs.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the fetched `ParseUser`.
     - throws: An error of type `ParseError`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
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
     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isAllowingCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the saved `ParseUser`.
     - throws: An error of type `ParseError`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If you are using `ParseConfiguration.isAllowingCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isAllowingCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func save(ignoringCustomObjectIdConfig: Bool = false,
              options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.save(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                      options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Creates the `ParseUser` *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the saved `ParseUser`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func create(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.create(options: options,
                        completion: continuation.resume)
        }
    }

    /**
     Replaces the `ParseUser` *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the saved `ParseUser`.
     - throws: An error of type `ParseError`.
     - important: If an object replaced has the same objectId as current, it will automatically replace the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func replace(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.replace(options: options,
                         completion: continuation.resume)
        }
    }

    /**
     Updates the `ParseUser` *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the saved `ParseUser`.
     - throws: An error of type `ParseError`.
     - important: If an object updated has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    internal func update(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.update(options: options,
                        completion: continuation.resume)
        }
    }

    /**
     Deletes the `ParseUser` *asynchronously*.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func delete(options: API.Options = []) async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            self.delete(options: options, completion: continuation.resume)
        }
        if case let .failure(error) = result {
            throw error
        }
    }
}

public extension Sequence where Element: ParseUser {
    /**
     Fetches a collection of users *aynchronously* with the current data from the server and sets
     an error if one occurs.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns an array of Result enums with the object if a fetch was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
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
     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isAllowingCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns an array of Result enums with the object if a save was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - warning: If you are using `ParseConfiguration.isAllowingCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isAllowingCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func saveAll(batchLimit limit: Int? = nil,
                 transaction: Bool = ParseSwift.configuration.isUsingTransactions,
                 ignoringCustomObjectIdConfig: Bool = false,
                 options: API.Options = []) async throws -> [(Result<Self.Element, ParseError>)] {
        try await withCheckedThrowingContinuation { continuation in
            self.saveAll(batchLimit: limit,
                         transaction: transaction,
                         ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                         options: options,
                         completion: continuation.resume)
        }
    }

    /**
     Creates a collection of users *asynchronously*.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns an array of Result enums with the object if a save was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func createAll(batchLimit limit: Int? = nil,
                   transaction: Bool = ParseSwift.configuration.isUsingTransactions,
                   options: API.Options = []) async throws -> [(Result<Self.Element, ParseError>)] {
        try await withCheckedThrowingContinuation { continuation in
            self.createAll(batchLimit: limit,
                           transaction: transaction,
                           options: options,
                           completion: continuation.resume)
        }
    }

    /**
     Replaces a collection of users *asynchronously*.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns an array of Result enums with the object if a save was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - important: If an object replaced has the same objectId as current, it will automatically replace the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func replaceAll(batchLimit limit: Int? = nil,
                    transaction: Bool = ParseSwift.configuration.isUsingTransactions,
                    options: API.Options = []) async throws -> [(Result<Self.Element, ParseError>)] {
        try await withCheckedThrowingContinuation { continuation in
            self.replaceAll(batchLimit: limit,
                            transaction: transaction,
                            options: options,
                            completion: continuation.resume)
        }
    }

    /**
     Updates a collection of users *asynchronously*.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns an array of Result enums with the object if a save was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - important: If an object updated has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    internal func updateAll(batchLimit limit: Int? = nil,
                            transaction: Bool = ParseSwift.configuration.isUsingTransactions,
                            options: API.Options = []) async throws -> [(Result<Self.Element, ParseError>)] {
        try await withCheckedThrowingContinuation { continuation in
            self.updateAll(batchLimit: limit,
                           transaction: transaction,
                           options: options,
                           completion: continuation.resume)
        }
    }

    /**
     Deletes a collection of users *asynchronously*.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Each element in the array is `nil` if the delete successful or a `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func deleteAll(batchLimit limit: Int? = nil,
                   transaction: Bool = ParseSwift.configuration.isUsingTransactions,
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
