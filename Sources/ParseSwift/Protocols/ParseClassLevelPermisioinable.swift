//
//  ParseClassLevelPermisioinable.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/27/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public protocol ParseClassLevelPermisioinable: Codable, Equatable {
    var protectedFields: [String: Set<String>]? { get set }
    var readUserFields: Set<String>? { get set }
    var writeUserFields: Set<String>? { get set }
}

// MARK: Protected
public extension ParseClassLevelPermisioinable {
    internal func getProtected(_ keyPath: KeyPath<Self, [String: Set<String>]?>,
                               for entity: String) -> Set<String> {
        self[keyPath: keyPath]?[entity] ?? []
    }

    internal func setProtected(_ keyPath: WritableKeyPath<Self, [String: Set<String>]?>,
                               fields: Set<String>,
                               for entity: String) -> Self {
        var mutableCLP = self
        if mutableCLP[keyPath: keyPath] != nil {
            mutableCLP[keyPath: keyPath]?[entity] = fields
        } else {
            mutableCLP[keyPath: keyPath] = [entity: fields]
        }
        return mutableCLP
    }

    internal func addProtected(_ keyPath: WritableKeyPath<Self, [String: Set<String>]?>,
                               fields: Set<String>,
                               for entity: String) -> Self {
        if let currentSet = self[keyPath: keyPath]?[entity] {
            var mutableCLP = self
            mutableCLP[keyPath: keyPath]?[entity] = currentSet.union(fields)
            return mutableCLP
        } else {
            return setProtected(keyPath, fields: fields, for: entity)
        }
    }

    internal func removeProtected(_ keyPath: WritableKeyPath<Self, [String: Set<String>]?>,
                                  fields: Set<String>,
                                  for entity: String) -> Self {
        var mutableCLP = self
        fields.forEach {
            mutableCLP[keyPath: keyPath]?[entity]?.remove($0)
        }
        return mutableCLP
    }

    /**
     Get the protected fields for the given `ParseUser` objectId.
     
     - parameter user: The `ParseUser` objectId access to check.
     - returns: The protected fields.
    */
    func getProtectedFields(_ objectId: String) -> Set<String> {
        getProtected(\.protectedFields, for: objectId)
    }

    /**
     Get the protected fields for the given `ParseUser`.
     
     - parameter user: The `ParseUser` access to check.
     - returns: The protected fields.
     - throws: An error of type `ParseError`.
    */
    func getProtectedFields<U>(_ user: U) throws -> Set<String> where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return getProtectedFields(objectId)
    }

    /**
     Get the protected fields for the given `ParseUser` pointer.
     
     - parameter user: The `ParseUser` access to check.
     - returns: The protected fields.
    */
    func getProtectedFields<U>(_ user: Pointer<U>) -> Set<String> where U: ParseUser {
        getProtectedFields(user.objectId)
    }

    /**
     Get the protected fields for the given `ParseRole`.
     
     - parameter role: The `ParseRole` access to check.
     - returns: The protected fields.
     - throws: An error of type `ParseError`.
    */
    func getProtectedFields<R>(_ role: R) throws -> Set<String> where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return getProtectedFields(roleNameAccess)
    }

    /**
     Set whether the given `ParseUser` objectId is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseUser` objectId to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setProtectedFields(_ fields: Set<String>, for objectId: String) -> Self {
        setProtected(\.protectedFields, fields: fields, for: objectId)
    }

    /**
     Set whether the given `ParseUser` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseUser` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setProtectedFields<U>(_ fields: Set<String>, for user: U) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return setProtectedFields(fields, for: objectId)
    }

    /**
     Set whether the given `ParseUser` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseUser` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setProtectedFields<U>(_ fields: Set<String>, for user: Pointer<U>) -> Self where U: ParseUser {
        setProtectedFields(fields, for: user.objectId)
    }

    /**
     Set whether the given `ParseRole` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseRole` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setProtectedFields<R>(_ fields: Set<String>, for role: R) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return setProtectedFields(fields, for: roleNameAccess)
    }

    /**
     Set whether the given `ParseUser` objectId is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseUser` objectId to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func addProtectedFields(_ fields: Set<String>, for objectId: String) -> Self {
        addProtected(\.protectedFields, fields: fields, for: objectId)
    }

    /**
     Set whether the given `ParseUser` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseUser` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func addProtectedFields<U>(_ fields: Set<String>, for user: U) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return addProtectedFields(fields, for: objectId)
    }

    /**
     Set whether the given `ParseUser` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseUser` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func addProtectedFields<U>(_ fields: Set<String>, for user: Pointer<U>) -> Self where U: ParseUser {
        addProtectedFields(fields, for: user.objectId)
    }

    /**
     Set whether the given `ParseRole` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseRole` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func addProtectedFields<R>(_ fields: Set<String>, for role: R) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return addProtectedFields(fields, for: roleNameAccess)
    }

    /**
     Remove  the given `ParseUser` objectId is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseUser` objectId to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func removeProtectedFields(_ fields: Set<String>, for objectId: String) -> Self {
        removeProtected(\.protectedFields, fields: fields, for: objectId)
    }

    /**
     Set whether the given `ParseUser` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseUser` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func removeProtectedFields<U>(_ fields: Set<String>, for user: U) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return removeProtectedFields(fields, for: objectId)
    }

    /**
     Set whether the given `ParseUser` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseUser` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func removeProtectedFields<U>(_ fields: Set<String>, for user: Pointer<U>) -> Self where U: ParseUser {
        removeProtectedFields(fields, for: user.objectId)
    }

    /**
     Set whether the given `ParseRole` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseRole` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func removeProtectedFields<R>(_ fields: Set<String>, for role: R) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return removeProtectedFields(fields, for: roleNameAccess)
    }
}

// MARK: UserFields
extension ParseClassLevelPermisioinable {
    func getUser(_ keyPath: KeyPath<Self, Set<String>?>) -> Set<String> {
        self[keyPath: keyPath] ?? []
    }

    func setUser(_ keyPath: WritableKeyPath<Self, Set<String>?>,
                 fields: Set<String>) -> Self {
        var mutableCLP = self
        mutableCLP[keyPath: keyPath] = fields
        return mutableCLP
    }

    func addUser(_ keyPath: WritableKeyPath<Self, Set<String>?>,
                 fields: Set<String>) -> Self {
        if let currentSet = self[keyPath: keyPath] {
            var mutableCLP = self
            mutableCLP[keyPath: keyPath] = currentSet.union(currentSet)
            return mutableCLP
        } else {
            return setUser(keyPath, fields: fields)
        }
    }

    func removeUser(_ keyPath: WritableKeyPath<Self, Set<String>?>,
                    fields: Set<String>) -> Self {
        var mutableCLP = self
        fields.forEach {
            mutableCLP[keyPath: keyPath]?.remove($0)
        }
        return mutableCLP
    }
}

// MARK: WriteUserFields
public extension ParseClassLevelPermisioinable {

    /**
     Get the `writeUserFields`.

     - returns: User pointer fields.
    */
    func getWriteUserFields() -> Set<String> {
        getUser(\.writeUserFields)
    }

    /**
     Sets permission for the user pointer fields or create/delete/update/addField operations.

     - parameter fields: User pointer fields.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteUser(_ fields: Set<String>) -> Self {
        setUser(\.writeUserFields, fields: fields)
    }

    /**
     Adds permission for the user pointer fields or create/delete/update/addField operations.

     - parameter fields: User pointer fields.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func addWriteUser(_ fields: Set<String>) -> Self {
        addUser(\.writeUserFields, fields: fields)
    }

    /**
     Adds permission for the user pointer fields or create/delete/update/addField operations.

     - parameter fields: User pointer fields.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func removeWriteUser(_ fields: Set<String>) -> Self {
        removeUser(\.writeUserFields, fields: fields)
    }
}

// MARK: ReadUserFields
public extension ParseClassLevelPermisioinable {

    /**
     Get the `readUserFields`.

     - returns: User pointer fields.
    */
    func getReadUserFields() -> Set<String> {
        getUser(\.readUserFields)
    }

    /**
     Sets permission for the user pointer fields or get/count/find operations.

     - parameter fields: User pointer fields.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadUser(_ fields: Set<String>) -> Self {
        setUser(\.readUserFields, fields: fields)
    }

    /**
     Adds permission for the user pointer fields or get/count/find operations.

     - parameter fields: User pointer fields.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func addReadUser(_ fields: Set<String>) -> Self {
        addUser(\.readUserFields, fields: fields)
    }

    /**
     Removes permission for the user pointer fields or get/count/find operations.

     - parameter fields: User pointer fields.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func removeReadUser(_ fields: Set<String>) -> Self {
        removeUser(\.readUserFields, fields: fields)
    }
}
