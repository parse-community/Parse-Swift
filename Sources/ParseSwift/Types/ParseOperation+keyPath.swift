//
//  ParseOperation+keyPath.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/4/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

extension ParseOperation {

    func setOriginalDataIfNeeded(_ operation: Self) -> Self {
        var mutableOperation = operation
        if mutableOperation.target.originalData == nil {
            mutableOperation.target = mutableOperation.target.mergeable
        }
        return mutableOperation
    }

    /**
     An operation that sets a field's value.
     - Parameters:
        - keyPath: The respective `KeyPath` of the object.
        - value: The value to set the `KeyPath` to.
        - returns: The updated operations.
     - warning: Do not combine operations using this method with other operations that
     do not use this method to **set** all operations. If you need to combine multiple types
     of operations such as: add, increment, forceSet, etc., use
     `func set<W>(_ key: (String, WritableKeyPath<T, W?>), value: W?)`
     instead.
     */
    public func set<W>(_ keyPath: WritableKeyPath<T, W?>,
                       value: W) throws -> Self where W: Encodable & Equatable {
        guard operations.isEmpty,
              keysToNull.isEmpty else {
            throw ParseError(code: .unknownError,
                             message: """
                                Cannot combine other operations such as: add, increment,
                                forceSet, etc., with this method. Use the \"set\" method that takes
                                the (String, WritableKeyPath) tuple as an argument instead to
                                combine multiple types of operations.
                                """)
        }
        var mutableOperation = setOriginalDataIfNeeded(self)
        mutableOperation.target[keyPath: keyPath] = value
        return mutableOperation
    }
}
