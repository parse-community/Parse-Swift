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

public extension ParseUser {

    // MARK: Combine
    /**
     Signs up the user *asynchronously* and publishes value.

     This will also enforce that the username is not already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
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

     This will also enforce that the username is not already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func signupPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.signup(options: options,
                        completion: promise)
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
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
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
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func becomePublisher(sessionToken: String, options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.become(sessionToken: sessionToken, options: options, completion: promise)
        }
    }

#if !os(Linux) && !os(Android) && !os(Windows)
    /**
     Logs in a `ParseUser` *asynchronously* using the session token from the Parse Objective-C SDK Keychain.
     Publishes an instance of the successfully logged in `ParseUser`. The Parse Objective-C SDK Keychain is not
     modified in any way when calling this method; allowing developers to revert their applications back to the older
     SDK if desired.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: When initializing the Swift SDK, `migratingFromObjcSDK` should be set to **false**
     when calling this method.
     - warning: The latest **PFUser** from the Objective-C SDK should be saved to your
     Parse Server before calling this method.
    */
    static func loginUsingObjCKeychainPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            Self.loginUsingObjCKeychain(options: options, completion: promise)
        }
    }
#endif

    /**
     Logs out the currently logged in user *asynchronously*. Publishes when complete.

     This will also remove the session from the Keychain, log out of linked services
     and all future calls to `current` will return `nil`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static func logoutPublisher(options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            Self.logout(options: options, completion: promise)
        }
    }

    /**
     Requests *asynchronously* a password reset email to be sent to the specified email address
     associated with the user account. This email allows the user to securely reset their password on the web.
     Publishes when complete.
     - parameter email: The email address associated with the user that forgot their password.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static func passwordResetPublisher(email: String,
                                       options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            Self.passwordReset(email: email, options: options, completion: promise)
        }
    }

    /**
     Verifies *asynchronously* whether the specified password associated with the user account is valid.
     Publishes when complete.
     - parameter password: The password to be verified.
     - parameter usingPost: Set to **true** to use **POST** for sending. Will use **GET**
     otherwise. Defaults to **false**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: `usingPost == true` requires the
     [issue](https://github.com/parse-community/parse-server/issues/7784) to be addressed on
     the Parse Server, othewise you should set `usingPost = false`.
    */
    static func verifyPasswordPublisher(password: String,
                                        usingPost: Bool = false,
                                        options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            Self.verifyPassword(password: password,
                                usingPost: usingPost,
                                options: options,
                                completion: promise)
        }
    }

    /**
     Requests *asynchronously* a verification email be sent to the specified email address
     associated with the user account. Publishes when complete.
     - parameter email: The email address associated with the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static func verificationEmailPublisher(email: String,
                                           options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            Self.verificationEmail(email: email, options: options, completion: promise)
        }
    }

    /**
     Fetches the `ParseUser` *aynchronously* with the current data from the server.
     Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetchPublisher(includeKeys: [String]? = nil,
                        options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.fetch(includeKeys: includeKeys,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Saves the `ParseUser` *asynchronously* and publishes when complete.

     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
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
    func savePublisher(options: API.Options = [],
                       ignoringCustomObjectIdConfig: Bool = false) -> Future<Self, ParseError> {
        Future { promise in
            self.save(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Creates the `ParseUser` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func createPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.create(options: options,
                        completion: promise)
        }
    }

    /**
     Replaces the `ParseUser` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object replaced has the same objectId as current, it will automatically replace the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func replacePublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.replace(options: options,
                         completion: promise)
        }
    }

    /**
     Updates the `ParseUser` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object updated has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    internal func updatePublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.update(options: options,
                        completion: promise)
        }
    }

    /**
     Deletes the `ParseUser` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func deletePublisher(options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            self.delete(options: options, completion: promise)
        }
    }
}

public extension Sequence where Element: ParseUser {
    /**
     Fetches a collection of users *aynchronously* with the current data from the server and sets
     an error if one occurs. Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces an an array of Result enums with the object if a fetch was
     successful or a `ParseError` if it failed.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
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
     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces an an array of Result enums with the object if a save was
     successful or a `ParseError` if it failed.
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
    func saveAllPublisher(batchLimit limit: Int? = nil,
                          transaction: Bool = configuration.isUsingTransactions,
                          ignoringCustomObjectIdConfig: Bool = false,
                          options: API.Options = []) -> Future<[(Result<Self.Element, ParseError>)], ParseError> {
        Future { promise in
            self.saveAll(batchLimit: limit,
                         transaction: transaction,
                         ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                         options: options,
                         completion: promise)
        }
    }

    /**
     Creates a collection of users *asynchronously* and publishes when complete.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces an an array of Result enums with the object if a save was
     successful or a `ParseError` if it failed.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func createAllPublisher(batchLimit limit: Int? = nil,
                            transaction: Bool = configuration.isUsingTransactions,
                            options: API.Options = []) -> Future<[(Result<Self.Element, ParseError>)], ParseError> {
        Future { promise in
            self.createAll(batchLimit: limit,
                           transaction: transaction,
                           options: options,
                           completion: promise)
        }
    }

    /**
     Replaces a collection of users *asynchronously* and publishes when complete.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces an an array of Result enums with the object if a save was
     successful or a `ParseError` if it failed.
     - important: If an object replaced has the same objectId as current, it will automatically replace the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func replaceAllPublisher(batchLimit limit: Int? = nil,
                             transaction: Bool = configuration.isUsingTransactions,
                             options: API.Options = []) -> Future<[(Result<Self.Element, ParseError>)],
                                                                    ParseError> {
        Future { promise in
            self.replaceAll(batchLimit: limit,
                           transaction: transaction,
                           options: options,
                           completion: promise)
        }
    }

    /**
     Updates a collection of users *asynchronously* and publishes when complete.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces an an array of Result enums with the object if a save was
     successful or a `ParseError` if it failed.
     - important: If an object updated has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    internal func updateAllPublisher(batchLimit limit: Int? = nil,
                                     transaction: Bool = configuration.isUsingTransactions,
                                     options: API.Options = []) -> Future<[(Result<Self.Element, ParseError>)],
                                                                            ParseError> {
        Future { promise in
            self.updateAll(batchLimit: limit,
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
     - returns: A publisher that eventually produces an an array of Result enums with `nil` if a delete was
     successful or a `ParseError` if it failed.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func deleteAllPublisher(batchLimit limit: Int? = nil,
                            transaction: Bool = configuration.isUsingTransactions,
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
