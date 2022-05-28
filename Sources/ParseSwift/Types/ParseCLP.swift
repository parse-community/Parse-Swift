//
//  ParseCLP.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/// Class Level Permissions for `ParseSchema`.
public struct ParseCLP: Codable, Equatable {

    var get: [String: AnyCodable]?
    var find: [String: AnyCodable]?
    var count: [String: AnyCodable]?
    var create: [String: AnyCodable]?
    var update: [String: AnyCodable]?
    var delete: [String: AnyCodable]?
    var addField: [String: AnyCodable]?
    public var protectedFields: [String: Set<String>]?
    public var readUserFields: Set<String>?
    public var writeUserFields: Set<String>?

    /// The avialable actions on a `ParseSchema`.
    public enum Action {
        /// Fetch `ParseObject`'s.
        case get
        /// Find `ParseObject`'s.
        case find
        /// Count `ParseObject`'s.
        case count
        /// Create new `ParseObject`'s.
        case create
        /// Update `ParseObject`'s.
        case update
        /// Delete `ParseObject`'s.
        case delete
        /// Add field to the `ParseSchema`.
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

    /// Creates an empty CLP type.
    public init() { }

    func getPointerFields(_ keyPath: KeyPath<Self, [String: AnyCodable]?>) -> Set<String> {
        self[keyPath: keyPath]?[Access.pointerFields.rawValue]?.value as? Set<String> ?? []
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
     - parameter action: Any of the following action on a `ParseSchema`:
     get/find/count/create/update/delete/addField.
     - returns: **true** if access is allowed, **false** otherwise.
    */
    func getPointerFields(_ action: Action) throws -> Set<String> {
        getPointerFields(action.keyPath())
    }

    /**
     Checks if get/find/count/create/update/delete/addField actions currently have public access.
     - parameter action: Any of the following actions on a `ParseSchema`:
     get/find/count/create/update/delete/addField.
     - returns: **true** if access is allowed, **false** otherwise.
    */
    func hasAccessPublic(_ action: Action) throws -> Bool {
        hasAccess(action.keyPath(), for: Access.publicScope.rawValue)
    }

    /**
     Checks if get/find/count/create/update/delete/addField actions currently requires authentication to access.
     - parameter action: Any of the following action on a `ParseSchema`: get/find/count/create/update/delete/addField.
     - returns: **true** if access is allowed, **false** otherwise.
     - warning: Requires Parse Server 2.3.0+.
    */
    func hasAccessRequiresAuthentication(_ action: Action) throws -> Bool {
        hasAccess(action.keyPath(), for: Access.requiresAuthentication.rawValue)
    }

    func hasAccess(_ action: Action,
                   for objectId: String) throws -> Bool {
        return hasAccess(action.keyPath(), for: objectId)
    }

    func hasAccess<U>(_ action: Action,
                      for user: U) throws -> Bool where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return hasAccess(action.keyPath(), for: objectId)
    }

    func hasAccess<U>(_ action: Action,
                      for user: Pointer<U>) throws -> Bool where U: ParseUser {
        hasAccess(action.keyPath(), for: user.objectId)
    }

    func hasAccess<R>(_ action: Action,
                      for role: R) throws -> Bool where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return hasAccess(action.keyPath(), for: roleNameAccess)
    }

    func setAccessPublic(_ allow: Bool,
                         on action: Action) -> Self {
        setAccess(allow, on: action.writableKeyPath(), for: Access.publicScope.rawValue)
    }

    /**
     - warning: Requires Parse Server 2.3.0+.
     */
    func setAccessRequiresAuthentication(_ allow: Bool,
                                         on action: Action) -> Self {
        setAccess(allow, on: action.writableKeyPath(), for: Access.requiresAuthentication.rawValue)
    }

    func setAccess(_ action: Action,
                   to allow: Bool,
                   for objectId: String) -> Self {
        setAccess(allow, on: action.writableKeyPath(), for: objectId)
    }

    func setAccess<U>(_ action: Action,
                      to allow: Bool,
                      for user: U) throws -> Self where U: ParseUser {
        let objectId = try user.toPointer().objectId
        return setAccess(allow, on: action.writableKeyPath(), for: objectId)
    }

    func setAccess<U>(_ action: Action,
                      to allow: Bool,
                      for user: Pointer<U>) -> Self where U: ParseUser {
        setAccess(allow, on: action.writableKeyPath(), for: user.objectId)
    }

    func setAccess<R>(_ action: Action,
                      to allow: Bool,
                      for role: R) throws -> Self where R: ParseRole {
        let roleNameAccess = try ParseACL.getRoleAccessName(role)
        return setAccess(allow, on: action.writableKeyPath(), for: roleNameAccess)
    }

    /**
     Set access to a **\_User** column or array **\_User** column in this Schema.
     - warning: Requires Parse Server 3.1.1+.
     */
    func setPointerFields(_ action: Action,
                          to fields: Set<String>) -> Self {
        setPointer(fields, on: action.writableKeyPath())
    }

    func addPointerFields(_ fields: Set<String>,
                          on action: Action) -> Self {
        addPointer(fields, on: action.writableKeyPath())
    }

    func removePointerFields(_ fields: Set<String>,
                             on action: Action) -> Self {
        removePointer(fields, on: action.writableKeyPath())
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
            .setAccess(allow, on: \.create, for: objectId)
            .setAccess(allow, on: \.update, for: objectId)
            .setAccess(allow, on: \.delete, for: objectId)
        if addField {
            updatedCLP = updatedCLP.setAccess(allow, on: \.addField, for: objectId)
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
            .setAccess(allow, on: \.get, for: objectId)
            .setAccess(allow, on: \.find, for: objectId)
            .setAccess(allow, on: \.count, for: objectId)
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

// MARK: Protected
public extension ParseClassLevelPermisioinable {
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
        setProtected(fields, on: \.protectedFields, for: objectId)
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
        addProtected(fields, on: \.protectedFields, for: objectId)
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
        removeProtected(fields, on: \.protectedFields, for: objectId)
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
extension ParseCLP {
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
public extension ParseCLP {

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
public extension ParseCLP {

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
