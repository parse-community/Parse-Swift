//
//  ACL.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-19.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

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

    public var publicRead: Bool {
        get {
            return get(ACL.publicScope, access: .read)
        }
        set {
            set(ACL.publicScope, access: .read, value: newValue)
        }
    }

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

    public func getReadAccess(userId: String) -> Bool {
        return get(userId, access: .read)
    }

    public func getWriteAccess(userId: String) -> Bool {
        return get(userId, access: .write)
    }

    public mutating func setReadAccess(userId: String, value: Bool) {
        set(userId, access: .read, value: value)
    }

    public mutating func setWriteAccess(userId: String, value: Bool) {
        set(userId, access: .write, value: value)
    }

    public func getReadAccess(roleName: String) -> Bool {
        return get(toRole(roleName: roleName), access: .read)
    }

    public func getWriteAccess(roleName: String) -> Bool {
        return get(toRole(roleName: roleName), access: .write)
    }

    public mutating func setReadAccess(roleName: String, value: Bool) {
        set(toRole(roleName: roleName), access: .read, value: value)
    }

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
    public static func defaultACL() throws -> Self {

        guard let currentUser: CurrentUserContainer<BaseParseUser> =
            try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
            let userObjectId = currentUser.currentUser?.objectId else {
                throw ParseError(code: .objectNotFound, message: "Couldn't retreive currentUser from Keychain")
        }

        var aclController: DefaultACLController? =
            try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.defaultACL)

        if aclController != nil {
            if !aclController!.useCurrentUser {
                return aclController!.defaultACL
            }
        } else {
            aclController = DefaultACLController(defaultACL: ACL(),
                                                 lastCurrentUser: currentUser.currentUser, useCurrentUser: true)
        }

        do {
            if let lastCurrentUserObjectId = aclController!.lastCurrentUser?.objectId {
                if userObjectId != lastCurrentUserObjectId {
                    try setDefaultAccess(userObjectId)
                }
            } else {
                try setDefaultAccess(userObjectId)
            }
            return aclController!.defaultACL
        } catch {
            throw error
        }
    }

    public static func setDefaultACL(_ acl: ACL, withAccessForCurrentUser: Bool) throws {
        guard let currentUser: CurrentUserContainer<BaseParseUser> =
            try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
            let user = currentUser.currentUser else {
                throw ParseError(code: .objectNotFound, message: "Couldn't retrieve currentUseer from Keychain")
        }
        let aclController
            = DefaultACLController(defaultACL: acl, lastCurrentUser: user, useCurrentUser: withAccessForCurrentUser)

        try? KeychainStore.shared.set(aclController, for: ParseStorage.Keys.defaultACL)
    }

    private static func setDefaultAccess(_ userObjectId: String) throws {
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

struct DefaultACLController: Codable {
    var defaultACL: ACL
    var lastCurrentUser: BaseParseUser?
    var useCurrentUser: Bool
}
