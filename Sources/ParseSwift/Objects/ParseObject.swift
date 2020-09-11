//
//  ParseObject.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation

/**
 The `ParseObject` class is a local representation of data persisted to the Parse cloud.
 This is the main class that is used to interact with objects in your app.
*/
public protocol ParseObject: Fetchable, Saveable, CustomDebugStringConvertible {
    /**
    The class name of the object.
    */
    static var className: String { get }

    /**
    The id of the object.
    */
    var objectId: String? { get set }

    /**
    When the object was created.
    */
    var createdAt: Date? { get set }

    /**
    When the object was last updated.
    */
    var updatedAt: Date? { get set }

    /**
    The ACL for this object.
    */
    var ACL: ACL? { get set }
}

// MARK: Default Implementations
extension ParseObject {
    /**
    The class name of the object.
    */
    public static var className: String {
        let classType = "\(type(of: self))"
        return classType.components(separatedBy: ".").first! // strip .Type
    }

    /**
    The class name of the object.
    */
    public var className: String {
        return Self.className
    }

    /**
     Determines if a object has the same objectId
    
     - parameter as: object to compare
     
     - returns: Returns a `true` if the other object has the same `objectId` or `false` if unsuccesfull.
    */
    public func hasSameObjectId<T: ParseObject>(as other: T) -> Bool {
        return other.className == className && other.objectId == objectId && objectId != nil
    }
}

// MARK: Batch Support
public extension Sequence where Element: ParseObject {

    /**
     Saves a collection of objects *synchronously* all at once and throws an error if necessary.
    
     - parameter options: objects The array of objects to save.
     
     - returns: Returns a Result enum with the object if a save was successful or a `ParseError` if unsuccesfull.
     - throws:`ParseError`
    */
    func saveAll(options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {
        let commands = map { $0.saveCommand() }
        return try API.Command<Self.Element, Self.Element>
                .batch(commands: commands)
                .execute(options: options)
    }

    /**
     Saves a collection of objects all at once `asynchronously` and executes the block when done.
    
     - parameter objects: The array of objects to save.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
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

// MARK: Convenience
extension ParseObject {
    var endpoint: API.Endpoint {
        if let objectId = objectId {
            return .object(className: className, objectId: objectId)
        }

        return .objects(className: className)
    }

    var isSaved: Bool {
        return objectId != nil
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

// MARK: Fetchable
extension ParseObject {
    internal static func updateKeychainIfNeeded(_ results: [Self], saving: Bool = false) throws {
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
            let encoded = try ParseCoding.parseEncoder(skipKeys: false).encode(foundCurrentUser)
            let updatedCurrentUser = try ParseCoding.jsonDecoder().decode(BaseParseUser.self, from: encoded)
            BaseParseUser.current = updatedCurrentUser
            BaseParseUser.saveCurrentContainerToKeychain()
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
                let encoded = try ParseCoding.parseEncoder(skipKeys: false).encode(saveInstallation!)
                let updatedCurrentInstallation =
                    try ParseCoding.jsonDecoder().decode(BaseParseInstallation.self, from: encoded)
                BaseParseInstallation.current = updatedCurrentInstallation
                BaseParseInstallation.saveCurrentContainerToKeychain()
            }
        }
    }

    /**
     *Synchronously* fetches the ParseObject with the current data from the server and sets an error if it occurs.
    
     - parameter error: Pointer to an `ParseError` that will be set if necessary.
    */
    public func fetch(options: API.Options) throws -> Self {
        let result: Self = try fetchCommand().execute(options: options)
        try? Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Fetches the `ParseObject` *asynchronously* and executes the given callback block.
    
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func fetch(
        options: API.Options,
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
    static func find() throws -> [Self] {
        return try query().find()
    }

    static func query() -> Query<Self> {
        return Query<Self>()
    }

    static func query(_ constraints: QueryConstraint...) -> Query<Self> {
        return Query(constraints)
    }
}

// MARK: Saveable
extension ParseObject {

    /**
     *Synchronously* saves the `ParseObject` and sets an error if it occurs.
     
     - parameter error: Pointer to an `ParseError` that will be set if necessary.
    
     - returns: Returns whether the save succeeded.
    */
    public func save(options: API.Options) throws -> Self {
        let result: Self = try saveCommand().execute(options: options)
        try? Self.updateKeychainIfNeeded([result], saving: true)
        return result
    }

    /**
     Saves the `ParseObject` *asynchronously* and executes the given callback block.
     - parameter completion: The block to execute.
    
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func save(
        options: API.Options,
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        saveCommand().executeAsync(options: options, callbackQueue: callbackQueue) { result in
            if case .success(let foundResults) = result {
                try? Self.updateKeychainIfNeeded([foundResults], saving: true)
            }
            completion(result)
        }
    }

    internal func saveCommand() -> API.Command<Self, Self> {
        return API.Command<Self, Self>.saveCommand(self)
    }
}

public extension ParseObject {
    func toPointer() -> Pointer<Self> {
        return Pointer(self)
    }
}
