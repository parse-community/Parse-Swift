//
//  ParseOperation+keyPath.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/4/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

extension ParseOperation {
    
    /**
     An operation that sets a field's value if it has changed from its previous value.
     - Parameters:
        - key: A tuple consisting of the key and the respective KeyPath of the object.
        - value: The value to set it to.
        - returns: The updated operations.
     - Note: Set the value to "nil" if you want it to be "null" on the Parse Server.
     */
    public func set<W>(_ keyPath: WritableKeyPath<T, W?>,
                       value: W?) -> Self where W: Encodable {
        var mutableOperation = self
        if value == nil && target[keyPath: keyPath] != nil {
            mutableOperation.keyPathsToNull.insert(keyPath)
            mutableOperation.target[keyPath: keyPath] = value
        } else if !target[keyPath: keyPath].isEqual(value) {
            mutableOperation.target[keyPath: keyPath] = value
        }
        return mutableOperation
    }
}
