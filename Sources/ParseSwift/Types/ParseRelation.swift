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
 
 In most cases, you do not need to create an instance of `ParseOperation` directly as it can be
 indirectly created from any `ParseObject` by using the respective `relation` property.
 */
public struct ParseRelation<T>: Codable, Hashable where T: ParseObject {
    internal let __type: String = "Relation" // swiftlint:disable:this identifier_name

    /// The parent `ParseObject`
    public var parent: T?

    /// The name of the class of the target child objects.
    public var className: String?

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

        return try parent.operation.addRelation(key, objects: objects)
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
        return try parent.operation.removeRelation(key, objects: objects)
    }

    /**
     Returns a `Query` that is limited to objects in this relation.
        - parameter child: The child class for the relation.
        - throws: An error of type `ParseError`.
        - returns: A relation query.
    */
    public func query<U>(_ child: U) throws -> Query<U> where U: ParseObject {

        guard let parent = self.parent else {
            throw ParseError(code: .unknownError,
                             message: "ParseRelation must have the parent set before querying.")
        }
        guard let key = self.key else {
            throw ParseError(code: .unknownError,
                             message: "ParseRelation must have the key set before querying.")
        }
        if !isSameClass([child]) {
            throw ParseError(code: .unknownError,
                             message: "ParseRelation must have the same child class as the original relation.")
        }
        return Query<U>(related(key: key, object: try parent.toPointer()))
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
     Create a new relation to a specific child.
     - parameter key: A key for the relation.
     - parameter child: The child `ParseObject`.
     - returns: A new `ParseRelation`.
     */
    func relation<U>(_ key: String, child: U? = nil) -> ParseRelation<Self> where U: ParseObject {
        ParseRelation(parent: self, key: key, child: child)
    }
}

// MARK: CustomDebugStringConvertible
extension ParseRelation: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
            return "ParseRelation ()"
        }
        return "ParseRelation (\(descriptionString))"
    }
}

// MARK: CustomStringConvertible
extension ParseRelation: CustomStringConvertible {
    public var description: String {
        debugDescription
    }
}
