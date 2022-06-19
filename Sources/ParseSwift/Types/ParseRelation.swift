//
//  ParseRelation.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/18/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
 The `ParseRelation` object that is used to access all of the children of a many-to-many relationship.
 Each instance of `ParseRelation` is associated with a particular parent object and key.
 
 In most cases, you do not need to create an instance of `ParseRelation` directly as it can be
 indirectly created from any `ParseObject` by using the respective `relation` property.
 */
public struct ParseRelation<T>: ParseTypeable, Hashable where T: ParseObject {
    internal let __type: String = "Relation" // swiftlint:disable:this identifier_name

    /// The parent `ParseObject`
    public var parent: Pointer<T>?

    /// The name of the class of the target child objects.
    public var className: String?

    var key: String?

    /**
     Create a `ParseRelation` with a specific parent and key.
     - parameters:
        - parent: The parent `ParseObject` Pointer.
        - key: The key for the relation.
     */
    public init(parent: Pointer<T>, key: String? = nil) {
        self.parent = parent
        self.key = key
    }

    /**
     Create a `ParseRelation` with a specific parent, key, and className.
     - parameters:
        - parent: The parent `ParseObject` Pointer.
        - key: The key for the relation.
        - className: The name of the child class for the relation.
     */
    public init(parent: Pointer<T>, key: String? = nil, className: String) {
        self.init(parent: parent, key: key)
        self.className = className
    }

    /**
     Create a `ParseRelation` with a specific parent, key, and child object.
     - parameters:
        - parent: The parent `ParseObject` Pointer.
        - key: The key for the relation.
        - child: The child `ParseObject`.
     */
    public init<U>(parent: Pointer<T>, key: String? = nil, child: U) where U: ParseObject {
        self.init(parent: parent, key: key)
        self.className = child.className
    }

    /**
     Create a `ParseRelation` with a specific parent, key, and child object.
     - parameters:
        - parent: The parent `ParseObject` Pointer.
        - key: The key for the relation.
        - child: The child `ParseObject` Pointer.
     */
    public init<U>(parent: Pointer<T>, key: String? = nil, child: Pointer<U>) where U: ParseObject {
        self.init(parent: parent, key: key)
        self.className = child.className
    }

    /**
     Create a `ParseRelation` with a specific parent and key.
     - parameters:
        - parent: The parent `ParseObject`.
        - key: The key for the relation.
     */
    public init(parent: T, key: String? = nil) throws {
        self.init(parent: try parent.toPointer(), key: key)
    }

    /**
     Create a `ParseRelation` with a specific parent, key, and className.
     - parameters:
        - parent: The parent `ParseObject`.
        - key: The key for the relation.
        - className: The name of the child class for the relation.
     */
    public init(parent: T, key: String? = nil, className: String) throws {
        self.init(parent: try parent.toPointer(), key: key, className: className)
    }

    /**
     Create a `ParseRelation` with a specific parent, key, and child object.
     - parameters:
        - parent: The parent `ParseObject`.
        - key: The key for the relation.
        - child: The child `ParseObject`.
     */
    public init<U>(parent: T, key: String? = nil, child: U) throws where U: ParseObject {
        self.init(parent: try parent.toPointer(), key: key, child: child)
    }

    /**
     Create a `ParseRelation` with a specific parent, key, and child object.
     - parameters:
        - parent: The parent `ParseObject`.
        - key: The key for the relation.
        - child: The child `ParseObject` Pointer.
     */
    public init<U>(parent: T, key: String? = nil, child: Pointer<U>) throws where U: ParseObject {
        self.init(parent: try parent.toPointer(), key: key, child: child)
    }

    enum CodingKeys: String, CodingKey {
        case className
        case __type // swiftlint:disable:this identifier_name
    }

    // MARK: Helpers
    func isSameClass(_ objectClassNames: [String]) -> Bool {
        guard let first = objectClassNames.first else {
            return false
        }
        if className != nil {
            if className != first {
                return false
            }
        }
        let sameClassObjects = objectClassNames.filter({ $0 == first })
        return sameClassObjects.count == objectClassNames.count
    }

    func isSameClass<U>(_ objects: [U]) -> Bool where U: ParseObject {
        isSameClass(objects.map { $0.className })
    }

    // MARK: Intents
    /**
     Adds a relation to the respective objects.
     - parameters:
        - key: The key for the relation.
        - objects: An array of `ParseObject`'s to add relation to.
     - throws: An error of type `ParseError`.
     */
    public func add<U>(_ key: String, objects: [U]) throws -> ParseOperation<T> where U: ParseObject {
        guard let parent = parent else {
            throw ParseError(code: .unknownError,
                             message: "ParseRelation must have the parent set.")
        }
        if let currentKey = self.key {
            if currentKey != key {
                throw ParseError(code: .unknownError, message: "All objects have be related to the same key.")
            }
        }
        if !isSameClass(objects) {
            throw ParseError(code: .unknownError, message: "All objects have to have the same className.")
        }

        return try parent.toObject().operation.addRelation(key, objects: objects)
    }

    /**
     Adds a relation to the respective `ParseObject`'s with using the `key` for this `ParseRelation`.
     - parameters:
        - objects: An array of `ParseObject`'s to add relation to.
     - throws: An error of type `ParseError`.
     */
    public func add<U>(_ objects: [U]) throws -> ParseOperation<T> where U: ParseObject {
        guard let key = self.key else {
            throw ParseError(code: .unknownError,
                             message: "ParseRelation must have the key set.")
        }
        return try add(key, objects: objects)
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
            throw ParseError(code: .unknownError,
                             message: "ParseRelation must have the parent set.")
        }
        if let currentKey = self.key {
            if currentKey != key {
                throw ParseError(code: .unknownError, message: "All objects have be related to the same key.")
            }
        }
        if !isSameClass(objects) {
            throw ParseError(code: .unknownError, message: "All objects have to have the same className.")
        }
        return try parent.toObject().operation.removeRelation(key, objects: objects)
    }

    /**
     Removes a relation to the respective objects using the `key` for this `ParseRelation`.
     - parameters:
        - objects: An array of `ParseObject`'s to add relation to.
     - throws: An error of type `ParseError`.
     */
    public func remove<U>(_ objects: [U]) throws -> ParseOperation<T> where U: ParseObject {
        guard let key = self.key else {
            throw ParseError(code: .unknownError,
                             message: "ParseRelation must have the key set.")
        }
        return try remove(key, objects: objects)
    }

    /**
     Returns a `Query` that is limited to objects for a specific `key` and `parent` in this relation.
     - parameter key: The key for the relation.
     - parameter parent: The parent pointer object for the relation.
     - returns: A relation query.
    */
    public static func query<U>(_ key: String, parent: Pointer<U>) -> Query<T> where U: ParseObject {
        Query<T>(related(key: key, object: parent))
    }

    /**
     Returns a `Query` that is limited to objects for a specific `key` and `parent` in this relation.
     - parameter key: The key for the relation.
     - parameter parent: The parent object for the relation.
     - throws: An error of type `ParseError`.
     - returns: A relation query.
    */
    public static func query<U>(_ key: String, parent: U) throws -> Query<T> where U: ParseObject {
        Self.query(key, parent: try parent.toPointer())
    }

    /**
     Returns a `Query` that is limited to objects for a specific `key` and `parent` in this relation.
     - parameter key: The key for the relation.
     - parameter parent: The parent object for the relation.
     - throws: An error of type `ParseError`.
     - returns: A relation query.
    */
    public func query<U>(_ key: String, parent: U) throws -> Query<T> where U: ParseObject {
        try Self.query(key, parent: parent)
    }

    /**
     Returns a `Query` that is limited to objects for a specific `key` and `parent` in this relation.
     - parameter key: The key for the relation.
     - parameter parent: The parent pointer object for the relation.
     - returns: A relation query.
    */
    public func query<U>(_ key: String, parent: Pointer<U>) -> Query<T> where U: ParseObject {
        Self.query(key, parent: parent)
    }

    /**
     Returns a `Query` that is limited to the key and objects in this relation.
        - throws: An error of type `ParseError`.
        - returns: A relation query.
    */
    public func query<U>() throws -> Query<U> where U: ParseObject {
        guard let parent = parent else {
            throw ParseError(code: .unknownError,
                             message: "ParseRelation must have the parent set.")
        }
        guard let key = self.key else {
            throw ParseError(code: .unknownError,
                             message: "ParseRelation must have the key set.")
        }
        if !isSameClass([U.className]) {
            throw ParseError(code: .unknownError,
                             message: "ParseRelation must have the same child className as the original relation.")
        }
        return Query<U>(related(key: key, object: parent))
    }

    /**
     Returns a `Query` that is limited to objects for a specific `key` and `child` in this relation.
     - parameter key: The key for the relation.
     - throws: An error of type `ParseError`.
     - returns: A relation query.
    */
    public func query<U>(_ key: String) throws -> Query<U> where U: ParseObject {
        guard let parent = parent else {
            throw ParseError(code: .unknownError,
                             message: "ParseRelation must have the parent set.")
        }
        return try Self(parent: parent, key: key).query()
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

    /// Create a new relation with this `ParseObject` as the parent.
    var relation: ParseRelation<Self>? {
        try? ParseRelation(parent: self)
    }

    /**
     Establish a relation based on a stored relation.
     - parameter relation: The stored relation property.
     - parameter key: The key for the relation.
     - parameter with: The parent `ParseObject` Pointer of the `ParseRelation`.
     - returns: A usable `ParseRelation` based on the stored relation property.
     */
    static func relation<T: ParseObject>(_ relation: ParseRelation<T>?,
                                         key: String,
                                         with parent: Pointer<T>) throws -> ParseRelation<T> {
        guard var relation = relation,
              relation.className != nil else {
            throw ParseError(code: .unknownError,
                             message: "ParseRelation is either nil or missing \"className\"")
        }
        relation.parent = parent
        relation.key = key
        return relation
    }

    /**
     Establish a relation based on a stored relation.
     - parameter relation: The stored relation property.
     - parameter key: The key for the relation.
     - parameter with: The parent `ParseObject` of the `ParseRelation`.
     - returns: A usable `ParseRelation` based on the stored relation property.
     */
    static func relation<T: ParseObject>(_ relation: ParseRelation<T>?,
                                         key: String,
                                         with parent: T) throws -> ParseRelation<T> {
        try Self.relation(relation, key: key, with: try parent.toPointer())
    }

    /**
     Returns a `Query` for child objects that is limited to objects for a specific `key` and `parent` in this relation.
     - parameter key: The key for the relation.
     - parameter parent: The parent object for the relation.
     - throws: An error of type `ParseError`.
     - returns: A relation query for child objects related to a `parent` object with a specific `key`.
    */
    static func queryRelations<U: ParseObject>(_ key: String, parent: U) throws -> Query<Self> {
        try ParseRelation<Self>.query(key, parent: parent)
    }

    /**
     Returns a `Query` for child objects that is limited to objects for a specific `key` and `parent` in this relation.
     - parameter key: The key for the relation.
     - parameter parent: The parent pointer object for the relation.
     - throws: An error of type `ParseError`.
     - returns: A relation query for child objects related to a `parent` object with a specific `key`.
    */
    static func queryRelations<U: ParseObject>(_ key: String, parent: Pointer<U>) -> Query<Self> {
        ParseRelation<Self>.query(key, parent: parent)
    }

    /**
     Create a new relation with a specific key.
     - parameter key: The key for the relation.
     - parameter className: The name of the child class for the relation.
     - returns: A new `ParseRelation`.
     */
    func relation(_ key: String, className: String) throws -> ParseRelation<Self> {
        try ParseRelation(parent: self, key: key, className: className)
    }

    /**
     Create a new relation to a specific child.
     - parameter key: The key for the relation.
     - parameter child: The child `ParseObject`.
     - returns: A new `ParseRelation`.
     */
    func relation<U>(_ key: String, child: U) throws -> ParseRelation<Self> where U: ParseObject {
        try ParseRelation(parent: self, key: key, child: child)
    }

    /**
     Establish a relation based on a stored relation with this `ParseObject` as the parent.
     - parameter relation: The stored relation property.
     - parameter key: The key for the relation.
     - returns: A usable `ParseRelation` based on the stored relation property.
     */
    func relation(_ relation: ParseRelation<Self>?,
                  key: String) throws -> ParseRelation<Self> {
        try Self.relation(relation, key: key, with: self)
    }

    /**
     Establish a relation based on a stored relation.
     - parameter relation: The stored relation property.
     - parameter key: The key for the relation.
     - parameter with: The parent `ParseObject` Pointer of the `ParseRelation`.
     - returns: A usable `ParseRelation` based on the stored relation property.
     */
    func relation<T: ParseObject>(_ relation: ParseRelation<T>?,
                                  key: String,
                                  with parent: Pointer<T>) throws -> ParseRelation<T> {
        try Self.relation(relation, key: key, with: parent)
    }

    /**
     Establish a relation based on a stored relation.
     - parameter relation: The stored relation property.
     - parameter key: The key for the relation.
     - parameter with: The parent `ParseObject` of the `ParseRelation`.
     - returns: A usable `ParseRelation` based on the stored relation property.
     */
    func relation<T: ParseObject>(_ relation: ParseRelation<T>?,
                                  key: String,
                                  with parent: T) throws -> ParseRelation<T> {
        try self.relation(relation, key: key, with: try parent.toPointer())
    }
}
