//
//  ParseObject.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 Objects that conform to the `ParseObject` protocol have a local representation of data persisted to the Parse Server.
 This is the main protocol that is used to interact with objects in your app.

 The Swift SDK is designed for your `ParseObject`s to be **value types (structures)**.
 Since you are using value types the compiler will assist you with conforming to the `ParseObject` protocol.
 After a `ParseObject`is saved/created to a Parse Server. It is recommended to conduct any updates on a
 `mergeable` copy of your `ParseObject`. This can be accomplished by calling the `mergeable` property
 of your `ParseObject` or by calling the `set()` method on your `ParseObject`. This allows a subset
 of the fields to be updated (PATCH) of an object as oppose to replacing all of the fields of an object (PUT).
 This reduces the amount of data sent between client and server when using `save`, `saveAll`, `update`,
 `updateAll`, `replace`, `replaceAll`, to update objects.
 
 - important: It is required that all of your `ParseObject`'s be **value types (structures)** and all added
 properties be optional so they can eventually be used as Parse `Pointer`'s. If a developer really wants to
 have a required key, they should require it on the server-side or create methods to check the respective properties
 on the client-side before saving objects. See
 [here](https://github.com/parse-community/Parse-Swift/pull/315#issuecomment-1014701003)
 for more information on the reasons why. See the [Playgrounds](https://github.com/parse-community/Parse-Swift/blob/c119033f44b91570997ad24f7b4b5af8e4d47b64/ParseSwift.playground/Pages/1%20-%20Your%20first%20Object.xcplaygroundpage/Contents.swift#L32-L66) for an example.
 - important: A developer can take advantage of `mergeable` updates in two ways: 1) By calling the `set()` method when starting
 to mutate a saved `ParseObject`, or 2) implement the `merge` method in each of your`ParseObject` models.
 - note: If you plan to use custom encoding/decoding, be sure to add `objectId`, `createdAt`, `updatedAt`, and
 `ACL` to your `ParseObject`'s `CodingKeys`.
 - warning: This SDK is not designed to use **reference types(classes)** for `ParseObject`'s. Doing so is at your
 risk and may have unexpected behavior when it comes to threading. You will also need to implement
 your own `==` method to conform to `Equatable` along with with the `hash` method to conform to `Hashable`.
 It is important to note that for unsaved `ParseObject`'s, you will not be able to rely on `objectId` for
 `Equatable` and `Hashable` as your unsaved objects will not have this value yet and is nil.
*/
public protocol ParseObject: ParseTypeable,
                             Objectable,
                             Fetchable,
                             Savable,
                             Deletable,
                             Identifiable,
                             Hashable {

    /**
     A JSON encoded version of this `ParseObject` before `mergeable` was called and
     properties were changed.
     - warning: This property is not intended to be set or modified by the developer.
    */
    var originalData: Data? { get set }

    /**
     An empty copy of the respective object that allows you to update a
     a subset of the fields (PATCH) of an object as oppose to replacing an object (PUT).
     - note: It is recommended to use this to create a mergeable copy of your `ParseObject`.
     - warning: `mergeable` should only be used on `ParseObject`'s that have already
     been saved at least once to a Parse Server and have a valid `objectId`. In addition,
     the developer should have implemented added all of their properties to `merge`.
    */
    var mergeable: Self { get }

    /**
     The default initializer to ensure all `ParseObject`'s can be encoded/decoded properly.
     - important: The compiler will give you this initialzer for free
     ([memberwise initializer](https://docs.swift.org/swift-book/LanguageGuide/Initialization.html))
     as long as you declare all properties as **optional** (see **Warning** section) and you declare all other initializers in
     an **extension**. See the [Playgrounds](https://github.com/parse-community/Parse-Swift/blob/c119033f44b91570997ad24f7b4b5af8e4d47b64/ParseSwift.playground/Pages/1%20-%20Your%20first%20Object.xcplaygroundpage/Contents.swift#L32-L66) for an example.
     - attention: This initilizer **should remain empty and no properties should be implemented inside of it**. The SDK needs
     this initializer to create new instances of your `ParseObject` when saving, updating, and converting to/from Parse Pointers. If you need
     to initiaze properties, create additional initializers.
     - warning: It is required that all added properties be optional properties so they can eventually be used as
     Parse `Pointer`'s. If a developer really wants to have a required key, they should require it on the server-side or
     create methods to check the respective properties on the client-side before saving objects. See
     [here](https://github.com/parse-community/Parse-Swift/pull/315#issuecomment-1014701003)
     for more information.
     */
    init()

    /**
     Determines if a `KeyPath` of the current `ParseObject` should be restored
     by comparing it to another `ParseObject`.
     - parameter key: The `KeyPath` to check.
     - parameter original: The original `ParseObject`.
     - returns: Returns a **true** if the keyPath should be restored  or **false** otherwise.
    */
    func shouldRestoreKey<W>(_ key: KeyPath<Self, W?>,
                             original: Self) -> Bool where W: Equatable

    /**
     Merges two `ParseObject`'s with the resulting object consisting of all modified
     and unchanged Parse properties.
     - parameter with: The original object.
     - returns: The updated installation.
     - throws: An error of type `ParseError`.
     - note: This is used in combination with `merge` to only send updated
     properties to the server and then merge those changes with the original object.
     - warning: You should only call this method and should not implement it directly
     as it is already implemented for developers to use.
    */
    func mergeParse(with object: Self) throws -> Self

    /**
     Merges two `ParseObject`'s with the resulting object consisting of all modified
     and unchanged properties.

         //: Create your own value typed `ParseObject`.
         struct GameScore: ParseObject {
             //: These are required by ParseObject
             var objectId: String?
             var createdAt: Date?
             var updatedAt: Date?
             var ACL: ParseACL?

             //: Your own properties.
             var points: Int?

             //: Implement your own version of merge
             func merge(with object: Self) throws -> Self {
                 var updated = try mergeParse(with: object)
                 if updated.shouldRestoreKey(\.points,
                                                  original: object) {
                     updated.points = object.points
                 }
                 return updated
             }
         }

     - parameter with: The original object.
     - returns: The merged object.
     - throws: An error of type `ParseError`.
     - note: Use this in combination with `ParseMutable` to only send updated
     properties to the server and then merge those changes with the original object.
     - important: It is recommend you provide an implementation of this method
     for all of your `ParseObject`'s as the developer has access to all properties of a
     `ParseObject`. You should always call `mergeParse`
     in the beginning of your implementation to handle all default Parse properties. In addition,
     use `shouldRestoreKey` to compare key modifications between objects.
    */
    func merge(with object: Self) throws -> Self
}

// MARK: Default Implementations
public extension ParseObject {

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    /**
     A computed property that is the same value as `objectId` and makes it easy to use `ParseObject`'s
     as models in MVVM and SwiftUI.
     - note: `id` allows `ParseObjects`'s to be used even when they are unsaved and do not have an `objectId`.
    */
    var id: String {
        objectId ?? UUID().uuidString
    }

    var mergeable: Self {
        guard isSaved,
            originalData == nil else {
            return self
        }
        var object = Self()
        object.objectId = objectId
        object.createdAt = createdAt
        object.originalData = try? ParseCoding.jsonEncoder().encode(self)
        return object
    }

    /**
     Determines if two objects have the same objectId.
     - parameter as: Object to compare.
     - returns: Returns a **true** if the other object has the same `objectId` or **false** if unsuccessful.
    */
    func hasSameObjectId<T: ParseObject>(as other: T) -> Bool {
        return other.className == className && other.objectId == objectId && objectId != nil
    }

    /**
     Converts this `ParseObject` to a Parse Pointer.
     - returns: The pointer version of the `ParseObject`, Pointer<Self>.
    */
    func toPointer() throws -> Pointer<Self> {
        return try Pointer(self)
    }

    func shouldRestoreKey<W>(_ key: KeyPath<Self, W?>,
                             original: Self) -> Bool where W: Equatable {
        self[keyPath: key] == nil && original[keyPath: key] != self[keyPath: key]
    }

    func mergeParse(with object: Self) throws -> Self {
        guard hasSameObjectId(as: object) else {
            throw ParseError(code: .unknownError,
                             message: "objectId's of objects do not match")
        }
        var updated = self
        if shouldRestoreKey(\.ACL,
                             original: object) {
            updated.ACL = object.ACL
        }
        return updated
    }

    func merge(with object: Self) throws -> Self {
        do {
            return try mergeAutomatically(object)
        } catch {
            return try mergeParse(with: object)
        }
    }
}

// MARK: Default Implementations (Internal)
extension ParseObject {
    func shouldRevertKey<W>(_ key: KeyPath<Self, W?>,
                            original: Self) -> Bool where W: Equatable {
        original[keyPath: key] != self[keyPath: key]
    }
}

// MARK: Helper Methods
public extension ParseObject {
    /**
     Reverts the `KeyPath` of the `ParseObject` back to  the original `KeyPath`
     before mutations began.
     - throws: An error of type `ParseError`.
     - important: This reverts to the contents in `originalData`. This means `originalData` should have
     been populated by calling `mergeable` or the `set` method.
    */
    @available(*, deprecated, renamed: "revert")
    func revertKeyPath<W>(_ keyPath: WritableKeyPath<Self, W?>) throws -> Self where W: Equatable {
        try revert(keyPath)
    }

    /**
     Reverts the `ParseObject` back to the original object before mutations began.
     - throws: An error of type `ParseError`.
     - important: This reverts to the contents in `originalData`. This means `originalData` should have
     been populated by calling `mergeable` or the `set` method.
    */
    @available(*, deprecated, renamed: "revert")
    func revertObject() throws -> Self {
        try revert()
    }

    /**
     Reverts the `KeyPath` of the `ParseObject` back to  the original `KeyPath`
     before mutations began.
     - throws: An error of type `ParseError`.
     - important: This reverts to the contents in `originalData`. This means `originalData` should have
     been populated by calling `mergeable` or the `set` method.
    */
    func revert<W>(_ keyPath: WritableKeyPath<Self, W?>) throws -> Self where W: Equatable {
        guard let originalData = originalData else {
            throw ParseError(code: .unknownError,
                             message: "Missing original data to revert to")
        }
        let original = try ParseCoding.jsonDecoder().decode(Self.self,
                                                            from: originalData)
        guard hasSameObjectId(as: original) else {
            throw ParseError(code: .unknownError,
                             message: "The current object does not have the same objectId as the original")
        }
        var updated = self
        if shouldRevertKey(keyPath,
                           original: original) {
            updated[keyPath: keyPath] = original[keyPath: keyPath]
        }
        return updated
    }

    /**
     Reverts the `ParseObject` back to the original object before mutations began.
     - throws: An error of type `ParseError`.
     - important: This reverts to the contents in `originalData`. This means `originalData` should have
     been populated by calling `mergeable` or the `set` method.
    */
    func revert() throws -> Self {
        guard let originalData = originalData else {
            throw ParseError(code: .unknownError,
                             message: "Missing original data to revert to")
        }
        let original = try ParseCoding.jsonDecoder().decode(Self.self,
                                                            from: originalData)
        guard hasSameObjectId(as: original) else {
            throw ParseError(code: .unknownError,
                             message: "The current object does not have the same objectId as the original")
        }
        return original
    }

    /**
     Get the unwrapped property value.
     - parameter key: The `KeyPath` of the value to get.
     - throws: An error of type `ParseError` when the value is **nil**.
     - returns: The unwrapped value.
     */
    @discardableResult
    func get<W>(_ keyPath: KeyPath<Self, W?>) throws -> W where W: Equatable {
        guard let value = self[keyPath: keyPath] else {
            throw ParseError(code: .unknownError, message: "Could not unwrap value")
        }
        return value
    }

    /**
     Set the value of a specific `KeyPath` on a `ParseObject`.
     - parameter key: The `KeyPath` of the value to set.
     - parameter value: The value to set the `KeyPath` to.
     - returns: The updated `ParseObject`.
     - important: This method should be used when updating a `ParseObject` that has already been saved to
     a Parse Server. You can also use this method on a new `ParseObject`'s that has not been saved to a Parse Server
     as long as the `objectId` of the respective `ParseObject` is **nil**.
     - attention: If you are using the `set()` method, you do not need to implement `merge()`. Using `set()`
     may perform slower than implementing `merge()` after saving the updated `ParseObject` to a Parse Server.
     This is due to neccesary overhead required to determine what keys have been updated. If a developer finds decoding
     updated `ParseObjects`'s to be slow, implementing `merge()` may speed up the process.
     - warning: This method should always be used when making the very first update/mutation to your `ParseObject`.
     Any subsequent mutations can modify the `ParseObject` property directly or use the `set()` method.
     */
    func set<W>(_ keyPath: WritableKeyPath<Self, W?>, to value: W) -> Self where W: Equatable {
        var updated = self.mergeable
        updated[keyPath: keyPath] = value
        return updated
    }
}

// MARK: Helper Methods (Internal)
extension ParseObject {

    func mergeAutomatically(_ originalObject: Self) throws -> Self {
        let updatedEncoded = try ParseCoding.jsonEncoder().encode(self)
        let originalData = try ParseCoding.jsonEncoder().encode(originalObject)
        guard let updated = try JSONSerialization.jsonObject(with: updatedEncoded) as? [String: AnyObject],
            var original = try JSONSerialization.jsonObject(with: originalData) as? [String: AnyObject] else {
            throw ParseError(code: .unknownError,
                             message: "Could not encode/decode necessary objects")
        }
        updated.forEach { (key, value) in
            original[key] = value
        }
        let mergedEncoded = try JSONSerialization.data(withJSONObject: original)
        return try ParseCoding.jsonDecoder().decode(Self.self,
                                                    from: mergedEncoded)
    }
}

// MARK: Batch Support
public extension Sequence where Element: ParseObject {

    internal func canSendTransactions(_ usingTransactions: Bool,
                                      objectCount: Int,
                                      batchLimit: Int) throws {
        if usingTransactions {
            if objectCount > batchLimit {
                let error = ParseError(code: .unknownError,
                                       message: """
The amount of objects (\(objectCount)) cannot exceed the batch size(\(batchLimit)).
Either decrease the amount of objects, increase the batch size, or disable
transactions for this call.
""")
                throw error
            }
        }
    }

    /**
     Saves a collection of objects *synchronously* all at once and throws an error if necessary.
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
    func saveAll(batchLimit limit: Int? = nil, // swiftlint:disable:this function_body_length
                 transaction: Bool = configuration.isUsingTransactions,
                 ignoringCustomObjectIdConfig: Bool = false,
                 options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        var childObjects = [String: PointerType]()
        var childFiles = [UUID: ParseFile]()
        var error: ParseError?

        var commands = [API.Command<Self.Element, Self.Element>]()
        try forEach {
            let object = $0
            let group = DispatchGroup()
            group.enter()
            object.ensureDeepSave(options: options,
                                  // swiftlint:disable:next line_length
                                  isShouldReturnIfChildObjectsFound: transaction) { (savedChildObjects, savedChildFiles, parseError) -> Void in
                // If an error occurs, everything should be skipped
                if parseError != nil {
                    error = parseError
                }
                savedChildObjects.forEach {(key, value) in
                    if error != nil {
                        return
                    }
                    if childObjects[key] == nil {
                        childObjects[key] = value
                    } else {
                        error = ParseError(code: .unknownError, message: "circular dependency")
                        return
                    }
                }
                savedChildFiles.forEach {(key, value) in
                    if error != nil {
                        return
                    }
                    if childFiles[key] == nil {
                        childFiles[key] = value
                    } else {
                        error = ParseError(code: .unknownError, message: "circular dependency")
                        return
                    }
                }
                group.leave()
            }
            group.wait()
            if let error = error {
                throw error
            }
            commands.append(try object.saveCommand(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig))
        }

        var returnBatch = [(Result<Self.Element, ParseError>)]()
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
        let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
        try batches.forEach {
            let currentBatch = try API.Command<Self.Element, Self.Element>
                .batch(commands: $0, transaction: transaction)
                .execute(options: options,
                         batching: true,
                         childObjects: childObjects,
                         childFiles: childFiles)
            returnBatch.append(contentsOf: currentBatch)
        }
        return returnBatch
    }

    /**
     Saves a collection of objects all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
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
    func saveAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        transaction: Bool = configuration.isUsingTransactions,
        ignoringCustomObjectIdConfig: Bool = false,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let method = Method.save
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let objects = try await batchCommand(method: method,
                                                     batchLimit: limit,
                                                     transaction: transaction,
                                                     ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                                                     options: options,
                                                     callbackQueue: callbackQueue)
                completion(.success(objects))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        batchCommand(method: method,
                     batchLimit: limit,
                     transaction: transaction,
                     ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                     options: options,
                     callbackQueue: callbackQueue,
                     completion: completion)
        #endif
    }

    /**
     Creates a collection of objects all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func createAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        transaction: Bool = configuration.isUsingTransactions,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let method = Method.create
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let objects = try await batchCommand(method: method,
                                                     batchLimit: limit,
                                                     transaction: transaction,
                                                     options: options,
                                                     callbackQueue: callbackQueue)
                completion(.success(objects))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        batchCommand(method: method,
                     batchLimit: limit,
                     transaction: transaction,
                     options: options,
                     callbackQueue: callbackQueue,
                     completion: completion)
        #endif
    }

    /**
     Replaces a collection of objects all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func replaceAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        transaction: Bool = configuration.isUsingTransactions,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let method = Method.replace
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let objects = try await batchCommand(method: method,
                                                     batchLimit: limit,
                                                     transaction: transaction,
                                                     options: options,
                                                     callbackQueue: callbackQueue)
                completion(.success(objects))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        batchCommand(method: method,
                     batchLimit: limit,
                     transaction: transaction,
                     options: options,
                     callbackQueue: callbackQueue,
                     completion: completion)
        #endif
    }

    /**
     Updates a collection of objects all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    internal func updateAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        transaction: Bool = configuration.isUsingTransactions,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let method = Method.update
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let objects = try await batchCommand(method: method,
                                                     batchLimit: limit,
                                                     transaction: transaction,
                                                     options: options,
                                                     callbackQueue: callbackQueue)
                completion(.success(objects))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        batchCommand(method: method,
                     batchLimit: limit,
                     transaction: transaction,
                     options: options,
                     callbackQueue: callbackQueue,
                     completion: completion)
        #endif
    }

    internal func batchCommand(method: Method, // swiftlint:disable:this function_parameter_count
                               batchLimit limit: Int?,
                               transaction: Bool,
                               ignoringCustomObjectIdConfig: Bool = false,
                               options: API.Options,
                               callbackQueue: DispatchQueue,
                               completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let uuid = UUID()
        let queue = DispatchQueue(label: "com.parse.batch.\(uuid)",
                                  qos: .default,
                                  attributes: .concurrent,
                                  autoreleaseFrequency: .inherit,
                                  target: nil)
        queue.sync {
            var childObjects = [String: PointerType]()
            var childFiles = [UUID: ParseFile]()
            var error: ParseError?
            var commands = [API.Command<Self.Element, Self.Element>]()
            let objects = map { $0 }
            for object in objects {
                let group = DispatchGroup()
                group.enter()
                object.ensureDeepSave(options: options,
                                      // swiftlint:disable:next line_length
                                      isShouldReturnIfChildObjectsFound: transaction) { (savedChildObjects, savedChildFiles, parseError) -> Void in
                    // If an error occurs, everything should be skipped
                    if let parseError = parseError {
                        error = parseError
                    }
                    savedChildObjects.forEach {(key, value) in
                        guard error == nil else {
                            return
                        }
                        guard childObjects[key] == nil else {
                            error = ParseError(code: .unknownError, message: "circular dependency")
                            return
                        }
                        childObjects[key] = value
                    }
                    savedChildFiles.forEach {(key, value) in
                        guard error == nil else {
                            return
                        }
                        guard childFiles[key] == nil else {
                            error = ParseError(code: .unknownError, message: "circular dependency")
                            return
                        }
                        childFiles[key] = value
                    }
                    group.leave()
                }
                group.wait()
                if let error = error {
                    callbackQueue.async {
                        completion(.failure(error))
                    }
                    return
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
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                    return
                }
            }

            do {
                var returnBatch = [(Result<Self.Element, ParseError>)]()

                let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
                try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
                let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
                var completed = 0
                for batch in batches {
                    API.Command<Self.Element, Self.Element>
                            .batch(commands: batch, transaction: transaction)
                            .executeAsync(options: options,
                                          batching: true,
                                          callbackQueue: callbackQueue,
                                          childObjects: childObjects,
                                          childFiles: childFiles) { results in
                        switch results {

                        case .success(let saved):
                            returnBatch.append(contentsOf: saved)
                            if completed == (batches.count - 1) {
                                completion(.success(returnBatch))
                            }
                            completed += 1
                        case .failure(let error):
                            completion(.failure(error))
                            return
                        }
                    }
                }
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    /**
     Fetches a collection of objects *synchronously* all at once and throws an error if necessary.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns an array of Result enums with the object if a fetch was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - warning: The order in which objects are returned are not guarenteed. You should not expect results in
     any particular order.
    */
    func fetchAll(includeKeys: [String]? = nil,
                  options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {

        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(compactMap { $0.objectId })
            var query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
                .limit(uniqueObjectIds.count)
            if let include = includeKeys {
                query = query.include(include)
            }
            let fetchedObjects = try query.find(options: options)
            var fetchedObjectsToReturn = [(Result<Self.Element, ParseError>)]()

            uniqueObjectIds.forEach {
                let uniqueObjectId = $0
                if let fetchedObject = fetchedObjects.first(where: {$0.objectId == uniqueObjectId}) {
                    fetchedObjectsToReturn.append(.success(fetchedObject))
                } else {
                    fetchedObjectsToReturn.append(.failure(ParseError(code: .objectNotFound,
                                                                      // swiftlint:disable:next line_length
                                                                      message: "objectId \"\(uniqueObjectId)\" was not found in className \"\(Self.Element.className)\"")))
                }
            }
            return fetchedObjectsToReturn
        } else {
            throw ParseError(code: .unknownError, message: "all items to fetch must be of the same class")
        }
    }

    /**
     Fetches a collection of objects all at once *asynchronously* and executes the completion block when done.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - warning: The order in which objects are returned are not guarenteed. You should not expect results in
     any particular order.
    */
    func fetchAll(
        includeKeys: [String]? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(compactMap { $0.objectId })
            var query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
            if let include = includeKeys {
                query = query.include(include)
            }
            query.find(options: options, callbackQueue: callbackQueue) { result in
                switch result {

                case .success(let fetchedObjects):
                    var fetchedObjectsToReturn = [(Result<Self.Element, ParseError>)]()

                    uniqueObjectIds.forEach {
                        let uniqueObjectId = $0
                        if let fetchedObject = fetchedObjects.first(where: {$0.objectId == uniqueObjectId}) {
                            fetchedObjectsToReturn.append(.success(fetchedObject))
                        } else {
                            fetchedObjectsToReturn.append(.failure(ParseError(code: .objectNotFound,
                                                                              // swiftlint:disable:next line_length
                                                                              message: "objectId \"\(uniqueObjectId)\" was not found in className \"\(Self.Element.className)\"")))
                        }
                    }
                    completion(.success(fetchedObjectsToReturn))
                case .failure(let error):
                    callbackQueue.async {
                        completion(.failure(error))
                    }
                }
            }
        } else {
            callbackQueue.async {
                completion(.failure(ParseError(code: .unknownError,
                                               message: "all items to fetch must be of the same class")))
            }
        }
    }

    /**
     Deletes a collection of objects *synchronously* all at once and throws an error if necessary.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns `nil` if the delete successful or a `ParseError` if it failed.
        1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
        array of other Parse.Error objects. Each error object in this array
        has an "object" property that references the object that could not be
        deleted (for instance, because that object could not be found).
        2. A non-aggregate Parse.Error. This indicates a serious error that
        caused the delete operation to be aborted partway through (for
        instance, a connection failure in the middle of the delete).
     - throws: An error of type `ParseError`.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func deleteAll(batchLimit limit: Int? = nil,
                   transaction: Bool = configuration.isUsingTransactions,
                   options: API.Options = []) throws -> [(Result<Void, ParseError>)] {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        var returnBatch = [(Result<Void, ParseError>)]()
        let commands = try map { try $0.deleteCommand() }
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
        let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
        try batches.forEach {
            let currentBatch = try API.Command<Self.Element, (Result<Void, ParseError>)>
                .batch(commands: $0,
                       transaction: transaction)
                .execute(options: options)
            returnBatch.append(contentsOf: currentBatch)
        }
        return returnBatch
    }

    /**
     Deletes a collection of objects all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[ParseError?], ParseError>)`.
     Each element in the array is `nil` if the delete successful or a `ParseError` if it failed.
     1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
     array of other Parse.Error objects. Each error object in this array
     has an "object" property that references the object that could not be
     deleted (for instance, because that object could not be found).
     2. A non-aggregate Parse.Error. This indicates a serious error that
     caused the delete operation to be aborted partway through (for
     instance, a connection failure in the middle of the delete).
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func deleteAll(
        batchLimit limit: Int? = nil,
        transaction: Bool = configuration.isUsingTransactions,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Void, ParseError>)], ParseError>) -> Void
    ) {
        do {
            var options = options
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            var returnBatch = [(Result<Void, ParseError>)]()
            let commands = try map({ try $0.deleteCommand() })
            let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
            try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
            let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
            var completed = 0
            for batch in batches {
                API.Command<Self.Element, ParseError?>
                        .batch(commands: batch, transaction: transaction)
                        .executeAsync(options: options,
                                      callbackQueue: callbackQueue) { results in
                    switch results {

                    case .success(let saved):
                        returnBatch.append(contentsOf: saved)
                        if completed == (batches.count - 1) {
                            completion(.success(returnBatch))
                        }
                        completed += 1
                    case .failure(let error):
                        completion(.failure(error))
                        return
                    }
                }
            }
        } catch {
            let defaultError = ParseError(code: .unknownError,
                                          message: error.localizedDescription)
            let parseError = error as? ParseError ?? defaultError
            callbackQueue.async {
                completion(.failure(parseError))
            }
        }
    }
}

// MARK: CustomDebugStringConvertible
extension ParseObject {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "\(className) ()"
        }

        return "\(className) (\(descriptionString))"
    }
}

// MARK: CustomStringConvertible
extension ParseObject {
    public var description: String {
        debugDescription
    }
}

// MARK: Fetchable
extension ParseObject {

    /**
     Fetches the `ParseObject` *synchronously* with the current data from the server.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of `ParseError` type.
     - returns: Returns the fetched `ParseObject`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func fetch(includeKeys: [String]? = nil,
                      options: API.Options = []) throws -> Self {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        return try fetchCommand(include: includeKeys).execute(options: options)
    }

    /**
     Fetches the `ParseObject` *asynchronously* and executes the given callback block.
     - parameter includeKeys: The name(s) of the key(s) to include. Use `["*"]` to include
     all keys one level deep.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func fetch(
        includeKeys: [String]? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
         do {
            try fetchCommand(include: includeKeys)
                .executeAsync(options: options,
                              callbackQueue: callbackQueue) { result in
                    completion(result)
            }
         } catch {
            callbackQueue.async {
                if let error = error as? ParseError {
                    completion(.failure(error))
                } else {
                    completion(.failure(ParseError(code: .unknownError,
                                                   message: error.localizedDescription)))
                }
            }
         }
    }

    internal func fetchCommand(include: [String]?) throws -> API.Command<Self, Self> {
        try API.Command<Self, Self>.fetch(self, include: include)
    }
}

// MARK: Savable
extension ParseObject {

    /**
     Saves the `ParseObject` *synchronously* and throws an error if there is an issue.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.

     - returns: Returns saved `ParseObject`.
    */
    @discardableResult
    public func save(options: API.Options = []) throws -> Self {
        try save(ignoringCustomObjectIdConfig: false, options: options)
    }

    /**
     Saves the `ParseObject` *synchronously* and throws an error if there is an issue.
     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.

     - returns: Returns saved `ParseObject`.
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
    @discardableResult
    public func save(ignoringCustomObjectIdConfig: Bool = false,
                     options: API.Options = []) throws -> Self {
        var childObjects: [String: PointerType]?
        var childFiles: [UUID: ParseFile]?
        var error: ParseError?
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let group = DispatchGroup()
        group.enter()
        self.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, parseError) in
            childObjects = savedChildObjects
            childFiles = savedChildFiles
            error = parseError
            group.leave()
        }
        group.wait()

        if let error = error {
            throw error
        }

        return try saveCommand(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig)
            .execute(options: options,
                     childObjects: childObjects,
                     childFiles: childFiles)
    }

    /**
     Saves the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
    */
    public func save(
        ignoringCustomObjectIdConfig: Bool = false,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.save
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let object = try await command(method: method,
                                               ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                                               options: options,
                                               callbackQueue: callbackQueue)
                completion(.success(object))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        command(method: method,
                ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                options: options,
                callbackQueue: callbackQueue,
                completion: completion)
        #endif
    }

    /**
     Creates the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func create(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.create
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let object = try await command(method: method,
                                               options: options,
                                               callbackQueue: callbackQueue)
                completion(.success(object))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        command(method: method,
                options: options,
                callbackQueue: callbackQueue,
                completion: completion)
        #endif
    }

    /**
     Replaces the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func replace(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.replace
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let object = try await command(method: method,
                                               options: options,
                                               callbackQueue: callbackQueue)
                completion(.success(object))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        command(method: method,
                options: options,
                callbackQueue: callbackQueue,
                completion: completion)
        #endif
    }

    /**
     Updates the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    func update(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.update
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let object = try await command(method: method,
                                               options: options,
                                               callbackQueue: callbackQueue)
                completion(.success(object))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        command(method: method,
                options: options,
                callbackQueue: callbackQueue,
                completion: completion)
        #endif
    }

    func command(method: Method,
                 ignoringCustomObjectIdConfig: Bool = false,
                 options: API.Options,
                 callbackQueue: DispatchQueue,
                 completion: @escaping (Result<Self, ParseError>) -> Void) {
        self.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, error) in
            guard let parseError = error else {
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
                    command
                        .executeAsync(options: options,
                                      callbackQueue: callbackQueue,
                                      childObjects: savedChildObjects,
                                      childFiles: savedChildFiles,
                                      completion: completion)
                } catch {
                    let defaultError = ParseError(code: .unknownError,
                                                  message: error.localizedDescription)
                    let parseError = error as? ParseError ?? defaultError
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
                return
            }
            callbackQueue.async {
                completion(.failure(parseError))
            }
        }
    }

    internal func saveCommand(ignoringCustomObjectIdConfig: Bool = false) throws -> API.Command<Self, Self> {
        try API.Command<Self, Self>.save(self,
                                         original: originalData,
                                         ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig)
    }

    internal func createCommand() -> API.Command<Self, Self> {
        API.Command<Self, Self>.create(self)
    }

    internal func replaceCommand() throws -> API.Command<Self, Self> {
        try API.Command<Self, Self>.replace(self,
                                            original: originalData)
    }

    internal func updateCommand() throws -> API.Command<Self, Self> {
        try API.Command<Self, Self>.update(self,
                                           original: originalData)
    }

    // swiftlint:disable:next function_body_length
    internal func ensureDeepSave(options: API.Options = [],
                                 isShouldReturnIfChildObjectsFound: Bool = false,
                                 completion: @escaping ([String: PointerType],
                                                        [UUID: ParseFile], ParseError?) -> Void) {
        let uuid = UUID()
        let queue = DispatchQueue(label: "com.parse.deepSave.\(uuid)",
                                  qos: .default,
                                  attributes: .concurrent,
                                  autoreleaseFrequency: .inherit,
                                  target: nil)
        var options = options
        // Remove any caching policy added by the developer as fresh data
        // from the server is needed.
        options.remove(.cachePolicy(.reloadIgnoringLocalCacheData))
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))

        queue.sync {
            var objectsFinishedSaving = [String: PointerType]()
            var filesFinishedSaving = [UUID: ParseFile]()
            do {
                let object = try ParseCoding.parseEncoder()
                    .encode(self,
                            objectsSavedBeforeThisOne: nil,
                            filesSavedBeforeThisOne: nil)

                var waitingToBeSaved = object.unsavedChildren
                if isShouldReturnIfChildObjectsFound && waitingToBeSaved.count > 0 {
                    let error = ParseError(code: .unknownError,
                                           message: """
    When using transactions, all child ParseObjects have to originally
    be saved to the Parse Server. Either save all child objects first
    or disable transactions for this call.
    """)
                    completion([String: PointerType](), [UUID: ParseFile](), error)
                    return
                }
                while waitingToBeSaved.count > 0 {
                    var savableObjects = [ParseEncodable]()
                    var savableFiles = [ParseFile]()
                    var nextBatch = [ParseEncodable]()
                    try waitingToBeSaved.forEach { parseType in

                        if let parseFile = parseType as? ParseFile {
                            // ParseFiles can be saved now
                            savableFiles.append(parseFile)
                        } else if let parseObject = parseType as? Objectable {
                            // This is a ParseObject
                            let waitingObjectInfo = try ParseCoding
                                .parseEncoder()
                                .encode(parseObject,
                                        collectChildren: true,
                                        objectsSavedBeforeThisOne: objectsFinishedSaving,
                                        filesSavedBeforeThisOne: filesFinishedSaving)

                            if waitingObjectInfo.unsavedChildren.count == 0 {
                                //If this ParseObject has no additional children, it can be saved now
                                savableObjects.append(parseObject)
                            } else {
                                //Else this ParseObject needs to wait until it is children are saved
                                nextBatch.append(parseObject)
                            }
                        }
                    }
                    waitingToBeSaved = nextBatch

                    if waitingToBeSaved.count > 0 && savableObjects.count == 0 && savableFiles.count == 0 {
                        completion(objectsFinishedSaving,
                                   filesFinishedSaving,
                                   ParseError(code: .unknownError,
                                              message: "Found a circular dependency in ParseObject."))
                        return
                    }
                    if savableObjects.count > 0 {
                        let savedChildObjects = try self.saveAll(objects: savableObjects,
                                                                 options: options)
                        let savedChildPointers = try savedChildObjects.compactMap { try $0.get() }
                        for (index, object) in savableObjects.enumerated() {
                            let hash = try BaseObjectable.createHash(object)
                            objectsFinishedSaving[hash] = savedChildPointers[index]
                        }
                    }

                    try savableFiles.forEach {
                        filesFinishedSaving[$0.id] = try $0.save(options: options)
                    }
                }
                completion(objectsFinishedSaving, filesFinishedSaving, nil)
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                completion(objectsFinishedSaving, filesFinishedSaving, parseError)
            }
        }
    }
}

// MARK: Savable Encodable Version
internal extension ParseEncodable {
    func saveAll(objects: [ParseEncodable],
                 transaction: Bool = configuration.isUsingTransactions,
                 options: API.Options = []) throws -> [(Result<PointerType, ParseError>)] {
        try API.NonParseBodyCommand<AnyCodable, PointerType>
                .batch(objects: objects,
                       transaction: transaction)
                .execute(options: options)
    }
}

// MARK: Deletable
extension ParseObject {
    /**
     Deletes the `ParseObject` *synchronously* with the current data from the server.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of `ParseError` type.
    */
    public func delete(options: API.Options = []) throws {
        _ = try deleteCommand().execute(options: options)
    }

    /**
     Deletes the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
    */
    public func delete(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Void, ParseError>) -> Void
    ) {
         do {
            try deleteCommand().executeAsync(options: options,
                                             callbackQueue: callbackQueue) { result in
                switch result {

                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
         } catch let error as ParseError {
            callbackQueue.async {
                completion(.failure(error))
            }
         } catch {
            callbackQueue.async {
                completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
            }
         }
    }

    internal func deleteCommand() throws -> API.NonParseBodyCommand<NoBody, NoBody> {
        try API.NonParseBodyCommand<NoBody, NoBody>.delete(self)
    }
} // swiftlint:disable:this file_length
