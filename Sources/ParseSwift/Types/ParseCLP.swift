//
//  ParseCLP.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/// Class Level Permissions for `ParseSchema`.
public struct ParseCLP: ParseClassLevelPermisioinable {

    public var get: [String: Bool]?
    public var find: [String: Bool]?
    public var count: [String: Bool]?
    public var create: [String: Bool]?
    public var update: [String: Bool]?
    public var delete: [String: Bool]?
    public var addField: [String: Bool]?
    public var protectedFields: [String: [String]]?
    public var readUserFields: [String]?
    public var writeUserFields: [String]?

    enum Access: String {
        case requiresAuthentication
        case publicScope = "*"
    }

    /// Creates an empty CLP type.
    public init() { }

    func hasAccess(_ keyPath: KeyPath<Self, [String: Bool]?>,
                   for entity: String) -> Bool {
        self[keyPath: keyPath]?[entity] ?? false
    }

    func setAccess(_ keyPath: WritableKeyPath<Self, [String: Bool]?>,
                   to allow: Bool,
                   for entity: String) -> Self {
        let allowed: Bool? = allow ? allow : nil
        var mutableCLP = self
        if mutableCLP[keyPath: keyPath] != nil {
            mutableCLP[keyPath: keyPath]?[entity] = allowed
        } else if let allowed = allowed {
            mutableCLP[keyPath: keyPath] = [entity: allowed]
        }
        return mutableCLP
    }

}

// MARK: Default Implementation
public extension ParseCLP {

    init(requireAuthentication: Bool, publicAccess: Bool) {
        let clp = setWriteAccessRequiresAuthentication(requireAuthentication)
            .setReadAccessRequiresAuthentication(requireAuthentication)
            .setWriteAccessPublic(publicAccess)
            .setReadAccessPublic(publicAccess)
        self = clp
    }

    init(objectId: String, canAddFied: Bool = false) {
        let clp = setWriteAccess(true,
                                 objectId: objectId,
                                 canAddField: canAddFied)
            .setReadAccess(true, objectId: objectId)
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

    /**
     Checks if get/find/count/create/update/delete/addField actions currently have public access.
     - parameter keyPath: Any of the following keyPaths that represent an
     action on a `ParseSchema`: get/find/count/create/update/delete/addField.
     - returns: **true** if access is allowed, **false** otherwise.
    */
    func hasAccessPublic(_ keyPath: KeyPath<Self, [String: Bool]?>) throws -> Bool {
        hasAccess(keyPath, for: Access.publicScope.rawValue)
    }

    /**
     Checks if get/find/count/create/update/delete/addField actions currently requires authentication to access.
     - parameter keyPath: Any of the following keyPaths that represent an
     action on a `ParseSchema`: get/find/count/create/update/delete/addField.
     - returns: **true** if access is allowed, **false** otherwise.
     - warning: Requires Parse Server 2.3.0+.
    */
    func hasAccessRequiresAuthentication(_ keyPath: KeyPath<Self, [String: Bool]?>) throws -> Bool {
        hasAccess(keyPath, for: Access.requiresAuthentication.rawValue)
    }

    func hasAccess<U>(_ keyPath: KeyPath<Self, [String: Bool]?>,
                      for user: U) throws -> Bool where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return hasAccess(keyPath, for: objectId)
    }

    func hasAccess<U>(_ keyPath: KeyPath<Self, [String: Bool]?>,
                      for user: Pointer<U>) throws -> Bool where U: ParseUser {
        hasAccess(keyPath, for: user.objectId)
    }

    func hasAccess<R>(_ keyPath: KeyPath<Self, [String: Bool]?>,
                      for role: R) throws -> Bool where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return hasAccess(keyPath, for: roleNameAccess)
    }

    func setAccessPublic(_ keyPath: WritableKeyPath<Self, [String: Bool]?>,
                         to allow: Bool) -> Self {
        setAccess(keyPath, to: allow, for: Access.publicScope.rawValue)
    }

    /**
     - warning: Requires Parse Server 2.3.0+.
     */
    func setAccessRequiresAuthentication(_ keyPath: WritableKeyPath<Self, [String: Bool]?>,
                                         to allow: Bool) -> Self {
        setAccess(keyPath, to: allow, for: Access.requiresAuthentication.rawValue)
    }

    func setAccess<U>(_ keyPath: WritableKeyPath<Self, [String: Bool]?>,
                      to allow: Bool,
                      for user: U) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return setAccess(keyPath, to: allow, for: objectId)
    }

    func setAccess<U>(_ keyPath: WritableKeyPath<Self, [String: Bool]?>,
                      to allow: Bool,
                      for user: Pointer<U>) -> Self where U: ParseUser {
        setAccess(keyPath, to: allow, for: user.objectId)
    }

    func setAccess<R>(_ keyPath: WritableKeyPath<Self, [String: Bool]?>,
                      to allow: Bool,
                      for role: R) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return setAccess(keyPath, to: allow, for: roleNameAccess)
    }
}

// MARK: WriteAccess
public extension ParseCLP {

    internal func hasWriteAccess(_ entity: String,
                                 check addField: Bool) -> Bool {
        let access = hasAccess(\.create, for: entity)
            && hasAccess(\.update, for: entity)
            && hasAccess(\.delete, for: entity)
        if addField {
            return access && hasAccess(\.addField, for: entity)
        }
        return access
    }

    /**
     Check whether authentication is required to write to this class.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if authentication is required, **false** otherwise.
    */
    func hasWriteAccessRequiresAuthentication(_ checkAddField: Bool = false) -> Bool {
        hasWriteAccess(Access.requiresAuthentication.rawValue, check: checkAddField)
    }

    /**
     Check whether the public has access to write to this class.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if authentication is required, **false** otherwise.
    */
    func hasWriteAccessPublic(_ checkAddField: Bool = false) -> Bool {
        hasWriteAccess(Access.publicScope.rawValue, check: checkAddField)
    }

    /**
     Check whether the `ParseUser` objectId has access to write to this class.
     - parameter objectId: The `ParseUser` objectId to check.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if authentication is required, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they aare apart of a `ParseRole` that has access.
     - throws: An error of type `ParseError`.
    */
    func hasWriteAccess(_ objectId: String,
                        checkAddField: Bool = false) -> Bool {
        hasWriteAccess(objectId, check: checkAddField)
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
    func hasWriteAccess<U>(_ user: Pointer<U>,
                           checkAddField: Bool = false) -> Bool where U: ParseUser {
        hasWriteAccess(user.objectId, checkAddField: checkAddField)
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
    func hasWriteAccess<U>(_ user: U,
                           checkAddField: Bool = false) throws -> Bool where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return hasWriteAccess(objectId, checkAddField: checkAddField)
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
    func hasWriteAccess<R>(_ role: R,
                           checkAddField: Bool = false) throws -> Bool where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return hasWriteAccess(roleNameAccess, checkAddField: checkAddField)
    }

    /**
     Sets whether authentication is required to create/update/delete/addField this class.

     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter can: **true** if access should be allowed to `addField`, **false** otherwise.
     Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteAccessRequiresAuthentication(_ allow: Bool,
                                              canAddField addField: Bool = false) -> Self {
        setWriteAccess(allow, objectId: Access.requiresAuthentication.rawValue, canAddField: addField)
    }

    /**
     Sets whether the public is allowed to create/update/delete/addField this class.

     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter can: **true** if access should be allowed to `addField`, **false** otherwise.
     Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteAccessPublic(_ allow: Bool,
                              canAddField addField: Bool = false) -> Self {
        setWriteAccess(allow, objectId: Access.publicScope.rawValue, canAddField: addField)
    }

    /**
     Sets whether the given `ParseUser` objectId  is allowed to create/update/delete/addField to this class.
     
     - parameter objectId: The `ParseUser` objectId to provide/restrict access to.
     - parameter to: **true** if access should be allowed, **false** otherwise.
     - parameter can: **true** if access should be allowed to `addField`, **false** otherwise.
     Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteAccess(_ allow: Bool,
                        objectId: String,
                        canAddField addField: Bool = false) -> Self {
        var updatedCLP = self
            .setAccess(\.create, to: allow, for: objectId)
            .setAccess(\.update, to: allow, for: objectId)
            .setAccess(\.delete, to: allow, for: objectId)
        if addField {
            updatedCLP = updatedCLP.setAccess(\.addField, to: allow, for: objectId)
        }
        return updatedCLP
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
    func setWriteAccess<U>(_ allow: Bool,
                           user: U,
                           canAddField addField: Bool = false) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return setWriteAccess(allow, objectId: objectId, canAddField: addField)
    }

    /**
     Sets whether the given `ParseUser`pointer  is allowed to create/update/delete/addField to this class.
     
     - parameter user: The `ParseUser` to provide/restrict access to.
     - parameter to: **true** if access should be allowed, **false** otherwise.
     - parameter can: **true** if access should be allowed to `addField`, **false** otherwise.
     Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteAccess<U>(_ allow: Bool,
                           user: Pointer<U>,
                           canAddField addField: Bool = false) -> Self where U: ParseUser {
        setWriteAccess(allow, objectId: user.objectId, canAddField: addField)
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
    func setWriteAccess<R>(_ allow: Bool,
                           role: R,
                           canAddField addField: Bool = false) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return setWriteAccess(allow, objectId: roleNameAccess, canAddField: addField)
    }
}

// MARK: ReadAccess
public extension ParseCLP {

    /**
     Check whether authentication is required to read from this class.
     - returns: **true** if authentication is required, **false** otherwise.
    */
    func hasReadAccessRequiresAuthentication() -> Bool {
        hasReadAccess(Access.requiresAuthentication.rawValue)
    }

    /**
     Check whether the public has access to read from this class.
     - returns: **true** if authentication is required, **false** otherwise.
    */
    func hasReadAccessPublic() -> Bool {
        hasReadAccess(Access.publicScope.rawValue)
    }

    /**
     Check whether the `ParseUser` objectId has access to read from this class.
     - parameter objectId: The `ParseUser` objectId to check.
     - returns: **true** if authentication is required, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they aare apart of a `ParseRole` that has access.
    */
    func hasReadAccess(_ objectId: String) -> Bool {
        hasAccess(\.get, for: objectId)
            && hasAccess(\.find, for: objectId)
            && hasAccess(\.count, for: objectId)
    }

    /**
     Check whether the `ParseUser` pointer has access to read from this class.
     - parameter user: The `ParseUser` pointer to check.
     - returns: **true** if authentication is required, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they aare apart of a `ParseRole` that has access.
    */
    func hasReadAccess<U>(_ user: Pointer<U>) -> Bool where U: ParseUser {
        hasReadAccess(user.objectId)
    }

    /**
     Check whether the `ParseUser` has access to read from this class.
     - parameter user: The `ParseUser` to check.
     - returns: **true** if authentication is required, **false** otherwise.
     - throws: An error of type `ParseError`.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they aare apart of a `ParseRole` that has access.
    */
    func hasReadAccess<U>(_ user: U) throws -> Bool where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return hasReadAccess(objectId)
    }

    /**
     Check whether the `ParseRole` has access to read from this class.
     - parameter role: The `ParseRole` to check.
     - returns: **true** if authentication is required, **false** otherwise.
     - throws: An error of type `ParseError`.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they aare apart of a `ParseRole` that has access.
    */
    func hasReadAccess<R>(_ role: R) throws -> Bool where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return hasReadAccess(roleNameAccess)
    }

    /**
     Sets whether authentication is required to get/find/count this class.

     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter can: **true** if access should be allowed to `addField`, **false** otherwise.
     Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadAccessRequiresAuthentication(_ allow: Bool,
                                             canAddField addField: Bool = false) -> Self {
        setReadAccess(allow, objectId: Access.requiresAuthentication.rawValue)
    }

    /**
     Sets whether the public is allowed to get/find/count this class.

     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadAccessPublic(_ allow: Bool) -> Self {
        setReadAccess(allow, objectId: Access.publicScope.rawValue)
    }

    /**
     Sets whether the given `ParseUser` is allowed to get/find/count this class.
     
     - parameter objectId: The `ParseUser` pointer to provide/restrict access to.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadAccess(_ allow: Bool,
                       objectId: String) -> Self {
        let updatedCLP = self
            .setAccess(\.get, to: allow, for: objectId)
            .setAccess(\.find, to: allow, for: objectId)
            .setAccess(\.count, to: allow, for: objectId)
        return updatedCLP
    }

    /**
     Sets whether the given `ParseUser` is allowed to get/find/count this class.
     
     - parameter role: The `ParseUser` to provide/restrict access to.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setReadAccess<U>(_ allow: Bool,
                          user: U) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return setReadAccess(allow, objectId: objectId)
    }

    /**
     Sets whether the given `ParseUser` is allowed to get/find/count this class.
     
     - parameter role: The `ParseUser` pointer to provide/restrict access to.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadAccess<U>(_ allow: Bool,
                          user: Pointer<U>) -> Self where U: ParseUser {
        return setReadAccess(allow, objectId: user.objectId)
    }

    /**
     Sets whether the given `ParseRole` is allowed to get/find/count this class.
     
     - parameter role: The `ParseRole` to provide/restrict access to.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setReadAccess<R>(_ allow: Bool, role: R) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return setReadAccess(allow, objectId: roleNameAccess)
    }
}

// MARK: CustomDebugStringConvertible
extension ParseCLP: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
            return "ParseCLP ()"
        }
        return "ParseCLP (\(descriptionString))"
    }
}

// MARK: CustomStringConvertible
extension ParseCLP: CustomStringConvertible {
    public var description: String {
        debugDescription
    }
}
