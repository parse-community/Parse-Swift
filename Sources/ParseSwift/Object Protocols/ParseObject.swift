//
//  ParseObject.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation

/**
 Objects that conform to the `ParseObject` protocol have a local representation of data persisted to the Parse cloud.
 This is the main protocol that is used to interact with objects in your app.
 - note: `ParseObject`s can be "value types" (structs) or reference types "classes". If you are using value types
 there isn't much else you need to do but to conform to ParseObject. If you are using reference types, see the warning.
 - warning: If you plan to use "reference types" (classes), you will need to implement your own `==` method to conform
 to `Equatable` along with with the `hash` method to conform to `Hashable`. It is important to note that for unsaved
`ParseObject`s, you won't be able to rely on `objectId` for `Equatable` and `Hashable` as your unsaved objects
 won't have this value yet and is nil. A possible way to address this is by creating a `UUID` for your objects locally
 and relying on that for `Equatable` and `Hashable`, otherwise it's possible you will get "circular dependency errors"
 depending on your implementation.
*/
public protocol ParseObject: Objectable, Fetchable, Saveable, Deletable, Hashable, CustomDebugStringConvertible {}

// MARK: Default Implementations
extension ParseObject {

    /**
     Determines if to objects have the same objectId

     - parameter as: object to compare

     - returns: Returns a `true` if the other object has the same `objectId` or `false` if unsuccessful.
    */
    public func hasSameObjectId<T: ParseObject>(as other: T) -> Bool {
        return other.className == className && other.objectId == objectId && objectId != nil
    }
}

// MARK: Batch Support
public extension Sequence where Element: ParseObject {

    /**
     Saves a collection of objects *synchronously* all at once and throws an error if necessary.

     - parameter options: A set of options used to save objects. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a save was successful or a `ParseError` if it failed.
     - throws: `ParseError`
    */
    func saveAll(options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {
        let commands = map { $0.saveCommand() }
        return try API.Command<Self.Element, Self.Element>
                .batch(commands: commands)
                .execute(options: options)
    }

    /**
     Saves a collection of objects all at once *asynchronously* and executes the completion block when done.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
    */
    func saveAll(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let commands = map { $0.saveCommand() }
        API.Command<Self.Element, Self.Element>
                .batch(commands: commands)
                .executeAsync(options: options, callbackQueue: callbackQueue, completion: completion)
    }
}

// MARK: Batch Support
internal extension Sequence where Element: Encodable {

    /**
     Saves a collection of objects *synchronously* all at once and throws an error if necessary.

     - parameter options: A set of options used to save objects. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a save was successful or a `ParseError` if it failed.
     - throws: `ParseError`
    */
    func saveAll(options: API.Options = []) throws -> [(Result<PointerType, ParseError>)] {
        let commands = try map { try $0.saveCommand() }
        return try API.Command<Self.Element, BaseObjectable>
                .batch(commands: commands)
                .execute(options: options)
    }
}

// MARK: CustomDebugStringConvertible
extension ParseObject {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.parseEncoder(skipKeys: false).encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "\(className) ()"
        }

        return "\(className) (\(descriptionString))"
    }
}

// MARK: Fetchable
extension ParseObject {
    internal static func updateKeychainIfNeeded(_ results: [Self], deleting: Bool = false) throws {
        guard let currentUser = BaseParseUser.current else {
            return
        }

        var foundCurrentUserObjects = results.filter { $0.hasSameObjectId(as: currentUser) }
        foundCurrentUserObjects = try foundCurrentUserObjects.sorted(by: {
            if $0.updatedAt == nil || $1.updatedAt == nil {
                throw ParseError(code: .unknownError,
                                 message: "Objects from the server should always have an 'updatedAt'")
            }
            return $0.updatedAt!.compare($1.updatedAt!) == .orderedDescending
        })
        if let foundCurrentUser = foundCurrentUserObjects.first {
            if !deleting {
                let encoded = try ParseCoding.parseEncoder(skipKeys: false).encode(foundCurrentUser)
                let updatedCurrentUser = try ParseCoding.jsonDecoder().decode(BaseParseUser.self, from: encoded)
                BaseParseUser.current = updatedCurrentUser
                BaseParseUser.saveCurrentContainerToKeychain()
            } else {
                BaseParseUser.deleteCurrentContainerFromKeychain()
            }
        } else if results.first?.className == BaseParseInstallation.className {
            guard let currentInstallation = BaseParseInstallation.current else {
                return
            }
            var saveInstallation: Self?
            let foundCurrentInstallationObjects = results.filter { $0.hasSameObjectId(as: currentInstallation) }
            if let foundCurrentInstallation = foundCurrentInstallationObjects.first {
                saveInstallation = foundCurrentInstallation
            } else {
                saveInstallation = results.first
            }
            if saveInstallation != nil {
                if !deleting {
                    let encoded = try ParseCoding.parseEncoder(skipKeys: false).encode(saveInstallation!)
                    let updatedCurrentInstallation =
                        try ParseCoding.jsonDecoder().decode(BaseParseInstallation.self, from: encoded)
                    BaseParseInstallation.current = updatedCurrentInstallation
                    BaseParseInstallation.saveCurrentContainerToKeychain()
                } else {
                    BaseParseInstallation.deleteCurrentContainerFromKeychain()
                }
            }
        }
    }

    /**
     Fetches the ParseObject *synchronously* with the current data from the server and sets an error if it occurs.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - throws: An Error of `ParseError` type.
    */
    public func fetch(options: API.Options = []) throws -> Self {
        let result: Self = try fetchCommand().execute(options: options)
        try? Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Fetches the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion.  Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func fetch(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
         do {
            try fetchCommand().executeAsync(options: options, callbackQueue: callbackQueue) { result in
                if case .success(let foundResult) = result {
                    try? Self.updateKeychainIfNeeded([foundResult])
                }
                completion(result)
            }
         } catch let error as ParseError {
             completion(.failure(error))
         } catch {
             completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
         }
    }

    internal func fetchCommand() throws -> API.Command<Self, Self> {
        return try API.Command<Self, Self>.fetchCommand(self)
    }
}

// MARK: Mutations
public extension ParseObject {
    var mutationContainer: ParseMutationContainer<Self> {
        return ParseMutationContainer(target: self)
    }
}

// MARK: Queryable
public extension ParseObject {

    static func query() -> Query<Self> {
        Query<Self>()
    }

    static func query(_ constraints: QueryConstraint...) -> Query<Self> {
        Query<Self>(constraints)
    }

    static func query(_ constraints: [QueryConstraint]) -> Query<Self> {
        Query<Self>(constraints)
    }
}

// MARK: Saveable
extension ParseObject {

    /**
     Saves the `ParseObject` *synchronously* and thows an error if there's an issue.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - throws: A Error of type `ParseError`.

     - returns: Returns saved  `ParseObject`.
    */
    public func save(options: API.Options = []) throws -> Self {
        var childObjects: [NSDictionary: PointerType]?
        var error: ParseError?
        let group = DispatchGroup()
        group.enter()
        self.ensureDeepSave(options: options) { result in
            switch result {

            case .success(let savedChildObjects):
                childObjects = savedChildObjects
                group.leave()
            case .failure(let parseError):
                error = parseError
            }
        }
        group.wait()

        if let error = error {
            throw error
        }

        let result: Self = try saveCommand().execute(options: options, childObjects: childObjects)
        try? Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Saves the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func save(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        self.ensureDeepSave(options: options) { result in
            switch result {

            case .success(let savedChildObjects):
                self.saveCommand().executeAsync(options: options, callbackQueue: callbackQueue,
                                           childObjects: savedChildObjects) { result in
                    if case .success(let foundResults) = result {
                        try? Self.updateKeychainIfNeeded([foundResults])
                    }
                    completion(result)
                }
            case .failure(let parseError):
                completion(.failure(parseError))
            }
        }
    }

    internal func saveCommand() -> API.Command<Self, Self> {
        return API.Command<Self, Self>.saveCommand(self)
    }

    internal func ensureDeepSave(options: API.Options = [],
                                 completion: @escaping (Result<[NSDictionary: PointerType], ParseError>) -> Void) {

        let queue = DispatchQueue(label: "com.parse.deepSave", qos: .default,
                                  attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)

        queue.sync {
            do {
                let object = try ParseCoding.parseEncoder().encode(self, collectChildren: true,
                                                                   objectsSavedBeforeThisOne: nil)

                var waitingToBeSaved = object.unsavedChildren
                var finishedSaving = [NSDictionary: PointerType]()
                while waitingToBeSaved.count > 0 {
                    var savable = [Encodable]()
                    var nextBatch = [Encodable]()
                    try waitingToBeSaved.forEach { parseObject in

                        let waitingObjectInfo = try ParseCoding.parseEncoder().encode(parseObject,
                                                                         collectChildren: true,
                                                                         objectsSavedBeforeThisOne: finishedSaving)

                        if waitingObjectInfo.unsavedChildren.count == 0 {
                            savable.append(parseObject)
                        } else {
                            nextBatch.append(parseObject)
                        }
                    }
                    waitingToBeSaved = nextBatch

                    if savable.count == 0 {
                        completion(.failure(ParseError(code: .unknownError,
                                                       message: "Found a circular dependency in ParseObject.")))
                        return
                    }

                    //Currently, batch isn't working for Encodable
                    //savable.saveAll(encodableObjects: savable)
                    try savable.forEach {
                        let hash = BaseObjectable.createHash($0)
                        finishedSaving[hash] = try $0.save(options: options)
                    }
                }
                completion(.success(finishedSaving))
            } catch {
                guard let parseError = error as? ParseError else {
                    completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
                    return
                }
                completion(.failure(parseError))
            }
        }
    }
}

// MARK: Savable Encodable Version
internal extension Encodable {
    func save(options: API.Options = []) throws -> PointerType {
        return try saveCommand().execute(options: options)
    }

    func saveCommand() throws -> API.Command<Self, PointerType> {
        return try API.Command<Self, PointerType>.saveCommand(self)
    }

    func saveAll<T: Encodable>(options: API.Options = [],
                               encodableObjects: [T]) throws -> [(Result<PointerType, ParseError>)] {
        let commands = try encodableObjects.map { try $0.saveCommand() }
        return try API.Command<T, BaseObjectable>
                .batch(commands: commands)
                .execute(options: options)
    }
}

// MARK: Deletable
extension ParseObject {
    /**
     Deletes the ParseObject *synchronously* with the current data from the server and sets an error if it occurs.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - throws: An Error of `ParseError` type.
    */
    public func delete(options: API.Options = []) throws {
        _ = try deleteCommand().execute(options: options)
        try? Self.updateKeychainIfNeeded([self], deleting: true)
    }

    /**
     Deletes the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion.  Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func delete(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (ParseError?) -> Void
    ) {
         do {
            try deleteCommand().executeAsync(options: options, callbackQueue: callbackQueue) { result in
                switch result {

                case .success:
                    try? Self.updateKeychainIfNeeded([self], deleting: true)
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
            }
         } catch let error as ParseError {
             completion(error)
         } catch {
             completion(ParseError(code: .unknownError, message: error.localizedDescription))
         }
    }

    internal func deleteCommand() throws -> API.Command<NoBody, NoBody> {
        return try API.Command<NoBody, NoBody>.deleteCommand(self)
    }
}

public extension ParseObject {
    func toPointer() -> Pointer<Self> {
        return Pointer(self)
    }
}// swiftlint:disable:this file_length
