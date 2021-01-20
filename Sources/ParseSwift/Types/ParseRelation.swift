//
//  ParseRelation.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/18/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
 The `ParseRelation` class that is used to access all of the children of a many-to-many relationship.
 Each instance of `ParseRelation` is associated with a particular parent object and key.
 */
public struct ParseRelation<T>: Codable where T: ParseObject {
    internal let __type: String = "Relation" // swiftlint:disable:this identifier_name

    /// The parent `ParseObject`
    public var parent: T?

    /// The name of the class of the target child objects.
    public var className: String?

    /// Returns true if the `ParseRelation` has pending operations.
    public var hasNewOperations: Bool {
        guard let operation = self.parent?.operation else {
            return false
        }
        return !operation.operations.isEmpty
    }

    var key: String?

    /**
     Create a `ParseRelation` with a specific parent and key.
     - parameters:
        - parent: The parent `ParseObject`.
        - key: The key for the relation.
        - className: The name of the child class for the relation.
     */
    public init(parent: T, key: String? = nil, className: String? = nil) {
        self.parent = parent
        self.key = key
        self.className = className
    }

    /**
     Create a `ParseRelation` with a specific parent and child.
     - parameters:
        - parent: The parent `ParseObject`.
        - key: The key for the relation.
        - child: The child `ParseObject`.
     */
    public init<U>(parent: T, key: String? = nil, child: U? = nil) where U: ParseObject {
        self.parent = parent
        self.key = key
        self.className = child?.className
    }

    enum CodingKeys: String, CodingKey {
        case className
        case __type // swiftlint:disable:this identifier_name
    }

    /**
     Adds a relation to the respective objects.
     - parameters:
        - key: The key for the relation.
        - objects: An array of `ParseObject`'s to add relation to.
     - throws: An error of type `ParseError`.
     */
    public func add<U>(_ key: String, objects: [U]) throws -> ParseOperation<T> where U: ParseObject {
        guard let parent = parent else {
            throw ParseError(code: .unknownError, message: "ParseRelation must have the parent set before removing.")
        }
        if let currentKey = self.key {
            if currentKey != key {
                throw ParseError(code: .unknownError, message: "All objects have be related to the same key.")
            }
        }
        if !isSameClass(objects) {
            throw ParseError(code: .unknownError, message: "All objects have to have the same className.")
        }

        return parent.operation.addRelation(key, objects: objects)
    }

    /**
     Removes a relation to the respective objects.
     - parameters:
        - key: The key for the relation.
        - objects: An array of `ParseObject`'s to remove relation to.
     - throws: An error of type `ParseError`.
     */
    public func remove<U>(_ key: String, objects: [U]) throws -> ParseOperation<T> where U: ParseObject {
        guard let parent = parent else {
            throw ParseError(code: .unknownError, message: "ParseRelation must have the parent set before removing.")
        }
        if let currentKey = self.key {
            if currentKey != key {
                throw ParseError(code: .unknownError, message: "All objects have be related to the same key.")
            }
        }
        if !isSameClass(objects) {
            throw ParseError(code: .unknownError, message: "All objects have to have the same className.")
        }
        return parent.operation.removeRelation(key, objects: objects)
    }

    /**
     Returns a `Query` that is limited to objects in this relation.
        - parameter target: The target class for the relation.
        - throws: An error of type `ParseError`.
        - returns: A relation query
    */
    public func query<U>(_ target: U) throws -> Query<U> where U: ParseObject {

        guard let parent = self.parent else {
            throw ParseError(code: .unknownError,
                             message: "ParseRelation must have the parent set before querying.")
        }
        guard let key = self.key else {
            throw ParseError(code: .unknownError,
                             message: "ParseRelation must have the key set before querying.")
        }
        if !isSameClass([target]) {
            throw ParseError(code: .unknownError,
                             message: "ParseRelation must have the same target class as the original relation.")
        }
        return Query<U>(related(key: "object", object: parent),
                        related(key: "key", object: key))
    }

    func isSameClass<U>(_ objects: [U]) -> Bool where U: ParseObject {
        guard let first = objects.first?.className else {
            return true
        }
        if className != nil {
            if className != first {
                return false
            }
        } else {
            return false
        }
        let sameClassObjects = objects.filter({ $0.className == first })
        return sameClassObjects.count == objects.count
    }
}

// MARK: Convenience
public extension ParseRelation {

    /**
     Adds a relation to the respective `ParseUser`'s with `key = "users"`.
     - parameters:
        - users: An array of `ParseUser`'s to add relation to.
     - throws: An error of type `ParseError`.
     */
    func add<U>(_ users: [U]) throws -> ParseOperation<T> where U: ParseUser {
        guard let key = self.key else {
            return try add("users", objects: users)
        }
        return try add(key, objects: users)
    }

    /**
     Adds a relation to the respective `ParseRole`'s with `key = "roles"`.
     - parameters:
        - roles: An array of `ParseRole`'s to add relation to.
     - throws: An error of type `ParseError`.
     */
    func add<U>(_ roles: [U]) throws -> ParseOperation<T> where U: ParseRole {
        guard let key = self.key else {
            return try add("roles", objects: roles)
        }
        return try add(key, objects: roles)
    }

    /**
     Removes a relation to the respective `ParseUser`'s with `key = "users"`.
     - parameters:
        - users: An array of `ParseUser`'s to add relation to.
     - throws: An error of type `ParseError`.
     */
    func remove<U>(_ users: [U]) throws -> ParseOperation<T> where U: ParseUser {
        guard let key = self.key else {
            return try remove("users", objects: users)
        }
        return try remove(key, objects: users)
    }

    /**
     Removes a relation to the respective `ParseRole`'s with `key = "roles"`.
     - parameters:
        - roles: An array of `ParseRole`'s to add relation to.
     - throws: An error of type `ParseError`.
     */
    func remove<U>(_ roles: [U]) throws -> ParseOperation<T> where U: ParseRole {
        guard let key = self.key else {
            return try remove("roles", objects: roles)
        }
        return try remove(key, objects: roles)
    }
}

extension ParseRelation {
    /**
     Saves the relations on the `ParseObject` *synchronously* and throws an error if there's an issue.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.

     - returns: Returns saved `ParseObject`.
    */
    public func save(options: API.Options = []) throws -> T {
        guard let parent = self.parent else {
            throw ParseError(code: .missingObjectId, message: "ParseObject isn't saved.")
        }
        if !parent.isSaved {
            throw ParseError(code: .missingObjectId, message: "ParseObject isn't saved.")
        }
        return try parent.operation.save()
    }

    /**
     Saves the relations on the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<T, ParseError>)`.
    */
    public func save(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<T, ParseError>) -> Void
    ) {
        guard let parent = self.parent else {
            let error = ParseError(code: .missingObjectId, message: "ParseObject isn't saved.")
            completion(.failure(error))
            return
        }
        if !parent.isSaved {
            callbackQueue.async {
                let error = ParseError(code: .missingObjectId, message: "ParseObject isn't saved.")
                completion(.failure(error))
            }
            return
        }

        parent.operation.save(options: options, callbackQueue: callbackQueue, completion: completion)
    }
}

// MARK: ParseRelation
public extension ParseObject {

    /// Create a new relation.
    var relation: ParseRelation<Self> {
        return ParseRelation(parent: self)
    }

    /**
     Create a new relation with a specific key.
     - parameter key: A key for the relation.
     - parameter className: The name of the child class for the relation.
     - returns: A new `ParseRelation`.
     */
    func relation(_ key: String, className: String? = nil) -> ParseRelation<Self> {
        ParseRelation(parent: self, key: key, className: className)
    }

    /**
     Create a new relation with a specific key.
     - parameter key: A key for the relation.
     - parameter child: The child `ParseObject`.
     - returns: A new `ParseRelation`.
     */
    func relation<U>(_ key: String, child: U? = nil) -> ParseRelation<Self> where U: ParseObject {
        ParseRelation(parent: self, key: key, child: child)
    }
}
