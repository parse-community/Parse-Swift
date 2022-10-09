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

     This will also enforce that the username is not already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the signed in `ParseUser`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @discardableResult static func signup(username: String,
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

     This will also enforce that the username is not already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the signed in `ParseUser`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @discardableResult func signup(options: API.Options = []) async throws -> Self {
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
    @discardableResult static func login(username: String,
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
    @discardableResult func become(sessionToken: String,
                                   options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.become(sessionToken: sessionToken, options: options, completion: continuation.resume)
        }
    }

#if !os(Linux) && !os(Android) && !os(Windows)
    /**
     Logs in a `ParseUser` *asynchronously* using the session token from the Parse Objective-C SDK Keychain.
     Returns an instance of the successfully logged in `ParseUser`. The Parse Objective-C SDK Keychain is not
     modified in any way when calling this method; allowing developers to revert their applications back to the older
     SDK if desired.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the logged in `ParseUser`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: When initializing the Swift SDK, `migratingFromObjcSDK` should be set to **false**
     when calling this method.
     - warning: The latest **PFUser** from the Objective-C SDK should be saved to your
     Parse Server before calling this method.
    */
    @discardableResult static func loginUsingObjCKeychain(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            Self.loginUsingObjCKeychain(options: options, completion: continuation.resume)
        }
    }
#endif

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
     otherwise. Defaults to **false**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: `usingPost == true` requires the
     [issue](https://github.com/parse-community/parse-server/issues/7784) to be addressed on
     the Parse Server, othewise you should set `usingPost = false`.
    */
    @discardableResult static func verifyPassword(password: String,
                                                  usingPost: Bool = false,
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
     Fetches the `ParseUser` *aynchronously* with the current data from the server.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the fetched `ParseUser`.
     - throws: An error of type `ParseError`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @discardableResult func fetch(includeKeys: [String]? = nil,
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
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the saved `ParseUser`.
     - throws: An error of type `ParseError`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @discardableResult func save(ignoringCustomObjectIdConfig: Bool = false,
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
    @discardableResult func create(options: API.Options = []) async throws -> Self {
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
    @discardableResult func replace(options: API.Options = []) async throws -> Self {
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
    @discardableResult internal func update(options: API.Options = []) async throws -> Self {
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
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns an array of Result enums with the object if a fetch was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @discardableResult func fetchAll(includeKeys: [String]? = nil,
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
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns an array of Result enums with the object if a save was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @discardableResult func saveAll(batchLimit limit: Int? = nil,
                                    transaction: Bool = configuration.isUsingTransactions,
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
    @discardableResult func createAll(batchLimit limit: Int? = nil,
                                      transaction: Bool = configuration.isUsingTransactions,
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
    @discardableResult func replaceAll(batchLimit limit: Int? = nil,
                                       transaction: Bool = configuration.isUsingTransactions,
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
                            transaction: Bool = configuration.isUsingTransactions,
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
    @discardableResult func deleteAll(batchLimit limit: Int? = nil,
                                      transaction: Bool = configuration.isUsingTransactions,
                                      options: API.Options = []) async throws -> [(Result<Void, ParseError>)] {
        try await withCheckedThrowingContinuation { continuation in
            self.deleteAll(batchLimit: limit,
                           transaction: transaction,
                           options: options,
                           completion: continuation.resume)
        }
    }
}

// MARK: Helper Methods (Internal)
internal extension ParseUser {

    func command(method: Method,
                 ignoringCustomObjectIdConfig: Bool = false,
                 options: API.Options,
                 callbackQueue: DispatchQueue) async throws -> Self {
        let (savedChildObjects, savedChildFiles) = try await self.ensureDeepSave(options: options)
        do {
            let command: API.Command<Self, Self>!
            switch method {
            case .save:
                command = try self.saveCommand(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig)
            case .create:
                command = self.createCommand()
            case .replace:
                command = try self.replaceCommand()
            case .update:
                command = try self.updateCommand()
            }
            let saved = try await command
                .executeAsync(options: options,
                              callbackQueue: callbackQueue,
                              childObjects: savedChildObjects,
                              childFiles: savedChildFiles)
            try? Self.updateKeychainIfNeeded([saved])
            return saved
        } catch {
            let defaultError = ParseError(code: .unknownError,
                                          message: error.localizedDescription)
            let parseError = error as? ParseError ?? defaultError
            throw parseError
        }
    }
}

// MARK: Batch Support
internal extension Sequence where Element: ParseUser {
    func batchCommand(method: Method,
                      batchLimit limit: Int?,
                      transaction: Bool,
                      ignoringCustomObjectIdConfig: Bool = false,
                      options: API.Options,
                      callbackQueue: DispatchQueue) async throws -> [(Result<Element, ParseError>)] {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        var childObjects = [String: PointerType]()
        var childFiles = [UUID: ParseFile]()
        var commands = [API.Command<Self.Element, Self.Element>]()
        let objects = map { $0 }
        for object in objects {
            let (savedChildObjects, savedChildFiles) = try await object
                .ensureDeepSave(options: options,
                                isShouldReturnIfChildObjectsFound: transaction)
            try savedChildObjects.forEach {(key, value) in
                guard childObjects[key] == nil else {
                    throw ParseError(code: .unknownError, message: "circular dependency")
                }
                childObjects[key] = value
            }
            try savedChildFiles.forEach {(key, value) in
                guard childFiles[key] == nil else {
                    throw ParseError(code: .unknownError, message: "circular dependency")
                }
                childFiles[key] = value
            }
            do {
                switch method {
                case .save:
                    commands.append(
                        try object.saveCommand(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig)
                    )
                case .create:
                    commands.append(object.createCommand())
                case .replace:
                    commands.append(try object.replaceCommand())
                case .update:
                    commands.append(try object.updateCommand())
                }
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                throw parseError
            }
        }

        do {
            var returnBatch = [(Result<Self.Element, ParseError>)]()
            let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
            try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
            let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
            for batch in batches {
                let saved = try await API.Command<Self.Element, Self.Element>
                        .batch(commands: batch, transaction: transaction)
                        .executeAsync(options: options,
                                      batching: true,
                                      callbackQueue: callbackQueue,
                                      childObjects: childObjects,
                                      childFiles: childFiles)
                returnBatch.append(contentsOf: saved)
            }
            try? Self.Element.updateKeychainIfNeeded(returnBatch.compactMap {try? $0.get()})
            return returnBatch
        } catch {
            let defaultError = ParseError(code: .unknownError,
                                          message: error.localizedDescription)
            let parseError = error as? ParseError ?? defaultError
            throw parseError
        }
    }
}
#endif
