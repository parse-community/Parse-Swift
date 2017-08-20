//
//  ACL.swift
//  Parse (iOS)
//
//  Created by Florent Vilmart on 17-08-19.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public struct ACL: Decodable, Encodable {
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
            return true
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

// Encoding and decoding
extension ACL {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RawCodingKey.self)
        try container.allKeys.lazy.map { (scope) -> (String, KeyedDecodingContainer<ACL.Access>) in
            return (scope.stringValue,
                    try container.nestedContainer(keyedBy: Access.self, forKey: scope))
            }.flatMap { pair -> [(String, Access, Bool)] in
                let (scope, accessValues) = pair
                return try accessValues.allKeys.flatMap { (access) -> (String, Access, Bool)? in
                    // swiftlint:disable line_length
                    guard let value = try accessValues.decodeIfPresent(Bool.self, forKey: access) else {
                    // swiftlint:enable line_length
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
