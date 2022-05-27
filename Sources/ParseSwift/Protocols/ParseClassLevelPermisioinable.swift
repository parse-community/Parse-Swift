//
//  ParseClassLevelPermisioinable.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/27/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public protocol ParseClassLevelPermisioinable: Codable, Equatable {
    var protectedFields: [String: [String]]? { get set }
    var readUserFields: [String]? { get set }
    var writeUserFields: [String]? { get set }

    /**
     Get the protected fields for the given `ParseUser` objectId.
     
     - parameter user: The `ParseUser` objectId access to check.
     - returns: The protected fields.
    */
    func getProtectedFields(_ objectId: String) -> [String]

    /**
     Get the protected fields for the given `ParseUser`.
     
     - parameter user: The `ParseUser` access to check.
     - returns: The protected fields.
     - throws: An error of type `ParseError`.
    */
    func getProtectedFields<U>(_ user: U) throws -> [String] where U: ParseUser

    /**
     Get the protected fields for the given `ParseUser` pointer.
     
     - parameter user: The `ParseUser` access to check.
     - returns: The protected fields.
    */
    func getProtectedFields<U>(_ user: Pointer<U>) -> [String] where U: ParseUser

    /**
     Get the protected fields for the given `ParseRole`.
     
     - parameter role: The `ParseRole` access to check.
     - returns: The protected fields.
     - throws: An error of type `ParseError`.
    */
    func getProtectedFields<R>(_ role: R) throws -> [String] where R: ParseRole

    /**
     Set whether the given `ParseUser` objectId is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseUser` objectId to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setProtectedFields(_ fields: [String], for objectId: String) -> Self

    /**
     Set whether the given `ParseUser` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseUser` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setProtectedFields<U>(_ fields: [String], for user: U) throws -> Self where U: ParseUser

    /**
     Set whether the given `ParseUser` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseUser` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setProtectedFields<U>(_ fields: [String], for user: Pointer<U>) -> Self where U: ParseUser

    /**
     Set whether the given `ParseRole` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseRole` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setProtectedFields<R>(_ fields: [String], for role: R) throws -> Self where R: ParseRole
}

// MARK: Protected
public extension ParseClassLevelPermisioinable {
    internal func getProtected(_ keyPath: KeyPath<Self, [String: [String]]?>,
                               for entity: String) -> [String] {
        self[keyPath: keyPath]?[entity] ?? []
    }

    internal func setProtected(_ keyPath: WritableKeyPath<Self, [String: [String]]?>,
                               fields: [String],
                               for entity: String) -> Self {
        var mutableCLP = self
        if mutableCLP[keyPath: keyPath] != nil {
            mutableCLP[keyPath: keyPath]?[entity] = fields
        } else {
            mutableCLP[keyPath: keyPath] = [entity: fields]
        }
        return mutableCLP
    }

    func getProtectedFields(_ objectId: String) -> [String] {
        getProtected(\.protectedFields, for: objectId)
    }

    func getProtectedFields<U>(_ user: U) throws -> [String] where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return getProtectedFields(objectId)
    }

    func getProtectedFields<U>(_ user: Pointer<U>) -> [String] where U: ParseUser {
        getProtectedFields(user.objectId)
    }

    func getProtectedFields<R>(_ role: R) throws -> [String] where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return getProtectedFields(roleNameAccess)
    }

    func setProtectedFields(_ fields: [String], for objectId: String) -> Self {
        setProtected(\.protectedFields, fields: fields, for: objectId)
    }

    func setProtectedFields<U>(_ fields: [String], for user: U) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return setProtectedFields(fields, for: objectId)
    }

    func setProtectedFields<U>(_ fields: [String], for user: Pointer<U>) -> Self where U: ParseUser {
        setProtectedFields(fields, for: user.objectId)
    }

    func setProtectedFields<R>(_ fields: [String], for role: R) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return setProtectedFields(fields, for: roleNameAccess)
    }
}

// MARK: UserFields
extension ParseClassLevelPermisioinable {
    func getUser(_ keyPath: KeyPath<Self, [String]?>) -> [String] {
        self[keyPath: keyPath] ?? []
    }

    func setUser(_ keyPath: WritableKeyPath<Self, [String]?>,
                 fields: [String]) -> Self {
        var mutableCLP = self
        mutableCLP[keyPath: keyPath] = fields
        return mutableCLP
    }
}

// MARK: WriteUserFields
public extension ParseClassLevelPermisioinable {

    /**
     Get the `writeUserFields`.

     - returns: User pointer fields.
    */
    func getWriteUserFields() -> [String] {
        getUser(\.writeUserFields)
    }

    /**
     Sets permission for the user pointer fields or create/delete/update/addField operations.

     - parameter fields: User pointer fields.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteUser(_ fields: [String]) -> Self {
        setUser(\.writeUserFields, fields: fields)
    }
}

// MARK: ReadUserFields
public extension ParseClassLevelPermisioinable {

    /**
     Get the `readUserFields`.

     - returns: User pointer fields.
    */
    func getReadUserFields() -> [String] {
        getUser(\.readUserFields)
    }

    /**
     Sets permission for the user pointer fields or get/count/find operations.

     - parameter fields: User pointer fields.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadUser(_ fields: [String]) -> Self {
        setUser(\.readUserFields, fields: fields)
    }
}
