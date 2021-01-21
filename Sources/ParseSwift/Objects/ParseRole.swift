//
//  ParseRole.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/17/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
 Objects that conform to the `ParseRole` protocol represent a Role on the Parse Server.
 `ParseRole`'s represent groupings of `ParseUser` objects for the purposes of
 granting permissions (e.g. specifying a `ParseACL` for a `ParseObject`).
 Roles are specified by their sets of child users and child roles,
 all of which are granted any permissions that the parent role has.
 Roles must have a name (which cannot be changed after creation of the role),
 and must specify a `ParseACL`.
 */
public protocol ParseRole: ParseObject {

    /**
     Gets or sets the name for a role.
     This value must be set before the role has been saved to the server,
     and cannot be set once the role has been saved.
     - warning: A role's name can only contain alphanumeric characters, `_`, `-`, and spaces.
     */
    var name: String { get set }

    /**
     Create a `ParseRole`. It's best to use the provided initializers, `init(name: String)`
     or `init(name: String, acl: ParseACL)`. The provided initializers will overwrite
     whatever name is specified here, so you can use `self.name = ""`
     */
    init()
}

// MARK: Default Implementations
public extension ParseRole {
    static var className: String {
        "_Role"
    }

    /**
     Create a `ParseRole` with a name. The `ParseACL` will still need to be initialized before saving.
     - parameter name: The name of the Role to create.
     - throws: `ParseError` if the name has invalid characters.
     */
    init(name: String) throws {
        try Self.checkName(name)
        self.init()
    }

    /**
     Create a `ParseRole` with a name.
     - parameter name: The name of the Role to create.
     - parameter acl: The `ParseACL` for this role. Roles must have an ACL.
     A `ParseRole` is a local representation of a role persisted to the Parse Server.
     - throws: `ParseError` if the name has invalid characters.
     */
    init(name: String, acl: ParseACL) throws {
        try Self.checkName(name)
        self.init()
        self.name = name
        self.ACL = acl
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
}

// MARK: Convenience
extension ParseRole {
    var endpoint: API.Endpoint {
        if let objectId = objectId {
            return .role(objectId: objectId)
        }
        return .roles
    }

    static func checkName(_ name: String) throws {
        // swiftlint:disable:next line_length
        let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_- ")
        if name.rangeOfCharacter(from: characterset.inverted) != nil {
            throw ParseError(code: .unknownError,
                             message: "A role's name can be only contain alphanumeric characters, _, '-, and spaces.")
        }
    }
}

// MARK: ParseRelation
public extension ParseRole {

    /**
     Gets the `ParseRelation` for the `ParseUser` objects that are direct children of this role.
     These users are granted any privileges that this role has been granted
     (e.g. read or write access through `ParseACL`s). You can add or remove users from
     the role through this relation.
     */
    var users: ParseRelation<Self> {
        ParseRelation(parent: self, key: "users", className: "_User")
    }

    /**
     Gets the `ParseRelation` for the `ParseRole` objects that are direct children of this role.
     These roles' users are granted any privileges that this role has been granted
     (e.g. read or write access through `ParseACL`s). You can add or remove child roles
     from this role through this relation.
     */
    var roles: ParseRelation<Self> {
        ParseRelation(parent: self, key: "roles", className: "_Role")
    }

    /**
     Query the `ParseRelation` for the `ParseUser`'s that are direct children of this role.
     These users are granted any privileges that this role has been granted
     (e.g. read or write access through `ParseACL`s).
     */
    func queryUsers<T>(_ user: T) throws -> Query<T> where T: ParseUser {
        try users.query(user)
    }

    /**
     Query the `ParseRelation` for the `ParseRole`'s that are direct children of this role.
     These users are granted any privileges that this role has been granted
     (e.g. read or write access through `ParseACL`s).
     */
    var queryRoles: Query<Self>? {
        try? roles.query(self)
    }
}
