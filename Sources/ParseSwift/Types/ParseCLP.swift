//
//  ParseCLP.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public struct ParseCLP: Codable, Equatable {

    public internal(set) var get: [String: Bool]?
    public internal(set) var find: [String: Bool]?
    public internal(set) var count: [String: Bool]?
    public internal(set) var create: [String: Bool]?
    public internal(set) var update: [String: Bool]?
    public internal(set) var delete: [String: Bool]?
    public internal(set) var addField: [String: Bool]?
    public internal(set) var protectedFields: [String: [String]]?
    public internal(set) var readUserFields: [String]?
    public internal(set) var writeUserFields: [String]?

    enum Access: String, Codable {
        case requiresAuthentication
        case publicScope = "*"
    }

    /// An empty CLP.
    public init() { }

    func getAccess(_ key: KeyPath<Self, [String: Bool]?>,
                   for entity: String) -> Bool {
        self[keyPath: key]?[entity] ?? false
    }

    func setAccess(_ key: WritableKeyPath<Self, [String: Bool]?>,
                   for entity: String,
                   to allow: Bool) -> Self {
        var mutableCLP = self
        mutableCLP[keyPath: key]?[entity] = allow
        return mutableCLP
    }

    func getUser(_ key: KeyPath<Self, [String]?>) -> [String] {
        self[keyPath: key] ?? []
    }

    func setUser(_ key: WritableKeyPath<Self, [String]?>,
                 fields: [String]) -> Self {
        var mutableCLP = self
        mutableCLP[keyPath: key] = fields
        return mutableCLP
    }

    func getProtected(_ key: KeyPath<Self, [String: [String]]?>,
                      for entity: String) -> [String] {
        self[keyPath: key]?[entity] ?? []
    }

    func setProtected(_ key: WritableKeyPath<Self, [String: [String]]?>,
                      fields: [String],
                      for entity: String) -> Self {
        var mutableCLP = self
        mutableCLP[keyPath: key]?[entity] = fields
        return mutableCLP
    }
}

// MARK: Default Implementation
public extension ParseCLP {

    init(requireAuthentication: Bool, publicAccess: Bool) {
        let clp = setRequiresAuthenticationWriteAccess(requireAuthentication)
            .setRequiresAuthenticationReadAccess(requireAuthentication)
            .setPublicWriteAccess(publicAccess)
            .setPublicReadAccess(publicAccess)
        self = clp
    }

    init(objectId: String, canAddFied: Bool = false) {
        let clp = setWriteAccess(objectId,
                                 to: true,
                                 canAddField: canAddFied)
            .setReadAccess(objectId, to: true)
        self = clp
    }

    init<U>(user: U, canAddFied: Bool = false) throws where U: ParseUser {
        let objectId = try user.toPointer().objectId
        self.init(objectId: objectId, canAddFied: canAddFied)
    }

    init<U>(user: Pointer<U>, canAddFied: Bool = false) where U: ParseUser {
        self.init(objectId: user.objectId, canAddFied: canAddFied)
    }

    init<R>(role: R, canAddFied: Bool = false) throws where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        self.init(objectId: roleNameAccess, canAddFied: canAddFied)
    }
}

// MARK: Protected
public extension ParseCLP {

    /**
     Get the protected fields for the given user objectId.
     
     - parameter objectId: The user objectId access to check.
     - returns: The protected fields.
    */
    func getProtected(_ objectId: String) -> [String] {
        getProtected(\.protectedFields, for: objectId)
    }

    /**
     Get the protected fields for the given `ParseUser`.
     
     - parameter user: The `ParseUser` access to check.
     - returns: The protected fields.
     - throws: An error of type `ParseError`.
    */
    func getProtected<U>(_ user: U) throws -> [String] where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return getProtected(objectId)
    }

    /**
     Get the protected fields for the given `ParseUser` pointer.
     
     - parameter user: The `ParseUser` access to check.
     - returns: The protected fields.
    */
    func getProtected<U>(_ user: Pointer<U>) -> [String] where U: ParseUser {
        getProtected(user.objectId)
    }

    /**
     Get the protected fields for the given `ParseRole`.
     
     - parameter role: The `ParseRole` access to check.
     - returns: The protected fields.
     - throws: An error of type `ParseError`.
    */
    func getProtected<R>(_ role: R) throws -> [String] where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return getProtected(roleNameAccess)
    }

    /**
     Set whether the given user objectId is allowed to retrieve fields from this class.
     
     - parameter for: The user objectId to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setProtected(_ fields: [String], for objectId: String) -> Self {
        setProtected(\.protectedFields, fields: fields, for: objectId)
    }

    /**
     Set whether the given `ParseUser` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseUser` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setProtected<U>(_ fields: [String], for user: U) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return setProtected(fields, for: objectId)
    }

    /**
     Set whether the given `ParseUser` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseUser` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setProtected<U>(_ fields: [String], for user: Pointer<U>) -> Self where U: ParseUser {
        setProtected(fields, for: user.objectId)
    }

    /**
     Set whether the given `ParseRole` is allowed to retrieve fields from this class.
     
     - parameter for: The `ParseRole` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setProtected<R>(_ fields: [String], for role: R) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return setProtected(fields, for: roleNameAccess)
    }
}

// MARK: WriteUserFields
public extension ParseCLP {

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
public extension ParseCLP {

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

// MARK: RequiresAuthenication
public extension ParseCLP {

    /**
     Check whether **get** requires authentication for this class.

     - returns: **true** if access is allowed, **false** otherwise.
    */
    func doesGetRequireAuthentication() -> Bool {
        getAccess(\.get, for: Access.requiresAuthentication.rawValue)
    }

    /**
     Check whether **find** requires authentication for this class.

     - returns: **true** if access is allowed, **false** otherwise.
    */
    func doesFindRequireAuthentication() -> Bool {
        getAccess(\.find, for: Access.requiresAuthentication.rawValue)
    }

    /**
     Check whether **count** requires authentication for this class.

     - returns: **true** if access is allowed, **false** otherwise.
    */
    func doesCountRequireAuthentication() -> Bool {
        getAccess(\.count, for: Access.requiresAuthentication.rawValue)
    }

    /**
     Check whether **create** requires authentication for this class.

     - returns: **true** if access is allowed, **false** otherwise.
    */
    func doesCreateRequireAuthentication() -> Bool {
        getAccess(\.create, for: Access.requiresAuthentication.rawValue)
    }

    /**
     Check whether **update** requires authentication for this class.

     - returns: **true** if access is allowed, **false** otherwise.
    */
    func doesUpdateRequireAuthentication() -> Bool {
        getAccess(\.update, for: Access.requiresAuthentication.rawValue)
    }

    /**
     Check whether **delete** requires authentication for this class.

     - returns: **true** if access is allowed, **false** otherwise.
    */
    func doesDeleteRequireAuthentication() -> Bool {
        getAccess(\.delete, for: Access.requiresAuthentication.rawValue)
    }

    /**
     Check whether **addField** requires authentication for this class.

     - returns: **true** if access is allowed, **false** otherwise.
    */
    func doesAddFieldRequireAuthentication() -> Bool {
        getAccess(\.addField, for: Access.requiresAuthentication.rawValue)
    }

    /**
     Sets whether **get** requires authentication for this class.
     
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setGetRequiresAuthentication(_ allow: Bool) -> Self {
        setAccess(\.get, for: Access.requiresAuthentication.rawValue, to: allow)
    }

    /**
     Sets whether **find** requires authentication for this class.
     
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setFindRequiresAuthentication(_ allow: Bool) -> Self {
        setAccess(\.find, for: Access.requiresAuthentication.rawValue, to: allow)
    }

    /**
     Sets whether **count** requires authentication for this class.
     
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setCountRequiresAuthentication(_ allow: Bool) -> Self {
        setAccess(\.count, for: Access.requiresAuthentication.rawValue, to: allow)
    }

    /**
     Sets whether **create** requires authentication for this class.
     
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setCreateRequiresAuthentication(_ allow: Bool) -> Self {
        setAccess(\.create, for: Access.requiresAuthentication.rawValue, to: allow)
    }

    /**
     Sets whether **update** requires authentication for this class.
     
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setUpdateRequiresAuthentication(_ allow: Bool) -> Self {
        setAccess(\.update, for: Access.requiresAuthentication.rawValue, to: allow)
    }

    /**
     Sets whether **delete** requires authentication for this class.
     
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setDeleteRequiresAuthentication(_ allow: Bool) -> Self {
        setAccess(\.delete, for: Access.requiresAuthentication.rawValue, to: allow)
    }

    /**
     Sets whether **addField** requires authentication for this class.
     
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setAddFieldRequiresAuthentication(_ allow: Bool) -> Self {
        setAccess(\.addField, for: Access.requiresAuthentication.rawValue, to: allow)
    }
}

// MARK: PublicAccess
public extension ParseCLP {

    /**
     Check whether **get** has public access for this class.

     - returns: **true** if access is allowed, **false** otherwise.
    */
    func doesGetHavePublicAccess() -> Bool {
        getAccess(\.get, for: Access.publicScope.rawValue)
    }

    /**
     Check whether **find** requires authentication for this class.

     - returns: **true** if access is allowed, **false** otherwise.
    */
    func doesFindHavePublicAccess() -> Bool {
        getAccess(\.find, for: Access.publicScope.rawValue)
    }

    /**
     Check whether **count** requires authentication for this class.

     - returns: **true** if access is allowed, **false** otherwise.
    */
    func doesCountHavePublicAccess() -> Bool {
        getAccess(\.count, for: Access.publicScope.rawValue)
    }

    /**
     Check whether **create** requires authentication for this class.

     - returns: **true** if access is allowed, **false** otherwise.
    */
    func doesCreateHavePublicAccess() -> Bool {
        getAccess(\.create, for: Access.publicScope.rawValue)
    }

    /**
     Check whether **update** requires authentication for this class.

     - returns: **true** if access is allowed, **false** otherwise.
    */
    func doesUpdateHavePublicAccess() -> Bool {
        getAccess(\.update, for: Access.publicScope.rawValue)
    }

    /**
     Check whether **delete** requires authentication for this class.

     - returns: **true** if access is allowed, **false** otherwise.
    */
    func doesDeleteHavePublicAccess() -> Bool {
        getAccess(\.delete, for: Access.publicScope.rawValue)
    }

    /**
     Check whether **addField** requires authentication for this class.

     - returns: **true** if access is allowed, **false** otherwise.
    */
    func doesAddFieldHavePublicAccess() -> Bool {
        getAccess(\.addField, for: Access.publicScope.rawValue)
    }

    /**
     Sets whether **get** requires authentication for this class.
     
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setGetPublicAccess(_ allow: Bool) -> Self {
        setAccess(\.get, for: Access.publicScope.rawValue, to: allow)
    }

    /**
     Sets whether **find** requires authentication for this class.
     
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setFindPublicAccess(_ allow: Bool) -> Self {
        setAccess(\.find, for: Access.publicScope.rawValue, to: allow)
    }

    /**
     Sets whether **count** requires authentication for this class.
     
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setCountPublicAccess(_ allow: Bool) -> Self {
        setAccess(\.count, for: Access.publicScope.rawValue, to: allow)
    }

    /**
     Sets whether **create** requires authentication for this class.
     
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setCreatePublicAccess(_ allow: Bool) -> Self {
        setAccess(\.create, for: Access.publicScope.rawValue, to: allow)
    }

    /**
     Sets whether **update** requires authentication for this class.
     
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setUpdatePublicAccess(_ allow: Bool) -> Self {
        setAccess(\.update, for: Access.publicScope.rawValue, to: allow)
    }

    /**
     Sets whether **delete** requires authentication for this class.
     
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setDeletePublicAccess(_ allow: Bool) -> Self {
        setAccess(\.delete, for: Access.publicScope.rawValue, to: allow)
    }

    /**
     Sets whether **addField** requires authentication for this class.
     
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setAddFieldPublicAccess(_ allow: Bool) -> Self {
        setAccess(\.addField, for: Access.publicScope.rawValue, to: allow)
    }
}

// MARK: WriteAccess
public extension ParseCLP {

    internal func setWrite(_ entity: String,
                           to allow: Bool,
                           can addField: Bool) -> Self {
        var updatedCLP = self
            .setAccess(\.create, for: entity, to: allow)
            .setAccess(\.update, for: entity, to: allow)
            .setAccess(\.delete, for: entity, to: allow)
        if addField {
            updatedCLP = updatedCLP.setAccess(\.addField, for: entity, to: allow)
        }
        return updatedCLP
    }

    internal func getWrite(_ entity: String, check addField: Bool) -> Bool {
        let access = getAccess(\.create, for: entity)
            && getAccess(\.update, for: entity)
            && getAccess(\.delete, for: entity)
        if addField {
            return access && getAccess(\.addField, for: entity)
        }
        return access
    }

    /**
     Check whether authentication is required to write to this class.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if authentication is required, **false** otherwise.
    */
    func doesWriteRequireAuthentication(_ checkAddField: Bool = false) -> Bool {
        getWrite(Access.requiresAuthentication.rawValue, check: checkAddField)
    }

    /**
     Check whether the public has access to write to this class.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if authentication is required, **false** otherwise.
    */
    func doesWriteHavePublicAccess(_ checkAddField: Bool = false) -> Bool {
        getWrite(Access.publicScope.rawValue, check: checkAddField)
    }

    /**
     Check whether the user objectId has access to write to this class.
     - parameter objectId: The user objectId to check.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if authentication is required, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they aare apart of a `ParseRole` that has access.
    */
    func doesHaveWriteAccess(_ objectId: String,
                             checkAddField: Bool = false) -> Bool {
        getWrite(objectId, check: checkAddField)
    }

    /**
     Check whether the `ParseUser` pointer has access to write to this class.
     - parameter user: The `ParseUser` pointer to check.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if authentication is required, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they aare apart of a `ParseRole` that has access.
    */
    func doesHaveWriteAccess<U>(_ user: Pointer<U>,
                                checkAddField: Bool = false) -> Bool where U: ParseUser {
        doesHaveWriteAccess(user.objectId, checkAddField: checkAddField)
    }

    /**
     Check whether the `ParseUser` has access to write to this class.
     - parameter user: The `ParseUser` to check.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if authentication is required, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they aare apart of a `ParseRole` that has access.
     - throws: An error of type `ParseError`.
    */
    func doesHaveWriteAccess<U>(_ user: U,
                                checkAddField: Bool = false) throws -> Bool where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return doesHaveWriteAccess(objectId, checkAddField: checkAddField)
    }

    /**
     Check whether the `ParseRole` has access to write to this class.
     - parameter role: The `ParseRole` to check.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if authentication is required, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they aare apart of a `ParseRole` that has access.
     - throws: An error of type `ParseError`.
    */
    func doesHaveWriteAccess<R>(_ role: R,
                                checkAddField: Bool = false) throws -> Bool where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return doesHaveWriteAccess(roleNameAccess, checkAddField: checkAddField)
    }

    /**
     Sets whether authentication is required to create/update/delete/addField this class.

     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter can: **true** if access should be allowed to `addField`, **false** otherwise.
     Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setRequiresAuthenticationWriteAccess(_ allow: Bool,
                                              canAddField addField: Bool = false) -> Self {
        setWrite(Access.requiresAuthentication.rawValue, to: allow, can: addField)
    }

    /**
     Sets whether the public is allowed to create/update/delete/addField this class.

     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter can: **true** if access should be allowed to `addField`, **false** otherwise.
     Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setPublicWriteAccess(_ allow: Bool,
                              canAddField addField: Bool = false) -> Self {
        setWrite(Access.publicScope.rawValue, to: allow, can: addField)
    }

    /**
     Sets whether the given user objectId is allowed to create/update/delete/addField to this class.
     
     - parameter objectId: The user objectId to provide/restrict access to.
     - parameter to: **true** if access should be allowed, **false** otherwise.
     - parameter can: **true** if access should be allowed to `addField`, **false** otherwise.
     Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteAccess(_ objectId: String,
                        to allow: Bool,
                        canAddField addField: Bool = false) -> Self {
        setWrite(objectId, to: allow, can: addField)
    }

    /**
     Sets whether the given `ParseUser` is allowed to create/update/delete/addField to this class.
     
     - parameter user: The `ParseUser` to provide/restrict access to.
     - parameter to: **true** if access should be allowed, **false** otherwise.
     - parameter can: **true** if access should be allowed to `addField`, **false** otherwise.
     Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setWriteAccess<U>(_ user: U,
                           to allow: Bool,
                           canAddField addField: Bool = false) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return setWriteAccess(objectId, to: allow, canAddField: addField)
    }

    /**
     Sets whether the given `ParseUser`pointer  is allowed to create/update/delete/addField to this class.
     
     - parameter user: The `ParseUser` to provide/restrict access to.
     - parameter to: **true** if access should be allowed, **false** otherwise.
     - parameter can: **true** if access should be allowed to `addField`, **false** otherwise.
     Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteAccess<U>(_ user: Pointer<U>,
                           to allow: Bool,
                           canAddField addField: Bool = false) -> Self where U: ParseUser {
        setWriteAccess(user.objectId, to: allow, canAddField: addField)
    }

    /**
     Sets whether the given `ParseRole` is allowed to create/update/delete/addField to this class.
     
     - parameter role: The `ParseRole` to provide/restrict access to.
     - parameter to: **true** if access should be allowed, **false** otherwise.
     - parameter can: **true** if access should be allowed to `addField`, **false** otherwise.
     Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setWriteAccess<R>(_ role: R,
                           to allow: Bool,
                           canAddField addField: Bool = false) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return setWriteAccess(roleNameAccess, to: allow, canAddField: addField)
    }
}

// MARK: ReadAccess
public extension ParseCLP {

    internal func setRead(_ entity: String, to allow: Bool) -> Self {
        let updatedCLP = self
            .setAccess(\.get, for: entity, to: allow)
            .setAccess(\.find, for: entity, to: allow)
            .setAccess(\.count, for: entity, to: allow)
        return updatedCLP
    }

    internal func getRead(_ entity: String) -> Bool {
        getAccess(\.get, for: entity)
            && getAccess(\.find, for: entity)
            && getAccess(\.count, for: entity)
    }

    /**
     Check whether authentication is required to read from this class.
     - returns: **true** if authentication is required, **false** otherwise.
    */
    func doesReadRequireAuthentication() -> Bool {
        getRead(Access.requiresAuthentication.rawValue)
    }

    /**
     Check whether the public has access to read from this class.
     - returns: **true** if authentication is required, **false** otherwise.
    */
    func doesReadHavePublicAccess() -> Bool {
        getRead(Access.publicScope.rawValue)
    }

    /**
     Check whether the user objectId has access to read from this class.
     - parameter objectId: The user objectId to check.
     - returns: **true** if authentication is required, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they aare apart of a `ParseRole` that has access.
    */
    func doesHaveReadAccess(_ objectId: String) -> Bool {
        getRead(objectId)
    }

    /**
     Check whether the `ParseUser` pointer has access to read from this class.
     - parameter user: The `ParseUser` pointer to check.
     - returns: **true** if authentication is required, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they aare apart of a `ParseRole` that has access.
    */
    func doesHaveReadAccess<U>(_ user: Pointer<U>) -> Bool where U: ParseUser {
        doesHaveReadAccess(user.objectId)
    }

    /**
     Check whether the `ParseUser` has access to read from this class.
     - parameter user: The `ParseUser` to check.
     - returns: **true** if authentication is required, **false** otherwise.
     - throws: An error of type `ParseError`.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they aare apart of a `ParseRole` that has access.
    */
    func doesHaveReadAccess<U>(_ user: U) throws -> Bool where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return doesHaveReadAccess(objectId)
    }

    /**
     Check whether the `ParseRole` has access to read from this class.
     - parameter role: The `ParseRole` to check.
     - returns: **true** if authentication is required, **false** otherwise.
     - throws: An error of type `ParseError`.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they aare apart of a `ParseRole` that has access.
    */
    func doesHaveReadAccess<R>(_ role: R) throws -> Bool where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return doesHaveReadAccess(roleNameAccess)
    }

    /**
     Sets whether authentication is required to get/find/count this class.

     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter can: **true** if access should be allowed to `addField`, **false** otherwise.
     Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setRequiresAuthenticationReadAccess(_ allow: Bool,
                                             canAddField addField: Bool = false) -> Self {
        setRead(Access.requiresAuthentication.rawValue, to: allow)
    }

    /**
     Sets whether the public is allowed to get/find/count this class.

     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setPublicReadAccess(_ allow: Bool) -> Self {
        setRead(Access.publicScope.rawValue, to: allow)
    }

    /**
     Sets whether the given user objectId is allowed to get/find/count this class.
     
     - parameter objectId: The user objectId to provide/restrict access to.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadAccess(_ objectId: String, to allow: Bool) -> Self {
        setRead(objectId, to: allow)
    }

    /**
     Sets whether the given `ParseUser` is allowed to get/find/count this class.
     
     - parameter role: The `ParseUser` to provide/restrict access to.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setReadAccess<U>(_ user: U, to allow: Bool) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return setReadAccess(objectId, to: allow)
    }

    /**
     Sets whether the given `ParseUser` is allowed to get/find/count this class.
     
     - parameter role: The `ParseUser` pointer to provide/restrict access to.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadAccess<U>(_ user: Pointer<U>,
                          to allow: Bool) -> Self where U: ParseUser {
        return setReadAccess(user.objectId, to: allow)
    }

    /**
     Sets whether the given `ParseRole` is allowed to get/find/count this class.
     
     - parameter role: The `ParseRole` to provide/restrict access to.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setReadAccess<R>(_ role: R, to allow: Bool) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return setReadAccess(roleNameAccess, to: allow)
    }
}
