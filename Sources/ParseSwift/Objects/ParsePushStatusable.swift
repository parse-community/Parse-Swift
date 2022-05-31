//
//  ParsePushStatus.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/30/22.
//  Copyright © 2022 Parse Community. All rights reserved.
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
public protocol ParsePushStatusable: ParseObject {

    associatedtype QueryObject: ParseObject

    /**
     Gets or sets the name for a role.
     This value must be set before the role has been saved to the server,
     and cannot be set once the role has been saved.
     - warning: A role's name can only contain alphanumeric characters, `_`, `-`, and spaces.
     */
    var pushTime: String? { get }

    /**
     Gets the `ParseRelation` for the `ParseUser` objects that are direct children of this role.
     These users are granted any privileges that this role has been granted
     (e.g. read or write access through `ParseACL`s). You can add or remove users from
     the role through this relation.
     */
    var source: String? { get }

    /**
     Gets the `ParseRelation` for the `ParseRole` objects that are direct children of this role.
     These roles' users are granted any privileges that this role has been granted
     (e.g. read or write access through `ParseACL`s). You can add or remove child roles
     from this role through this relation.
     */
    var query: Query<QueryObject>? { get }

    var payload: String? { get }
    var title: String? { get }
    var expiry: Int? { get }
    var expirationInterval: String? { get }
    var status: String? { get }
    var numSent: Int? { get }
    var numFailed: Int? { get }
    var pushHash: String? { get }
    var errorMessage: ParseError? { get }
    var sentPerType: [String: Int]? { get }
    var failedPerType: [String: Int]? { get }
    var sentPerUTCOffset: [String: Int]? { get }
    var failedPerUTCOffset: [String: Int]? { get }
    var count: Int? { get }

    /**
     Create a an empty `ParseRole`.
     - warning: It's best to use the provided initializers, `init(name: String)`
     or `init(name: String, acl: ParseACL)` instead of `init()` as they ensure the
     `ParseRole` is setup properly.
     */
    init()
}

// MARK: Default Implementations
public extension ParsePushStatusable {
    static var className: String {
        "_PushStatus"
    }
}
