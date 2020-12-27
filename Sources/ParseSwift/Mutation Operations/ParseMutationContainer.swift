//
//  ParseMutationContainer.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public struct ParseMutationContainer<T>: Encodable where T: ParseObject {
    typealias ObjectType = T

    var target: T
    private var operations = [String: Encodable]()

    init(target: T) {
        self.target = target
    }

    /**
     An operation that increases a numeric field's value by a given amount.
     */
    public mutating func increment(_ key: String, by amount: Int) {
        operations[key] = IncrementOperation(amount: amount)
    }
    
    /**
     An operation that adds a new element to an array field,
     only if it wasn't already present.
     */
    public mutating func addUnique<W>(_ key: String, objects: [W]) where W: Encodable, W: Hashable {
        operations[key] = AddUniqueOperation(objects: objects)
    }
    
    /**
     An operation that adds a new element to an array field,
     only if it wasn't already present.
     */
    public mutating func addUnique<V>(_ key: (String, WritableKeyPath<T, [V]>),
                                      objects: [V]) where V: Encodable, V: Hashable {
        operations[key.0] = AddUniqueOperation(objects: objects)
        var values = target[keyPath: key.1]
        values.append(contentsOf: objects)
        target[keyPath: key.1] = Array(Set<V>(values))
    }
    
    /**
     An operation that adds a new element to an array field,
     only if it wasn't already present.
     */
    public mutating func addUnique<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                                      objects: [V]) where V: Encodable, V: Hashable {
        operations[key.0] = AddUniqueOperation(objects: objects)
        var values = target[keyPath: key.1] ?? []
        values.append(contentsOf: objects)
        target[keyPath: key.1] = Array(Set<V>(values))
    }

    /**
     An operation that adds a new element to an array field.
     */
    public mutating func add<W>(_ key: String, objects: [W]) where W: Encodable {
        operations[key] = AddOperation(objects: objects)
    }

    /**
     An operation that adds a new element to an array field.
     */
    public mutating func add<V>(_ key: (String, WritableKeyPath<T, [V]>),
                                objects: [V]) where V: Encodable {
        operations[key.0] = AddOperation(objects: objects)
        var values = target[keyPath: key.1]
        values.append(contentsOf: objects)
        target[keyPath: key.1] = values
    }

    /**
     An operation that adds a new element to an array field.
     */
    public mutating func add<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                                objects: [V]) where V: Encodable {
        operations[key.0] = AddOperation(objects: objects)
        var values = target[keyPath: key.1] ?? []
        values.append(contentsOf: objects)
        target[keyPath: key.1] = values
    }

    /**
     An operation that removes every instance of an element from
     an array field.
     */
    public mutating func remove<W>(_ key: String, objects: [W]) where W: Encodable {
        operations[key] = RemoveOperation(objects: objects)
    }

    /**
     An operation that removes every instance of an element from
     an array field.
     */
    public mutating func remove<V>(_ key: (String, WritableKeyPath<T, [V]>),
                                   objects: [V]) where V: Encodable, V: Hashable {
        operations[key.0] = RemoveOperation(objects: objects)
        let values = target[keyPath: key.1]
        var set = Set<V>(values)
        objects.forEach {
            set.remove($0)
        }
        target[keyPath: key.1] = Array(set)
    }

    /**
     An operation that removes every instance of an element from
     an array field.
     */
    public mutating func remove<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                                   objects: [V]) where V: Encodable, V: Hashable {
        operations[key.0] = RemoveOperation(objects: objects)
        let values = target[keyPath: key.1]
        var set = Set<V>(values ?? [])
        objects.forEach {
            set.remove($0)
        }
        target[keyPath: key.1] = Array(set)
    }

    /**
     An operation where a field is deleted from the object.
     */
    public mutating func unset(_ key: String) {
        operations[key] = DeleteOperation()
    }

    /**
     An operation where a field is deleted from the object.
     */
    public mutating func unset<V>(_ key: (String, WritableKeyPath<T, V?>)) where V: Encodable {
        operations[key.0] = DeleteOperation()
        target[keyPath: key.1] = nil
    }
    
    /**
     Converts the ParseFieldOperation to a data structure
     that can be converted to JSON and sent to Parse as part of a save operation.

     @param encoder encoder that will be used to encode the object.
     */
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RawCodingKey.self)
        try operations.forEach { pair in
            let (key, value) = pair
            let encoder = container.superEncoder(forKey: .key(key))
            try value.encode(to: encoder)
        }
    }
}
