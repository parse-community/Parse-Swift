//
//  ParseRole.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/17/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

public protocol ParseRole: ParseObject {
    var name: String { get }
    var users: [String] { get }
    var roles: [String] { get }
}

// MARK: Default Implementations
public extension ParseRole {
    static var className: String {
        return "_Role"
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
}
