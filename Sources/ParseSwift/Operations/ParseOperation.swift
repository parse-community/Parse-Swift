//
//  ParseOperation.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

/**
 A `ParseOperation` represents a modification to a value in a `ParseObject`.
 For example, setting, deleting, or incrementing a value are all `ParseOperation`'s.
 `ParseOperation` themselves can be considered to be immutable.
 */
public final class ParseOperation<T>: ParseType where T: ParseObject {
    typealias ObjectType = T

    var target: T
    var operations = [String: Encodable]()

    init(target: T) {
        self.target = target
    }

    /**
     An operation that increases a numeric field's value by a given amount.
     - Parameters:
        - key: The key of the object.
        - amount: How much to increment by.
     */
    public func increment(_ key: String, by amount: Int) -> Self {
        operations[key] = IncrementOperation(amount: amount)
        return self
    }

    /**
     An operation that adds a new element to an array field,
     only if it wasn't already present.
     - Parameters:
        - key: The key of the object.
        - objects: The field of objects.
     */
    public func addUnique<W>(_ key: String, objects: [W]) -> Self where W: Encodable, W: Hashable {
        operations[key] = AddUniqueOperation(objects: objects)
        return self
    }

    /**
     An operation that adds a new element to an array field,
     only if it wasn't already present.
     - Parameters:
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
     */
    public func addUnique<V>(_ key: (String, WritableKeyPath<T, [V]>),
                             objects: [V]) -> Self where V: Encodable, V: Hashable {
        operations[key.0] = AddUniqueOperation(objects: objects)
        var values = target[keyPath: key.1]
        values.append(contentsOf: objects)
        target[keyPath: key.1] = Array(Set<V>(values))
        return self
    }

    /**
     An operation that adds a new element to an array field,
     only if it wasn't already present.
     - Parameters:
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
     */
    public func addUnique<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                             objects: [V]) -> Self where V: Encodable, V: Hashable {
        operations[key.0] = AddUniqueOperation(objects: objects)
        var values = target[keyPath: key.1] ?? []
        values.append(contentsOf: objects)
        target[keyPath: key.1] = Array(Set<V>(values))
        return self
    }

    /**
     An operation that adds a new element to an array field.
     - Parameters:
        - key: The key of the object.
        - objects: The field of objects.
     */
    public func add<W>(_ key: String, objects: [W]) -> Self where W: Encodable {
        operations[key] = AddOperation(objects: objects)
        return self
    }

    /**
     An operation that adds a new element to an array field.
     - Parameters:
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
     */
    public func add<V>(_ key: (String, WritableKeyPath<T, [V]>),
                       objects: [V]) -> Self where V: Encodable {
        operations[key.0] = AddOperation(objects: objects)
        var values = target[keyPath: key.1]
        values.append(contentsOf: objects)
        target[keyPath: key.1] = values
        return self
    }

    /**
     An operation that adds a new element to an array field.
     - Parameters:
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
     */
    public func add<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                       objects: [V]) -> Self where V: Encodable {
        operations[key.0] = AddOperation(objects: objects)
        var values = target[keyPath: key.1] ?? []
        values.append(contentsOf: objects)
        target[keyPath: key.1] = values
        return self
    }

    /**
     An operation that removes every instance of an element from
     an array field.
     - Parameters:
        - key: The key of the object.
        - objects: The field of objects.
     */
    public func remove<W>(_ key: String, objects: [W]) -> Self where W: Encodable {
        operations[key] = RemoveOperation(objects: objects)
        return self
    }

    /**
     An operation that removes every instance of an element from
     an array field.
     - Parameters:
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
     */
    public func remove<V>(_ key: (String, WritableKeyPath<T, [V]>),
                          objects: [V]) -> Self where V: Encodable, V: Hashable {
        operations[key.0] = RemoveOperation(objects: objects)
        let values = target[keyPath: key.1]
        var set = Set<V>(values)
        objects.forEach {
            set.remove($0)
        }
        target[keyPath: key.1] = Array(set)
        return self
    }

    /**
     An operation that removes every instance of an element from
     an array field.
     - Parameters:
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
     */
    public func remove<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                          objects: [V]) -> Self where V: Encodable, V: Hashable {
        operations[key.0] = RemoveOperation(objects: objects)
        let values = target[keyPath: key.1]
        var set = Set<V>(values ?? [])
        objects.forEach {
            set.remove($0)
        }
        target[keyPath: key.1] = Array(set)
        return self
    }

    /**
     An operation where a field is deleted from the object.
     - parameter key: The key of the object.
     */
    public func unset(_ key: String) -> Self {
        operations[key] = DeleteOperation()
        return self
    }

    /**
     An operation where a field is deleted from the object.
     - Parameters:
        - key: A tuple consisting of the key and KeyPath of the object.
     */
    public func unset<V>(_ key: (String, WritableKeyPath<T, V?>)) -> Self where V: Encodable {
        operations[key.0] = DeleteOperation()
        target[keyPath: key.1] = nil
        return self
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RawCodingKey.self)
        try operations.forEach { pair in
            let (key, value) = pair
            let encoder = container.superEncoder(forKey: .key(key))
            try value.encode(to: encoder)
        }
    }
}
