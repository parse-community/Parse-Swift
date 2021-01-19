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
    public var parent: T? {
        willSet {
            operation = newValue?.operation
        }
    }

    /// The name of the class of the target child objects.
    public var className: String?

    /// Returns true if the `ParseRelation` has pending operations.
    public var hasNewOperations: Bool {
        guard let operation = self.operation else {
            return false
        }
        return !operation.operations.isEmpty
    }

    var operation: ParseOperation<T>?
    var key: String?

    /**
     Create a `ParseRelation` with a specific parent and key.
     - parameters:
        - parent: The parent `ParseObject`.
        - key: The key for the relation.
        - targetClassName: The name of the child class for the relation.
     */
    init(parent: T, key: String? = nil, targetClassName: String? = nil) {
        self.parent = parent
        self.operation = parent.operation
        self.key = key
        self.className = targetClassName
    }

    enum CodingKeys: String, CodingKey {
        case className
        case parent
        case key
        case __type // swiftlint:disable:this identifier_name
    }

    /**
     Adds a relation to the passed in object.
     - parameters:
        - key: The key for the relation.
        - throws: An error of type `ParseError`.
        - objects: An array of `ParseObject`'s to add relation to.
     */
    public func add<U>(_ key: String, objects: [U]) throws -> Self where U: ParseObject {
        if parent == nil {
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
        _ = self.operation?.addRelation(key, objects: objects)
        return self
    }

    /**
     Removes a relation to the passed in object.
     - parameters:
        - key: The key for the relation.
        - objects: An array of `ParseObject`'s to remove relation to.
     - throws: An error of type `ParseError`.
     */
    public func remove<U>(_ key: String, objects: [U]) throws -> Self where U: ParseObject {
        if parent == nil {
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
        _ = self.operation?.removeRelation(key, objects: objects)
        return self
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
extension ParseRelation {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key = try values.decodeIfPresent(String.self, forKey: .key)
        parent = try values.decodeIfPresent(T.self, forKey: .parent)
        operation = parent?.operation
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
     - returns: A new `ParseRelation`.
     */
    func relation(_ key: String) -> ParseRelation<Self> {
        ParseRelation(parent: self, key: key)
    }
}
