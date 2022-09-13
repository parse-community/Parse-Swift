//
//  ParseCLP.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/// Class Level Permissions for `ParseSchema`.
public struct ParseCLP: ParseTypeable {

    var get: [String: AnyCodable]?
    var find: [String: AnyCodable]?
    var count: [String: AnyCodable]?
    var create: [String: AnyCodable]?
    var update: [String: AnyCodable]?
    var delete: [String: AnyCodable]?
    var addField: [String: AnyCodable]?
    /**
     The users, roles, and access level restrictions who cannot access particular
     fields in a Parse class.
     */
    public internal(set) var protectedFields: [String: Set<String>]?
    /**
     Fields of `ParseUser` type or an array of `ParseUser`'s that
     can perform get/count/find actions on a Parse class.
     */
    public var readUserFields: Set<String>?
    /**
     Fields of `ParseUser` type or an array of `ParseUser`'s that
     can perform create/delete/update/addField actions on a Parse class.
     */
    public var writeUserFields: Set<String>?

    /// The avialable actions to perform on a Parse class.
    public enum Action {
        /// Fetch `ParseObject`'s.
        case get
        /// Query for `ParseObject`'s.
        case find
        /// Count `ParseObject`'s.
        case count
        /// Create new `ParseObject`'s.
        case create
        /// Update `ParseObject`'s.
        case update
        /// Delete `ParseObject`'s.
        case delete
        /// Add fields to the Parse class.
        case addField

        internal func keyPath() -> KeyPath<ParseCLP, [String: AnyCodable]?> {
            let keyPath: KeyPath<ParseCLP, [String: AnyCodable]?>
            switch self {
            case .get:
                keyPath = \.get
            case .find:
                keyPath = \.find
            case .count:
                keyPath = \.count
            case .create:
                keyPath = \.create
            case .update:
                keyPath = \.update
            case .delete:
                keyPath = \.delete
            case .addField:
                keyPath = \.addField
            }
            return keyPath
        }

        internal func writableKeyPath() -> WritableKeyPath<ParseCLP, [String: AnyCodable]?> {
            let keyPath: WritableKeyPath<ParseCLP, [String: AnyCodable]?>
            switch self {
            case .get:
                keyPath = \.get
            case .find:
                keyPath = \.find
            case .count:
                keyPath = \.count
            case .create:
                keyPath = \.create
            case .update:
                keyPath = \.update
            case .delete:
                keyPath = \.delete
            case .addField:
                keyPath = \.addField
            }
            return keyPath
        }
    }

    enum Access: String {
        case requiresAuthentication
        case publicScope = "*"
        case pointerFields
    }

    /// Creates an empty instance of CLP.
    public init() { }

    /**
     Creates an instance of CLP with particular access.
     - parameter requiresAuthentication: Read/Write to a Parse class requires users to be authenticated.
     - parameter publicAccess:Read/Write to a Parse class can be done by the public.
     - warning: Setting `requiresAuthentication` and `publicAccess` does not give **addField**
     access. You can set **addField** access after creating an instance of CLP.
     - warning: Use of `requiresAuthentication == true` requires Parse Server 2.3.0+.
     */
    public init(requiresAuthentication: Bool, publicAccess: Bool) {
        let clp = setWriteAccessRequiresAuthentication(requiresAuthentication)
            .setReadAccessRequiresAuthentication(requiresAuthentication)
            .setWriteAccessPublic(publicAccess)
            .setReadAccessPublic(publicAccess)
        self = clp
    }
}

// MARK: Default Implementation
extension ParseCLP {
    static func getUserFieldAccess(_ field: String) -> String {
        "userField:\(field)"
    }

    func hasAccess(_ keyPath: KeyPath<Self, [String: AnyCodable]?>,
                   for entity: String) -> Bool {
        self[keyPath: keyPath]?[entity]?.value as? Bool ?? false
    }

    func setAccess(_ allow: Bool,
                   on keyPath: WritableKeyPath<Self, [String: AnyCodable]?>,
                   for entity: String) -> Self {
        let allowed: Bool? = allow ? allow : nil
        var mutableCLP = self
        if let allowed = allowed {
            let value = AnyCodable(allowed)
            if mutableCLP[keyPath: keyPath] != nil {
                mutableCLP[keyPath: keyPath]?[entity] = value
            } else {
                mutableCLP[keyPath: keyPath] = [entity: value]
            }
        } else {
            mutableCLP[keyPath: keyPath]?[entity] = nil
        }
        return mutableCLP
    }

    func getPointerFields(_ keyPath: KeyPath<Self, [String: AnyCodable]?>) -> Set<String> {
        self[keyPath: keyPath]?[Access.pointerFields.rawValue]?.value as? Set<String> ?? []
    }

    func setPointer(_ fields: Set<String>,
                    on keyPath: WritableKeyPath<Self, [String: AnyCodable]?>) -> Self {
        var mutableCLP = self
        let value = AnyCodable(fields)
        if mutableCLP[keyPath: keyPath] != nil {
            mutableCLP[keyPath: keyPath]?[Access.pointerFields.rawValue] = value
        } else {
            mutableCLP[keyPath: keyPath] = [Access.pointerFields.rawValue: value]
        }
        return mutableCLP
    }

    func addPointer(_ fields: Set<String>,
                    on keyPath: WritableKeyPath<Self, [String: AnyCodable]?>) -> Self {

        if let currentSet = self[keyPath: keyPath]?[Access.pointerFields.rawValue]?.value as? Set<String> {
            var mutableCLP = self
            mutableCLP[keyPath: keyPath]?[Access.pointerFields.rawValue] = AnyCodable(currentSet.union(fields))
            return mutableCLP
        } else {
            return setPointer(fields, on: keyPath)
        }
    }

    func removePointer(_ fields: Set<String>,
                       on keyPath: WritableKeyPath<Self, [String: AnyCodable]?>) -> Self {
        var mutableCLP = self
        if var currentSet = self[keyPath: keyPath]?[Access.pointerFields.rawValue]?.value as? Set<String> {
            fields.forEach { currentSet.remove($0) }
            mutableCLP[keyPath: keyPath]?[Access.pointerFields.rawValue] = AnyCodable(currentSet)
        }
        return mutableCLP
    }
}

// MARK: Standard Access
public extension ParseCLP {
    /**
     Checks if an `Action` on a Parse class has public access.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - returns: **true** if access is allowed, **false** otherwise.
    */
    func hasAccessPublic(_ action: Action) -> Bool {
        hasAccess(action.keyPath(), for: Access.publicScope.rawValue)
    }

    /**
     Checks if an `Action` on a Parse class requires users to be authenticated to access.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - returns: **true** if access is allowed, **false** otherwise.
     - warning: Requires Parse Server 2.3.0+.
    */
    func hasAccessRequiresAuthentication(_ action: Action) -> Bool {
        hasAccess(action.keyPath(), for: Access.requiresAuthentication.rawValue)
    }

    /**
     Checks if an `Action` on a Parse class provides access to a specific `objectId`.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - parameter objectId: The `ParseUser` objectId to check.
     - returns: **true** if access is allowed, **false** otherwise.
    */
    func hasAccess(_ action: Action,
                   for objectId: String) -> Bool {
        return hasAccess(action.keyPath(), for: objectId)
    }

    /**
     Checks if an `Action` on a Parse class provides access to a specific `ParseUser`.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - parameter user: The `ParseUser` to check.
     - returns: **true** if access is allowed, **false** otherwise.
     - throws: An error of type `ParseError`.
    */
    func hasAccess<U>(_ action: Action,
                      for user: U) throws -> Bool where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return hasAccess(action.keyPath(), for: objectId)
    }

    /**
     Checks if an `Action` on a Parse class provides access to a specific `ParseUser` pointer.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - parameter user: The `ParseUser` pointer to check.
     - returns: **true** if access is allowed, **false** otherwise.
    */
    func hasAccess<U>(_ action: Action,
                      for user: Pointer<U>) -> Bool where U: ParseUser {
        hasAccess(action.keyPath(), for: user.objectId)
    }

    /**
     Checks if an `Action` on a Parse class provides access to a specific `ParseRole`.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - parameter role: The `ParseRole` to check.
     - returns: **true** if access is allowed, **false** otherwise.
     - throws: An error of type `ParseError`.
    */
    func hasAccess<R>(_ action: Action,
                      for role: R) throws -> Bool where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return hasAccess(action.keyPath(), for: roleNameAccess)
    }

    /**
     Set/remove public access to an `Action` on a Parse class.
     - parameter allow: **true** to allow access , **false** to remove access.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setAccessPublic(_ allow: Bool,
                         on action: Action) -> Self {
        setAccess(allow, on: action.writableKeyPath(), for: Access.publicScope.rawValue)
    }

    /**
     Set/remove require user authentication to access an `Action` on a Parse class.
     - parameter allow: **true** to allow access , **false** to remove access.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - warning: Requires Parse Server 2.3.0+.
     */
    func setAccessRequiresAuthentication(_ allow: Bool,
                                         on action: Action) -> Self {
        setAccess(allow, on: action.writableKeyPath(), for: Access.requiresAuthentication.rawValue)
    }

    /**
     Set/remove access to an `Action` for a specific user objectId on a Parse class.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - parameter allow: **true** to allow access , **false** to remove access.
     - parameter objectId: The `ParseUser` objectId to add/remove access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     */
    func setAccess(_ allow: Bool,
                   on action: Action,
                   for objectId: String) -> Self {
        setAccess(allow, on: action.writableKeyPath(), for: objectId)
    }

    /**
     Set/remove access to an `Action` for a specific user `ParseUser` on a Parse class.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - parameter allow: **true** to allow access , **false** to remove access.
     - parameter objectId: The `ParseUser` to add/remove access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     */
    func setAccess<U>(_ allow: Bool,
                      on action: Action,
                      for user: U) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return setAccess(allow, on: action.writableKeyPath(), for: objectId)
    }

    /**
     Set/remove access to an `Action` for a specific user `ParseUser` pointer on a Parse class.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - parameter allow: **true** to allow access , **false** to remove access.
     - parameter user: The `ParseUser` pointer to add/remove access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     */
    func setAccess<U>(_ allow: Bool,
                      on action: Action,
                      for user: Pointer<U>) -> Self where U: ParseUser {
        setAccess(allow, on: action.writableKeyPath(), for: user.objectId)
    }

    /**
     Set/remove access to an `Action` for a specific `ParseRole` on a Parse class.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - parameter allow: **true** to allow access , **false** to remove access.
     - parameter objectId: The `ParseRole` to add/remove access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     */
    func setAccess<R>(_ allow: Bool,
                      on action: Action,
                      for role: R) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return setAccess(allow, on: action.writableKeyPath(), for: roleNameAccess)
    }
}

// MARK: WriteAccess
public extension ParseCLP {
    internal func hasWriteAccess(_ entity: String,
                                 check addField: Bool) -> Bool {
        let access = hasAccess(.create, for: entity)
            && hasAccess(.update, for: entity)
            && hasAccess(.delete, for: entity)
        if addField {
            return access && hasAccess(.addField, for: entity)
        }
        return access
    }

    /**
     Check whether user authentication is required to perform create/update/delete/addField actions on a Parse class.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if has access, **false** otherwise.
     - warning: Requires Parse Server 2.3.0+.
    */
    func hasWriteAccessRequiresAuthentication(_ checkAddField: Bool = false) -> Bool {
        hasWriteAccess(Access.requiresAuthentication.rawValue, check: checkAddField)
    }

    /**
     Check whether the public has access to perform create/update/delete/addField actions on a Parse class.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if has access, **false** otherwise.
    */
    func hasWriteAccessPublic(_ checkAddField: Bool = false) -> Bool {
        hasWriteAccess(Access.publicScope.rawValue, check: checkAddField)
    }

    /**
     Check whether a `ParseUser` objectId has access to perform create/update/delete/addField actions on a Parse class.
     - parameter objectId: The `ParseUser` objectId to check.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if has access, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they are apart of a `ParseRole` that has access.
     - throws: An error of type `ParseError`.
    */
    func hasWriteAccess(_ objectId: String,
                        checkAddField: Bool = false) -> Bool {
        hasWriteAccess(objectId, check: checkAddField)
    }

    /**
     Check whether the `ParseUser` pointer has access to perform create/update/delete/addField actions on a Parse class.
     - parameter user: The `ParseUser` pointer to check.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if has access, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they are apart of a `ParseRole` that has access.
    */
    func hasWriteAccess<U>(_ user: Pointer<U>,
                           checkAddField: Bool = false) -> Bool where U: ParseUser {
        hasWriteAccess(user.objectId, checkAddField: checkAddField)
    }

    /**
     Check whether the `ParseUser` has access to perform create/update/delete/addField actions on a Parse class.
     - parameter user: The `ParseUser` to check.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if has access, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they are apart of a `ParseRole` that has access.
     - throws: An error of type `ParseError`.
    */
    func hasWriteAccess<U>(_ user: U,
                           checkAddField: Bool = false) throws -> Bool where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return hasWriteAccess(objectId, checkAddField: checkAddField)
    }

    /**
     Check whether the `ParseRole` has access to perform create/update/delete/addField actions on a Parse class.
     - parameter role: The `ParseRole` to check.
     - parameter checkAddField: **true** if `addField` should be part of the check, **false** otherwise.
     Defaults to **false**.
     - returns: **true** if has access, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they are apart of a `ParseRole` that has access.
     - throws: An error of type `ParseError`.
    */
    func hasWriteAccess<R>(_ role: R,
                           checkAddField: Bool = false) throws -> Bool where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return hasWriteAccess(roleNameAccess, checkAddField: checkAddField)
    }

    /**
     Sets whether user authentication is required to perform create/update/delete/addField actions on a Parse class.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter canAddField: **true** if access should be allowed to `addField`,
     **false** otherwise. Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - warning: Requires Parse Server 2.3.0+.
    */
    func setWriteAccessRequiresAuthentication(_ allow: Bool,
                                              canAddField addField: Bool = false) -> Self {
        setWriteAccess(allow, for: Access.requiresAuthentication.rawValue, canAddField: addField)
    }

    /**
     Sets whether the public has access to perform create/update/delete/addField actions on a Parse class.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter canAddField: **true** if access should be allowed to `addField`,
     **false** otherwise. Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteAccessPublic(_ allow: Bool,
                              canAddField addField: Bool = false) -> Self {
        setWriteAccess(allow, for: Access.publicScope.rawValue, canAddField: addField)
    }

    /**
     Sets whether the given `ParseUser` objectId  has access to perform
     create/update/delete/addField actions on a Parse class.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter objectId: The `ParseUser` objectId to provide/restrict access to.
     - parameter canAddField: **true** if access should be allowed to `addField`,
     **false** otherwise. Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteAccess(_ allow: Bool,
                        for objectId: String,
                        canAddField addField: Bool = false) -> Self {
        var updatedCLP = self
            .setAccess(allow, on: .create, for: objectId)
            .setAccess(allow, on: .update, for: objectId)
            .setAccess(allow, on: .delete, for: objectId)
        if addField {
            updatedCLP = updatedCLP.setAccess(allow, on: .addField, for: objectId)
        } else {
            updatedCLP = updatedCLP.setAccess(false, on: .addField, for: objectId)
        }
        return updatedCLP
    }

    /**
     Sets whether the given `ParseUser` has access to perform create/update/delete/addField actions on a Parse class.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter user: The `ParseUser` to provide/restrict access to.
     - parameter canAddField: **true** if access should be allowed to `addField`,
     **false** otherwise. Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setWriteAccess<U>(_ allow: Bool,
                           for user: U,
                           canAddField addField: Bool = false) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return setWriteAccess(allow, for: objectId, canAddField: addField)
    }

    /**
     Sets whether the given `ParseUser`pointer  has access to perform
     create/update/delete/addField actions on a Parse class.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter user: The `ParseUser` to provide/restrict access to.
     - parameter canAddField: **true** if access should be allowed to `addField`,
     **false** otherwise. Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteAccess<U>(_ allow: Bool,
                           for user: Pointer<U>,
                           canAddField addField: Bool = false) -> Self where U: ParseUser {
        setWriteAccess(allow, for: user.objectId, canAddField: addField)
    }

    /**
     Sets whether the given `ParseRole` has access to perform create/update/delete/addField actions on a Parse class.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter role: The `ParseRole` to provide/restrict access to.
     - parameter canAddField: **true** if access should be allowed to `addField`,
     **false** otherwise. Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setWriteAccess<R>(_ allow: Bool,
                           for role: R,
                           canAddField addField: Bool = false) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return setWriteAccess(allow, for: roleNameAccess, canAddField: addField)
    }
}

// MARK: ReadAccess
public extension ParseCLP {
    /**
     Check whether user authentication is required to perform get/find/count actions on a Parse class.
     - returns: **true** if has access, **false** otherwise.
     - warning: Requires Parse Server 2.3.0+.
    */
    func hasReadAccessRequiresAuthentication() -> Bool {
        hasReadAccess(Access.requiresAuthentication.rawValue)
    }

    /**
     Check whether the public has access to perform get/find/count actions on a Parse class.
     - returns: **true** if has access, **false** otherwise.
    */
    func hasReadAccessPublic() -> Bool {
        hasReadAccess(Access.publicScope.rawValue)
    }

    /**
     Check whether the `ParseUser` objectId has access to perform get/find/count actions on a Parse class.
     - parameter objectId: The `ParseUser` objectId to check.
     - returns: **true** if has access, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they are apart of a `ParseRole` that has access.
    */
    func hasReadAccess(_ objectId: String) -> Bool {
        hasAccess(.get, for: objectId)
            && hasAccess(.find, for: objectId)
            && hasAccess(.count, for: objectId)
    }

    /**
     Check whether the `ParseUser` pointer has access to perform get/find/count actions on a Parse class.
     - parameter user: The `ParseUser` pointer to check.
     - returns: **true** if has access, **false** otherwise.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they are apart of a `ParseRole` that has access.
    */
    func hasReadAccess<U>(_ user: Pointer<U>) -> Bool where U: ParseUser {
        hasReadAccess(user.objectId)
    }

    /**
     Check whether the `ParseUser` has access to perform get/find/count actions on a Parse class.
     - parameter user: The `ParseUser` to check.
     - returns: **true** if has access, **false** otherwise.
     - throws: An error of type `ParseError`.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they are apart of a `ParseRole` that has access.
    */
    func hasReadAccess<U>(_ user: U) throws -> Bool where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return hasReadAccess(objectId)
    }

    /**
     Check whether the `ParseRole` has access to perform get/find/count actions on a Parse class.
     - parameter role: The `ParseRole` to check.
     - returns: **true** if has access, **false** otherwise.
     - throws: An error of type `ParseError`.
     - warning: Even if **false** is returned, the `ParseUser`/`ParseRole` may still
     have access if they are apart of a `ParseRole` that has access.
    */
    func hasReadAccess<R>(_ role: R) throws -> Bool where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return hasReadAccess(roleNameAccess)
    }

    /**
     Sets whether authentication is required to perform get/find/count actions on a Parse class.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter canAddField: **true** if access should be allowed to `addField`,
     **false** otherwise. Defaults to **false**.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - warning: Requires Parse Server 2.3.0+.
    */
    func setReadAccessRequiresAuthentication(_ allow: Bool,
                                             canAddField addField: Bool = false) -> Self {
        setReadAccess(allow, for: Access.requiresAuthentication.rawValue)
    }

    /**
     Sets whether the public has access to perform get/find/count actions on a Parse class.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadAccessPublic(_ allow: Bool) -> Self {
        setReadAccess(allow, for: Access.publicScope.rawValue)
    }

    /**
     Sets whether the given `ParseUser` has access to perform get/find/count actions on a Parse class.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter objectId: The `ParseUser` pointer to provide/restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadAccess(_ allow: Bool,
                       for objectId: String) -> Self {
        let updatedCLP = self
            .setAccess(allow, on: .get, for: objectId)
            .setAccess(allow, on: .find, for: objectId)
            .setAccess(allow, on: .count, for: objectId)
        return updatedCLP
    }

    /**
     Sets whether the given `ParseUser` has access to perform get/find/count actions on a Parse class.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter user: The `ParseUser` to provide/restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setReadAccess<U>(_ allow: Bool,
                          for user: U) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return setReadAccess(allow, for: objectId)
    }

    /**
     Sets whether the given `ParseUser` has access to perform get/find/count actions on a Parse class.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter user: The `ParseUser` pointer to provide/restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadAccess<U>(_ allow: Bool,
                          for user: Pointer<U>) -> Self where U: ParseUser {
        return setReadAccess(allow, for: user.objectId)
    }

    /**
     Sets whether the given `ParseRole` has access to perform get/find/count actions on a Parse class.
     - parameter allow: **true** if access should be allowed, **false** otherwise.
     - parameter role: The `ParseRole` to provide/restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setReadAccess<R>(_ allow: Bool,
                          for role: R) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return setReadAccess(allow, for: roleNameAccess)
    }
}

// MARK: Pointer Access
public extension ParseCLP {
    /**
     Retreive the fields in a Parse class that determine access for a specific `Action`.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - returns: The set of fields that are either of`ParseUser` type or
     an array of `ParseUser`'s.
    */
    func getPointerFields(_ action: Action) -> Set<String> {
        getPointerFields(action.keyPath())
    }

    /**
     Give access to a set of fields that are either of `ParseUser` type or an array
     `ParseUser`'s for a specific `Action` on a Parse class.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - parameter fields: The set of fields that are either of`ParseUser` type or
     an array of `ParseUser`'s.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - note: This method replaces the current set of `fields` in the CLP.
     - warning: Requires Parse Server 3.1.1+.
     */
    func setPointerFields(_ fields: Set<String>,
                          on action: Action) -> Self {
        setPointer(fields, on: action.writableKeyPath())
    }

    /**
     Add access to an additional set of fields that are either of `ParseUser` type or an array
     `ParseUser`'s for a specific `Action` on a Parse class.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - parameter fields: The set of fields that are either of`ParseUser` type or
     an array of `ParseUser`'s.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - note: This method adds on to the current set of `fields` in the CLP.
     - warning: Requires Parse Server 3.1.1+.
     */
    func addPointerFields(_ fields: Set<String>,
                          on action: Action) -> Self {
        addPointer(fields, on: action.writableKeyPath())
    }

    /**
     Remove access for the set of fields that are either of `ParseUser` type or an array
     `ParseUser`'s for a specific `Action` on a Parse class.
     - parameter action: An enum value of one of the following actions:
     get/find/count/create/update/delete/addField.
     - parameter fields: The set of fields that are either of`ParseUser` type or
     an array of `ParseUser`'s.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - note: This method removes from the current set of `fields` in the CLP.
     - warning: Requires Parse Server 3.1.1+.
     */
    func removePointerFields(_ fields: Set<String>,
                             on action: Action) -> Self {
        removePointer(fields, on: action.writableKeyPath())
    }
}

// MARK: Protected Fields
public extension ParseCLP {
    internal func getProtected(_ keyPath: KeyPath<Self, [String: Set<String>]?>,
                               for entity: String) -> Set<String> {
        self[keyPath: keyPath]?[entity] ?? []
    }

    internal func setProtected(_ fields: Set<String>,
                               on keyPath: WritableKeyPath<Self, [String: Set<String>]?>,
                               for entity: String) -> Self {
        var mutableCLP = self
        if mutableCLP[keyPath: keyPath] != nil {
            mutableCLP[keyPath: keyPath]?[entity] = fields
        } else {
            mutableCLP[keyPath: keyPath] = [entity: fields]
        }
        return mutableCLP
    }

    internal func addProtected(_ fields: Set<String>,
                               on keyPath: WritableKeyPath<Self, [String: Set<String>]?>,
                               for entity: String) -> Self {
        if let currentSet = self[keyPath: keyPath]?[entity] {
            var mutableCLP = self
            mutableCLP[keyPath: keyPath]?[entity] = currentSet.union(fields)
            return mutableCLP
        } else {
            return setProtected(fields, on: keyPath, for: entity)
        }
    }

    internal func removeProtected(_ fields: Set<String>,
                                  on keyPath: WritableKeyPath<Self, [String: Set<String>]?>,
                                  for entity: String) -> Self {
        var mutableCLP = self
        fields.forEach {
            mutableCLP[keyPath: keyPath]?[entity]?.remove($0)
        }
        return mutableCLP
    }

    /**
     Get the fields the publc cannot access.
     - returns: The set protected fields that cannot be accessed.
    */
    func getProtectedFieldsPublic() -> Set<String> {
        getProtectedFields(Access.publicScope.rawValue)
    }

    /**
     Get the fields the users with authentication cannot access.
     - returns: The set protected fields that cannot be accessed.
     - warning: Requires Parse Server 2.3.0+.
    */
    func getProtectedFieldsRequiresAuthentication() -> Set<String> {
        getProtectedFields(Access.requiresAuthentication.rawValue)
    }

    /**
     Get the protected fields either a field of `ParseUser` type or
     an array of `ParseUser`'s in a Parse class cannot access.
     - parameter field: A field in a Parse class that is either of `ParseUser` type or
     an array of `ParseUser`'s.
     - returns: The set protected fields that cannot be accessed.
    */
    func getProtectedFieldsUser(_ field: String) -> Set<String> {
        getProtectedFields(Self.getUserFieldAccess(field))
    }

    /**
     Get the protected fields the given `ParseUser` objectId cannot access.
     - parameter objectId: The `ParseUser` objectId access to check.
     - returns: The set protected fields that cannot be accessed.
    */
    func getProtectedFields(_ objectId: String) -> Set<String> {
        getProtected(\.protectedFields, for: objectId)
    }

    /**
     Get the protected fields the given `ParseUser` cannot access.
     - parameter user: The `ParseUser` access to check.
     - returns: The set protected fields that cannot be accessed.
     - throws: An error of type `ParseError`.
    */
    func getProtectedFields<U>(_ user: U) throws -> Set<String> where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return getProtectedFields(objectId)
    }

    /**
     Get the protected fields for the given `ParseUser` pointer cannot access.
     - parameter user: The `ParseUser` access to check.
     - returns: The set protected fields that cannot be accessed.
    */
    func getProtectedFields<U>(_ user: Pointer<U>) -> Set<String> where U: ParseUser {
        getProtectedFields(user.objectId)
    }

    /**
     Get the protected fields the given `ParseRole` cannot access.
     - parameter role: The `ParseRole` access to check.
     - returns: The set protected fields that cannot be accessed.
     - throws: An error of type `ParseError`.
    */
    func getProtectedFields<R>(_ role: R) throws -> Set<String> where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return getProtectedFields(roleNameAccess)
    }

    /**
     Set whether the public should not have access to specific fields of a Parse class.
     - parameter fields: The set of fields that should be protected from access.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setProtectedFieldsPublic(_ fields: Set<String>) -> Self {
        setProtected(fields, on: \.protectedFields, for: Access.publicScope.rawValue)
    }

    /**
     Set whether authenticated users should not have access to specific fields of a Parse class.
     - parameter fields: The set of fields that should be protected from access.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     - warning: Requires Parse Server 2.3.0+.
    */
    func setProtectedFieldsRequiresAuthentication(_ fields: Set<String>) -> Self {
        setProtected(fields, on: \.protectedFields, for: Access.requiresAuthentication.rawValue)
    }

    /**
     Set whether the given field that is either of `ParseUser` type or an array of `ParseUser`'s
     should not have access to specific fields of a Parse class.
     - parameter fields: The set of fields that should be protected from access.
     - parameter userField: A field in a Parse class that is either of `ParseUser` type or
     an array of `ParseUser`'s to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setProtectedFields(_ fields: Set<String>, userField: String) -> Self {
        setProtected(fields,
                     on: \.protectedFields,
                     for: Self.getUserFieldAccess(userField))
    }

    /**
     Set whether the given `ParseUser` objectId should not have access to specific fields of a Parse class.
     - parameter fields: The set of fields that should be protected from access.
     - parameter objectId: The `ParseUser` objectId to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setProtectedFields(_ fields: Set<String>, for objectId: String) -> Self {
        setProtected(fields, on: \.protectedFields, for: objectId)
    }

    /**
     Set whether the given `ParseUser` should not have access to specific fields of a Parse class.
     - parameter fields: The set of fields that should be protected from access.
     - parameter user: The `ParseUser` to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setProtectedFields<U>(_ fields: Set<String>, for user: U) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return setProtectedFields(fields, for: objectId)
    }

    /**
     Set whether the given `ParseUser` should not have access to specific fields of a Parse class.
     - parameter fields: The set of fields that should be protected from access.
     - parameter user: The `ParseUser` to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setProtectedFields<U>(_ fields: Set<String>, for user: Pointer<U>) -> Self where U: ParseUser {
        setProtectedFields(fields, for: user.objectId)
    }

    /**
     Set whether the given `ParseRole` should not have access to specific fields of a Parse class.
     - parameter fields: The set of fields that should be protected from access.
     - parameter role: The `ParseRole` to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func setProtectedFields<R>(_ fields: Set<String>, for role: R) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return setProtectedFields(fields, for: roleNameAccess)
    }

    /**
     Add to the set of specific fields the public should not have access to on a Parse class.
     - parameter fields: The set of fields that should be protected from access.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     - note: This method adds on to the current set of `fields` in the CLP.
    */
    func addProtectedFieldsPublic(_ fields: Set<String>) -> Self {
        addProtected(fields, on: \.protectedFields, for: Access.publicScope.rawValue)
    }

    /**
     Add to the set of specific fields authenticated users should not have access to on a Parse class.
     - parameter fields: The set of fields that should be protected from access.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     - note: This method adds on to the current set of `fields` in the CLP.
     - warning: Requires Parse Server 2.3.0+.
    */
    func addProtectedFieldsRequiresAuthentication(_ fields: Set<String>) -> Self {
        addProtected(fields, on: \.protectedFields, for: Access.requiresAuthentication.rawValue)
    }

    /**
     Add to the set of specific fields the given field that is either of `ParseUser` type or an array of `ParseUser`'s
     should not have access to on a Parse class.
     - parameter fields: The set of fields that should be protected from access.
     - parameter userField: A field in a Parse class that is either of `ParseUser` type or
     an array of `ParseUser`'s to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     - note: This method adds on to the current set of `fields` in the CLP.
    */
    func addProtectedFieldsUser(_ fields: Set<String>, userField: String) -> Self {
        addProtected(fields, on: \.protectedFields, for: Self.getUserFieldAccess(userField))
    }

    /**
     Add to the set of specific fields the given `ParseUser` objectId should not have access to on a Parse class.
     - parameter fields: The set of fields that should be protected from access.
     - parameter objectId: The `ParseUser` objectId to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     - note: This method adds on to the current set of `fields` in the CLP.
    */
    func addProtectedFields(_ fields: Set<String>, for objectId: String) -> Self {
        addProtected(fields, on: \.protectedFields, for: objectId)
    }

    /**
     Add to the set of specific fields the given `ParseUser` should not have access to on a Parse class.
     - parameter fields: The set of fields that should be protected from access.
     - parameter user: The `ParseUser` to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     - note: This method adds on to the current set of `fields` in the CLP.
    */
    func addProtectedFields<U>(_ fields: Set<String>, for user: U) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return addProtectedFields(fields, for: objectId)
    }

    /**
     Add to the set of specific fields the given `ParseUser` pointer should not have access to on a Parse class.
     - parameter fields: The set of fields that should be protected from access.
     - parameter user: The `ParseUser` to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - note: This method adds on to the current set of `fields` in the CLP.
    */
    func addProtectedFields<U>(_ fields: Set<String>, for user: Pointer<U>) -> Self where U: ParseUser {
        addProtectedFields(fields, for: user.objectId)
    }

    /**
     Add to the set of specific fields the given `ParseRole` should not have access to on a Parse class.
     - parameter fields: The set of fields that should be protected from access.
     - parameter role: The `ParseRole` to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     - note: This method adds on to the current set of `fields` in the CLP.
    */
    func addProtectedFields<R>(_ fields: Set<String>, for role: R) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return addProtectedFields(fields, for: roleNameAccess)
    }

    /**
     Remove the set of specific fields the public should not have access to on a Parse class.
     - parameter fields: The set of fields that should be removed from protected access.
     - parameter objectId: The `ParseUser` objectId to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     - note: This method removes from the current set of `fields` in the CLP.
    */
    func removeProtectedFieldsPublic(_ fields: Set<String>) -> Self {
        removeProtected(fields, on: \.protectedFields, for: Access.publicScope.rawValue)
    }

    /**
     Remove the set of specific fields authenticated users should not have access to
     on a Parse class.
     - parameter fields: The set of fields that should be removed from protected access.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     - note: This method removes from the current set of `fields` in the CLP.
    */
    func removeProtectedFieldsRequiresAuthentication(_ fields: Set<String>) -> Self {
        removeProtected(fields, on: \.protectedFields, for: Access.requiresAuthentication.rawValue)
    }

    /**
     Remove fields from the set of specific fields the given field that is either of `ParseUser` type
     or an array of `ParseUser`'s should not have access to on a Parse class.
     - parameter fields: The set of fields that should be removed from protected access.
     - parameter userField: A field in a Parse class that is either of `ParseUser` type or
     an array of `ParseUser`'s to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     - note: This method removes from the current set of `fields` in the CLP.
    */
    func removeProtectedFieldsUser(_ fields: Set<String>, userField: String) -> Self {
        removeProtected(fields, on: \.protectedFields, for: Self.getUserFieldAccess(userField))
    }

    /**
     Remove fields from the set of specific fields the given `ParseUser` objectId
     should not have access to on a Parse class.
     - parameter fields: The set of fields that should be removed from protected access.
     - parameter objectId: The `ParseUser` objectId to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     - note: This method removes from the current set of `fields` in the CLP.
    */
    func removeProtectedFields(_ fields: Set<String>, for objectId: String) -> Self {
        removeProtected(fields, on: \.protectedFields, for: objectId)
    }

    /**
     Remove fields from the set of specific fields the given `ParseUser` should not have access to on a Parse class.
     - parameter fields: The set of fields that should be removed from protected access.
     - parameter user: The `ParseUser` to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     - note: This method removes from the current set of `fields` in the CLP.
    */
    func removeProtectedFields<U>(_ fields: Set<String>, for user: U) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return removeProtectedFields(fields, for: objectId)
    }

    /**
     Remove fields from the set of specific fields the given `ParseUser` pointer
     should not have access to on a Parse class.
     - parameter fields: The set of fields that should be removed from protected access.
     - parameter user: The `ParseUser` to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - note: This method removes from the current set of `fields` in the CLP.
    */
    func removeProtectedFields<U>(_ fields: Set<String>, for user: Pointer<U>) -> Self where U: ParseUser {
        removeProtectedFields(fields, for: user.objectId)
    }

    /**
     Remove fields from the set of specific fields the given `ParseRole` should not have access to on a Parse class.
     - parameter fields: The set of fields that should be removed from protected access.
     - parameter role: The `ParseRole` to restrict access to.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
     - throws: An error of type `ParseError`.
     - note: This method removes from the current set of `fields` in the CLP.
    */
    func removeProtectedFields<R>(_ fields: Set<String>, for role: R) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return removeProtectedFields(fields, for: roleNameAccess)
    }
}
