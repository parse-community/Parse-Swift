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
public struct ParseACL: ParseType,
                        Decodable,
                        Equatable,
                        Hashable {
    private static let publicScope = "*"
    private var acl: [String: [Access: Bool]]?

    /**
     An enum specifying read and write access controls.
    */
    public enum Access: String, Codable, CodingKey {
        /// Read access control.
        case read
        /// Write access control.
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
     - parameter key: The key of the `ParseUser` or `ParseRole` for which to retrieve access.
     - parameter access: The type of access.
     - returns: `true` if the `key` has *explicit* access, otherwise `false`.
    */
    func get(_ key: String, access: Access) -> Bool {
        guard let acl = acl else { // no acl, all open!
            return false
        }
        return acl[key]?[access] ?? false
    }

    // MARK: ParseUser
    /**
     Gets whether the given `objectId` is *explicitly* allowed to read this object.
     Even if this returns `false`, the user may still be able to access it if `publicReadAccess` returns `true`
     or if the user belongs to a role that has access.

     - parameter objectId: The `ParseUser.objectId` of the user for which to retrieve access.
     - returns: `true` if the user with this `objectId` has *explicit* read access, otherwise `false`.
    */
    public func getReadAccess(objectId: String) -> Bool {
        get(objectId, access: .read)
    }

    /**
     Gets whether the given `ParseUser` is *explicitly* allowed to read this object.
     Even if this returns `false`, the user may still be able to access it if `publicReadAccess` returns `true`
     or if the user belongs to a role that has access.

     - parameter user: The `ParseUser` for which to retrieve access.
     - returns: `true` if the user with this `ParseUser` has *explicit* read access, otherwise `false`.
    */
    public func getReadAccess<T>(user: T) -> Bool where T: ParseUser {
        if let objectId = user.objectId {
            return get(objectId, access: .read)
        } else {
            return false
        }
    }

    /**
     Gets whether the given `objectId` is *explicitly* allowed to write this object.
     Even if this returns false, the user may still be able to write it if `publicWriteAccess` returns `true`
     or if the user belongs to a role that has access.

     - parameter objectId: The `ParseUser.objectId` of the user for which to retrieve access.
     - returns: `true` if the user with this `ParseUser.objectId` has *explicit* write access, otherwise `false`.
    */
    public func getWriteAccess(objectId: String) -> Bool {
        return get(objectId, access: .write)
    }

    /**
     Gets whether the given `ParseUser` is *explicitly* allowed to write this object.
     Even if this returns false, the user may still be able to write it if `publicWriteAccess` returns `true`
     or if the user belongs to a role that has access.

     - parameter user: The `ParseUser` of the user for which to retrieve access.
     - returns: `true` if the `ParseUser` has *explicit* write access, otherwise `false`.
    */
    public func getWriteAccess<T>(user: T) -> Bool where T: ParseUser {
        if let objectId = user.objectId {
            return get(objectId, access: .write)
        } else {
            return false
        }
    }

    /**
     Set whether the given `objectId` is allowed to read this object.

     - parameter value: Whether the given user can read this object.
     - parameter objectId: The `ParseUser.objectId` of the user to assign access.
    */
    public mutating func setReadAccess(objectId: String, value: Bool) {
        set(objectId, access: .read, value: value)
    }

    /**
     Set whether the given `ParseUser` is allowed to read this object.

     - parameter value: Whether the given user can read this object.
     - parameter user: The `ParseUser` to assign access.
    */
    public mutating func setReadAccess<T>(user: T, value: Bool) where T: ParseUser {
        if let objectId = user.objectId {
            set(objectId, access: .read, value: value)
        }
    }

    /**
     Set whether the given `objectId` is allowed to write this object.

     - parameter value: Whether the given user can write this object.
     - parameter objectId: The `ParseUser.objectId` of the user to assign access.
    */
    public mutating func setWriteAccess(objectId: String, value: Bool) {
        set(objectId, access: .write, value: value)
    }

    /**
     Set whether the given `ParseUser` is allowed to write this object.

     - parameter value: Whether the given user can write this object.
     - parameter user: The `ParseUser` to assign access.
    */
    public mutating func setWriteAccess<T>(user: T, value: Bool) where T: ParseUser {
        if let objectId = user.objectId {
            set(objectId, access: .write, value: value)
        }
    }

    // MARK: ParseRole

    /**
     Get whether users belonging to the role with the given name are allowed to read this object.
     Even if this returns `false`, the role may still be able to read it if a parent role has read access.

     - parameter roleName: The name of the role.
     - returns: `true` if the role has read access, otherwise `false`.
    */
    public func getReadAccess(roleName: String) -> Bool {
        get(toRole(roleName: roleName), access: .read)
    }

    /**
     Get whether users belonging to the role are allowed to read this object.
     Even if this returns `false`, the role may still be able to read it if a parent role has read access.

     - parameter role: The `ParseRole` to get access for.
     - returns: `true` if the `ParseRole` has read access, otherwise `false`.
    */
    public func getReadAccess<T>(role: T) -> Bool where T: ParseRole {
        get(toRole(roleName: role.name), access: .read)
    }

    /**
     Get whether users belonging to the role with the given name are allowed to write this object.
     Even if this returns `false`, the role may still be able to write it if a parent role has write access.

     - parameter roleName: The name of the role.
     - returns: `true` if the role has read access, otherwise `false`.
    */
    public func getWriteAccess(roleName: String) -> Bool {
        get(toRole(roleName: roleName), access: .write)
    }

    /**
     Get whether users belonging to the role are allowed to write this object.
     Even if this returns `false`, the role may still be able to write it if a parent role has write access.

     - parameter role: The `ParseRole` to get access for.
     - returns: `true` if the role has read access, otherwise `false`.
    */
    public func getWriteAccess<T>(role: T) -> Bool where T: ParseRole {
        get(toRole(roleName: role.name), access: .write)
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
     Set whether users belonging to the role are allowed to read this object.

     - parameter value: Whether the given role can read this object.
     - parameter role: The `ParseRole` to set access for.
    */
    public mutating func setReadAccess<T>(role: T, value: Bool) where T: ParseRole {
        set(toRole(roleName: role.name), access: .read, value: value)
    }

    /**
     Set whether users belonging to the role with the given name are allowed to write this object.

     - parameter allowed: Whether the given role can write this object.
     - parameter roleName: The name of the role.
    */
    public mutating func setWriteAccess(roleName: String, value: Bool) {
        set(toRole(roleName: roleName), access: .write, value: value)
    }

    /**
     Set whether users belonging to the role are allowed to write this object.

     - parameter allowed: Whether the given role can write this object.
     - parameter role: The `ParseRole` to set access for.
    */
    public mutating func setWriteAccess<T>(role: T, value: Bool) where T: ParseRole {
        set(toRole(roleName: role.name), access: .write, value: value)
    }

    private func toRole(roleName: String) -> String {
        "role:\(roleName)"
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

        let aclController: DefaultACL?

        #if !os(Linux) && !os(Android)
        aclController = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.defaultACL)
        #else
        aclController = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.defaultACL)
        #endif

        if let acl = aclController {
            if !acl.useCurrentUser {
                return acl.defaultACL
            } else {
                guard let userObjectId = BaseParseUser.current?.objectId else {
                    return acl.defaultACL
                }

                guard let lastCurrentUserObjectId = acl.lastCurrentUserObjectId,
                    userObjectId == lastCurrentUserObjectId else {
                    return try setDefaultACL(ParseACL(), withAccessForCurrentUser: true)
                }

                return acl.defaultACL
            }
        }

        return try setDefaultACL(ParseACL(), withAccessForCurrentUser: true)
    }

    /**
     Sets a default ACL that can later be used by `ParseObjects`.
     
     To apply the default ACL to all instances of a respective `ParseObject` when they are created,
     you will need to add `ACL = try? ParseACL.defaultACL()`. You can also at it when
     conforming to `ParseObject`:
     
         struct MyParseObject: ParseObject {
     
            var objectId: String?
            var createdAt: Date?
            var updatedAt: Date?
            var ACL: ParseACL? = try? ParseACL.defaultACL()
         }

     - parameter acl: The ACL to use as a template for instances of `ParseObject`.

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

        guard let currentUser = BaseParseUser.current,
            let currentUserObjectId = currentUser.objectId else {
            throw ParseError(code: .missingObjectId, message: "Can't set defaultACL with no current user")
        }

        let modifiedACL: ParseACL?
        if withAccessForCurrentUser {
            modifiedACL = setDefaultAccess(acl, user: currentUser)
        } else {
            modifiedACL = acl
        }

        let aclController: DefaultACL!
        if let modified = modifiedACL {
            aclController = DefaultACL(defaultACL: modified,
                                       lastCurrentUserObjectId: currentUserObjectId,
                                       useCurrentUser: withAccessForCurrentUser)
        } else {
            aclController =
                DefaultACL(defaultACL: acl,
                           lastCurrentUserObjectId: currentUserObjectId,
                           useCurrentUser: withAccessForCurrentUser)
        }

        #if !os(Linux) && !os(Android)
        try KeychainStore.shared.set(aclController, for: ParseStorage.Keys.defaultACL)
        #else
        try ParseStorage.shared.set(aclController, for: ParseStorage.Keys.defaultACL)
        #endif
        return aclController.defaultACL
    }

    private static func setDefaultAccess<T>(_ acl: ParseACL, user: T) -> ParseACL? where T: ParseUser {
        var modifiedACL = acl
        modifiedACL.setReadAccess(user: user, value: true)
        modifiedACL.setWriteAccess(user: user, value: true)

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

// MARK: CustomDebugStringConvertible
extension ParseACL: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
            return "ACL ()"
        }
        return "ACL (\(descriptionString))"
    }
}

// MARK: CustomStringConvertible
extension ParseACL: CustomStringConvertible {
    public var description: String {
        debugDescription
    }
}

struct DefaultACL: Codable {
    var defaultACL: ParseACL
    var lastCurrentUserObjectId: String?
    var useCurrentUser: Bool
}
