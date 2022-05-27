//
//  ParseCLPPointer.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/27/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/// Class Level Permissions for `ParseSchema`.
public struct ParseCLPPointer: ParseClassLevelPermisioinable {

    public var get: [String: Set<String>]?
    public var find: [String: Set<String>]?
    public var count: [String: Set<String>]?
    public var create: [String: Set<String>]?
    public var update: [String: Set<String>]?
    public var delete: [String: Set<String>]?
    public var addField: [String: Set<String>]?
    public var protectedFields: [String: Set<String>]?
    public var readUserFields: Set<String>?
    public var writeUserFields: Set<String>?

    /// Creates an empty CLP type.
    public init() { }
}

public extension ParseCLPPointer {

    func getPointer(_ keyPath: KeyPath<Self, [String: Set<String>]?>) -> Set<String> {
        self[keyPath: keyPath]?[ParseCLP.Access.pointerFields.rawValue] ?? []
    }

    func setPointer(_ keyPath: WritableKeyPath<Self, [String: Set<String>]?>,
                    fields: Set<String>) -> Self {
        var mutableCLP = self
        if mutableCLP[keyPath: keyPath] != nil {
            mutableCLP[keyPath: keyPath]?[ParseCLP.Access.pointerFields.rawValue] = fields
        } else {
            mutableCLP[keyPath: keyPath] = [ParseCLP.Access.pointerFields.rawValue: fields]
        }
        return mutableCLP
    }

    func addPointer(_ keyPath: WritableKeyPath<Self, [String: Set<String>]?>,
                    fields: Set<String>) -> Self {
        var mutableCLP = self
        if let currentSet = mutableCLP[keyPath: keyPath]?[ParseCLP.Access.pointerFields.rawValue] {
            mutableCLP[keyPath: keyPath]?[ParseCLP.Access.pointerFields.rawValue] = currentSet.union(fields)
        } else {
            mutableCLP[keyPath: keyPath] = [ParseCLP.Access.pointerFields.rawValue: fields]
        }
        return mutableCLP
    }
}
