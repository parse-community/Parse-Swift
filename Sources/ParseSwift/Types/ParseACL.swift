//
//  ParseACL.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-19.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

/**
 `ParseACL` is used to control which users can access or modify a particular `ParseObject`.
 Each `ParseObject` has its own ACL. You can grant read and write permissions separately 
 to specific users, to groups of users that belong to roles, or you can grant permissions to
 "the public" so that, for example, any user could read a particular object but only a 
 particular set of users could write to that object.
*/
public struct ParseACL: Codable, Equatable, Hashable {
    private static let publicScope = "*"
    private var acl: [String: [Access: Bool]]?

    /**
     An enum specifying read and write access controls.
    */
    public enum Access: String, Codable, CodingKey {
        case read
        case write

        public init(from decoder: Decoder) throws {
            self = Access(rawValue: try decoder.singleValueContainer().decode(String.self))!
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    public init() {}

    /**
     Controls whether the public is allowed to read this object.
    */
    public var publicRead: Bool {
        get {
            return get(ParseACL.publicScope, access: .read)
        }
        set {
            set(ParseACL.publicScope, access: .read, value: newValue)
        }
    }

    /**
     Controls whether the public is allowed to write this object.
    */
    public var publicWrite: Bool {
        get {
            return get(ParseACL.publicScope, access: .write)
        }
        set {
            set(ParseACL.publicScope, access: .write, value: newValue)
        }
    }

    /**
     Returns true if a particular key has a specific access level.
     - parameter key: The `ParseObject.objectId` of the user for which to retrieve access.
     - parameter access: The type of access.
     - returns: `true` if the user with this `key` has *explicit* access, otherwise `false`.
    */
    public func get(_ key: String, access: Access) -> Bool {
        guard let acl = acl else { // no acl, all open!
            return false
        }
        return acl[key]?[access] ?? false
    }

    /**
     Gets whether the given user id is *explicitly* allowed to read this object.
     Even if this returns `false`, the user may still be able to access it if `publicReadAccess` returns `true`
     or if the user belongs to a role that has access.

     - parameter userId: The `ParseObject.objectId` of the user for which to retrieve access.
     - returns: `true` if the user with this `objectId` has *explicit* read access, otherwise `false`.
    */
    public func getReadAccess(userId: String) -> Bool {
        return get(userId, access: .read)
    }

    /**
     Gets whether the given user id is *explicitly* allowed to write this object.
     Even if this returns false, the user may still be able to write it if `publicWriteAccess` returns `true`
     or if the user belongs to a role that has access.

     - parameter userId: The `ParseObject.objectId` of the user for which to retrieve access.

     - returns: `true` if the user with this `ParseObject.objectId` has *explicit* write access, otherwise `false`.
    */
    public func getWriteAccess(userId: String) -> Bool {
        return get(userId, access: .write)
    }

    /**
     Set whether the given `userId` is allowed to read this object.

     - parameter value: Whether the given user can write this object.
     - parameter userId: The `ParseObject.objectId` of the user to assign access.
    */
    public mutating func setReadAccess(userId: String, value: Bool) {
        set(userId, access: .read, value: value)
    }

    /**
     Set whether the given `userId` is allowed to write this object.

     - parameter value: Whether the given user can read this object.
     - parameter userId: The `ParseObject.objectId` of the user to assign access.
    */
    public mutating func setWriteAccess(userId: String, value: Bool) {
        set(userId, access: .write, value: value)
    }

    /**
     Get whether users belonging to the role with the given name are allowed to read this object.
     Even if this returns `false`, the role may still be able to read it if a parent role has read access.

     - parameter roleName: The name of the role.

     - returns: `true` if the role has read access, otherwise `false`.
    */
    public func getReadAccess(roleName: String) -> Bool {
        return get(toRole(roleName: roleName), access: .read)
    }

    /**
     Get whether users belonging to the role with the given name are allowed to write this object.
     Even if this returns `false`, the role may still be able to write it if a parent role has write access.

     - parameter roleName: The name of the role.

     - returns: `true` if the role has read access, otherwise `false`.
    */
    public func getWriteAccess(roleName: String) -> Bool {
        return get(toRole(roleName: roleName), access: .write)
    }

    /**
     Set whether users belonging to the role with the given name are allowed to read this object.

     - parameter value: Whether the given role can read this object.
     - parameter roleName: The name of the role.
    */
    public mutating func setReadAccess(roleName: String, value: Bool) {
        set(toRole(roleName: roleName), access: .read, value: value)
    }

    /**
     Set whether users belonging to the role with the given name are allowed to write this object.

     - parameter allowed: Whether the given role can write this object.
     - parameter roleName: The name of the role.
    */
    public mutating func setWriteAccess(roleName: String, value: Bool) {
        set(toRole(roleName: roleName), access: .write, value: value)
    }

    private func toRole(roleName: String) -> String {
        return "role:\(roleName)"
    }

    private mutating func set(_ key: String, access: Access, value: Bool) {
        // initialized the backing dictionary if needed
        if acl == nil && value { // do not create if value is false (no-op)
            acl = [:]
        }
        // initialize the scope dictionary
        if acl?[key] == nil && value { // do not create if value is false (no-op)
            acl?[key] = [:]
        }
        if value {
            acl?[key]?[access] = value
        } else {
            acl?[key]?.removeValue(forKey: access)
            if acl?[key]?.isEmpty == true {
                acl?.removeValue(forKey: key)
            }
            if acl?.isEmpty == true {
                acl = nil // cleanup
            }
        }
    }
}

// Default ACL
extension ParseACL {
    /**
     Get the default ACL from the Keychain.

     - returns: Returns the default ACL.
    */
    public static func defaultACL() throws -> Self {

        let currentUser = BaseParseUser.current
        let aclController: DefaultACL? =
            try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.defaultACL)

        if aclController != nil {
            if !aclController!.useCurrentUser {
                return aclController!.defaultACL
            } else {
                guard let userObjectId = currentUser?.objectId else {
                    return aclController!.defaultACL
                }

                guard let lastCurrentUserObjectId = aclController!.lastCurrentUser?.objectId,
                    userObjectId == lastCurrentUserObjectId else {
                    return try setDefaultACL(ParseACL(), withAccessForCurrentUser: true)
                }

                return aclController!.defaultACL
            }
        }

        return try setDefaultACL(ParseACL(), withAccessForCurrentUser: true)
    }

    /**
     Sets a default ACL that will be applied to all instances of `ParseObject` when they are created.

     - parameter acl: The ACL to use as a template for all instances of `ParseObject` created
     after this method has been called.

     This value will be copied and used as a template for the creation of new ACLs, so changes to the
     instance after this method has been called will not be reflected in new instance of `ParseObject`.

     - parameter withAccessForCurrentUser: If `true`, the `ACL` that is applied to
     newly-created instance of `ParseObject` will
     provide read and write access to the `ParseUser.+currentUser` at the time of creation.
     - If `false`, the provided `acl` will be used without modification.
     - If `acl` is `nil`, this value is ignored.
     
     - returns: Updated defaultACL
    */
    public static func setDefaultACL(_ acl: ParseACL, withAccessForCurrentUser: Bool) throws -> ParseACL {

        let currentUser = BaseParseUser.current

        let modifiedACL: ParseACL?
        if withAccessForCurrentUser {
            modifiedACL = setDefaultAccess(acl)
        } else {
            modifiedACL = acl
        }

        let aclController: DefaultACL!
        if modifiedACL != nil {
            aclController = DefaultACL(defaultACL: modifiedACL!,
                                       lastCurrentUser: currentUser, useCurrentUser: withAccessForCurrentUser)
        } else {
            aclController =
                DefaultACL(defaultACL: acl, lastCurrentUser: currentUser, useCurrentUser: withAccessForCurrentUser)
        }

        try? KeychainStore.shared.set(aclController, for: ParseStorage.Keys.defaultACL)

        return aclController.defaultACL
    }

    private static func setDefaultAccess(_ acl: ParseACL) -> ParseACL? {
        guard let userObjectId = BaseParseUser.current?.objectId else {
            return nil
        }
        var modifiedACL = acl
        modifiedACL.setReadAccess(userId: userObjectId, value: true)
        modifiedACL.setWriteAccess(userId: userObjectId, value: true)

        return modifiedACL
    }
}

// Encoding and decoding
extension ParseACL {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RawCodingKey.self)
        try container.allKeys.lazy.map { (scope) -> (String, KeyedDecodingContainer<ParseACL.Access>) in
            return (scope.stringValue,
                    try container.nestedContainer(keyedBy: Access.self, forKey: scope))
            }.flatMap { pair -> [(String, Access, Bool)] in
                let (scope, accessValues) = pair
                return try accessValues.allKeys.compactMap { (access) -> (String, Access, Bool)? in
                    guard let value = try accessValues.decodeIfPresent(Bool.self, forKey: access) else {
                        return nil
                    }
                    return (scope, access, value)
                }
            }.forEach {
                set($0, access: $1, value: $2)
            }
    }

    public func encode(to encoder: Encoder) throws {
        guard let acl = acl else { return } // only encode if acl is present
        var container = encoder.container(keyedBy: RawCodingKey.self)
        try acl.forEach { pair in
            let (scope, values) = pair
            var nestedContainer = container.nestedContainer(keyedBy: Access.self,
                                                            forKey: .key(scope))
            try values.forEach { (pair) in
                let (access, value) = pair
                try nestedContainer.encode(value, forKey: access)
            }
        }
    }

}

extension ParseACL: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
            return "ACL ()"
        }
        return "ACL (\(descriptionString))"
    }
}

struct DefaultACL: Codable {
    var defaultACL: ParseACL
    var lastCurrentUser: BaseParseUser?
    var useCurrentUser: Bool
}
