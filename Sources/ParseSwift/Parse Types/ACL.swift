//
//  ACL.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-19.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

/**
 The `ACL` class is used to control which users can access or modify a particular object.
 Each `ParseObject` can have its own `ACL`. You can grant read and write permissions separately to specific users,
 to groups of users that belong to roles, or you can grant permissions to "the public" so that,
 for example, any user could read a particular object but only a particular set of users could write to that object.
*/
public struct ACL: Codable, Equatable {
    private static let publicScope = "*"
    private var acl: [String: [Access: Bool]]?

    // Enum for accesses
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
            return get(ACL.publicScope, access: .read)
        }
        set {
            set(ACL.publicScope, access: .read, value: newValue)
        }
    }

    /**
     Controls whether the public is allowed to write this object.
    */
    public var publicWrite: Bool {
        get {
            return get(ACL.publicScope, access: .write)
        }
        set {
            set(ACL.publicScope, access: .write, value: newValue)
        }
    }

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
    
     - parameter userId The `ParseObject.objectId` of the user for which to retrive access.
     - returns: `true` if the user with this `objectId` has *explicit* read access, otherwise `false`.
    */
    public func getReadAccess(userId: String) -> Bool {
        return get(userId, access: .read)
    }

    /**
     Gets whether the given user id is *explicitly* allowed to write this object.
     Even if this returns false, the user may still be able to write it if `publicWriteAccess` returns `true`
     or if the user belongs to a role that has access.
    
     - parameter userId The `ParseObject.objectId` of the user for which to retrive access.
    
     - returns: `true` if the user with this `ParseObject.objectId` has *explicit* write access, otherwise `false`.
    */
    public func getWriteAccess(userId: String) -> Bool {
        return get(userId, access: .write)
    }

    /**
     Set whether the given user id is allowed to read this object.
    
     - parameter allowed Whether the given user can write this object.
     - parameter userId The `ParseObject.objectId` of the user to assign access.
    */
    public mutating func setReadAccess(userId: String, value: Bool) {
        set(userId, access: .read, value: value)
    }

    /**
     Set whether the given user id is allowed to write this object.
     
     - parameter allowed Whether the given user can read this object.
     - parameter userId The `ParseObject.objectId` of the user to assign access.
    */
    public mutating func setWriteAccess(userId: String, value: Bool) {
        set(userId, access: .write, value: value)
    }

    /**
     Get whether users belonging to the role with the given name are allowed to read this object.
     Even if this returns `false`, the role may still be able to read it if a parent role has read access.
    
     - parameter name The name of the role.
    
     - returns: `true` if the role has read access, otherwise `false`.
    */
    public func getReadAccess(roleName: String) -> Bool {
        return get(toRole(roleName: roleName), access: .read)
    }

    /**
     Get whether users belonging to the role with the given name are allowed to write this object.
     Even if this returns `false`, the role may still be able to write it if a parent role has write access.
    
     - parameter name The name of the role.
    
     - returns: `true` if the role has read access, otherwise `false`.
    */
    public func getWriteAccess(roleName: String) -> Bool {
        return get(toRole(roleName: roleName), access: .write)
    }

    /**
     Set whether users belonging to the role with the given name are allowed to read this object.
    
     - parameter allowed Whether the given role can read this object.
     - parameter name The name of the role.
    */
    public mutating func setReadAccess(roleName: String, value: Bool) {
        set(toRole(roleName: roleName), access: .read, value: value)
    }

    /**
     Set whether users belonging to the role with the given name are allowed to write this object.
    
     - parameter allowed Whether the given role can write this object.
     - parameter name The name of the role.
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
extension ACL {
    /**
     Get the default ACL from the Keychain.
     
     - returns: Returns the default ACL.
    */
    public static func defaultACL() throws -> Self {

        let currentUser = BaseParseUser.current
        var aclController: DefaultACL? =
            try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.defaultACL)

        if aclController != nil {
            if !aclController!.useCurrentUser {
                return aclController!.defaultACL
            }
        } else {
            aclController = DefaultACL(defaultACL: ACL(),
                                                 lastCurrentUser: currentUser, useCurrentUser: true)
        }

        do {
            guard let userObjectId = currentUser?.objectId else {
                return aclController!.defaultACL
            }

            guard let lastCurrentUserObjectId = aclController!.lastCurrentUser?.objectId else {
                try setDefaultAccess(userObjectId)
                return aclController!.defaultACL
            }

            if userObjectId != lastCurrentUserObjectId {
                try setDefaultAccess(userObjectId)
            }
            return aclController!.defaultACL

        } catch {
            throw error
        }
    }

    /**
     Sets a default ACL that will be applied to all instances of `ParseObject` when they are created.
    
     - parameter acl The ACL to use as a template for all instance of `ParseObject`
     created after this method has been called.
     This value will be copied and used as a template for the creation of new ACLs, so changes to the
     instance after this method has been called will not be reflected in new instance of `ParseObject`.
     - parameter currentUserAccess - If `true`, the `ParseACL` that is applied to
     newly-created instance of `ParseObject` will
     provide read and write access to the `ParseUser.+currentUser` at the time of creation.
     - If `false`, the provided `acl` will be used without modification.
     - If `acl` is `nil`, this value is ignored.
    */
    public static func setDefaultACL(_ acl: ACL, withAccessForCurrentUser: Bool) throws {

        let currentUser = BaseParseUser.current
        let aclController
            = DefaultACL(defaultACL: acl, lastCurrentUser: currentUser, useCurrentUser: withAccessForCurrentUser)

        try? KeychainStore.shared.set(aclController, for: ParseStorage.Keys.defaultACL)
    }

    private static func setDefaultAccess(_ userObjectId: String?) throws {
        guard let userObjectId = userObjectId else {
            return
        }
        var acl = ACL()
        acl.setReadAccess(userId: userObjectId, value: true)
        acl.setWriteAccess(userId: userObjectId, value: true)
        do {
            try setDefaultACL(acl, withAccessForCurrentUser: true)
        } catch {
            throw error
        }
    }
}

// Encoding and decoding
extension ACL {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RawCodingKey.self)
        try container.allKeys.lazy.map { (scope) -> (String, KeyedDecodingContainer<ACL.Access>) in
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

extension ACL: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let descriptionData = try? JSONEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
            return "ACL ()"
        }
        return "ACL (\(descriptionString))"
    }
}

struct DefaultACL: Codable {
    var defaultACL: ACL
    var lastCurrentUser: BaseParseUser?
    var useCurrentUser: Bool
}
