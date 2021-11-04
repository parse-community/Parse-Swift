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
 
 In most cases, you do not need to create an instance of `ParseOperation` directly as it can be
 indirectly created from any `ParseObject` by using the respective `operation` property.
 */
public struct ParseOperation<T>: Savable where T: ParseObject {

    var target: T?
    var operations = [String: Encodable]()

    public init(target: T) {
        self.target = target
    }

    /**
     An operation that sets a field's value if it has changed from its previous value.
     - Parameters:
        - key: A tuple consisting of the key and the respective KeyPath of the object.
        - value: The value to set it to.
        - returns: The updated operations.
     */
    public func set<W>(_ key: (String, WritableKeyPath<T, W>),
                       value: W) throws -> Self where W: Encodable {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        if !target[keyPath: key.1].isEqual(value) {
            mutableOperation.operations[key.0] = value
            mutableOperation.target?[keyPath: key.1] = value
        }
        return mutableOperation
    }

    /**
     An operation that force sets a field's value.
     - Parameters:
        - key: A tuple consisting of the key and the respective KeyPath of the object.
        - value: The value to set it to.
        - returns: The updated operations.
     */
    public func forceSet<W>(_ key: (String, WritableKeyPath<T, W>),
                            value: W) throws -> Self where W: Encodable {
        guard self.target != nil else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = value
        mutableOperation.target?[keyPath: key.1] = value
        return mutableOperation
    }

    /**
     An operation that increases a numeric field's value by a given amount.
     - Parameters:
        - key: The key of the object.
        - amount: How much to increment by.
        - returns: The updated operations.
     */
    public func increment(_ key: String, by amount: Int) -> Self {
        var mutableOperation = self
        mutableOperation.operations[key] = Increment(amount: amount)
        return mutableOperation
    }

    /**
     An operation that adds a new element to an array field,
     only if it wasn't already present.
     - Parameters:
        - key: The key of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func addUnique<W>(_ key: String, objects: [W]) -> Self where W: Encodable, W: Hashable {
        var mutableOperation = self
        mutableOperation.operations[key] = AddUnique(objects: objects)
        return mutableOperation
    }

    /**
     An operation that adds a new element to an array field,
     only if it wasn't already present.
     - Parameters:
        - key: A tuple consisting of the key and the respective KeyPath of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func addUnique<V>(_ key: (String, WritableKeyPath<T, [V]>),
                             objects: [V]) throws -> Self where V: Encodable, V: Hashable {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = AddUnique(objects: objects)
        var values = target[keyPath: key.1]
        values.append(contentsOf: objects)
        mutableOperation.target?[keyPath: key.1] = Array(Set<V>(values))
        return mutableOperation
    }

    /**
     An operation that adds a new element to an array field,
     only if it wasn't already present.
     - Parameters:
        - key: A tuple consisting of the key and the respective KeyPath of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func addUnique<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                             objects: [V]) throws -> Self where V: Encodable, V: Hashable {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = AddUnique(objects: objects)
        var values = target[keyPath: key.1] ?? []
        values.append(contentsOf: objects)
        mutableOperation.target?[keyPath: key.1] = Array(Set<V>(values))
        return mutableOperation
    }

    /**
     An operation that adds a new element to an array field.
     - Parameters:
        - key: The key of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func add<W>(_ key: String, objects: [W]) -> Self where W: Encodable {
        var mutableOperation = self
        mutableOperation.operations[key] = Add(objects: objects)
        return mutableOperation
    }

    /**
     An operation that adds a new element to an array field.
     - Parameters:
        - key: A tuple consisting of the key and the respective KeyPath of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func add<V>(_ key: (String, WritableKeyPath<T, [V]>),
                       objects: [V]) throws -> Self where V: Encodable {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = Add(objects: objects)
        var values = target[keyPath: key.1]
        values.append(contentsOf: objects)
        mutableOperation.target?[keyPath: key.1] = values
        return mutableOperation
    }

    /**
     An operation that adds a new element to an array field.
     - Parameters:
        - key: A tuple consisting of the key and the respective KeyPath of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func add<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                       objects: [V]) throws -> Self where V: Encodable {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = Add(objects: objects)
        var values = target[keyPath: key.1] ?? []
        values.append(contentsOf: objects)
        mutableOperation.target?[keyPath: key.1] = values
        return mutableOperation
    }

    /**
     An operation that adds a new relation to an array field.
     - Parameters:
        - key: The key of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func addRelation<W>(_ key: String, objects: [W]) throws -> Self where W: ParseObject {
        var mutableOperation = self
        mutableOperation.operations[key] = try AddRelation(objects: objects)
        return mutableOperation
    }

    /**
     An operation that adds a new relation to an array field.
     - Parameters:
        - key: A tuple consisting of the key and the respective KeyPath of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func addRelation<V>(_ key: (String, WritableKeyPath<T, [V]>),
                               objects: [V]) throws -> Self where V: ParseObject {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = try AddRelation(objects: objects)
        var values = target[keyPath: key.1]
        values.append(contentsOf: objects)
        mutableOperation.target?[keyPath: key.1] = values
        return mutableOperation
    }

    /**
     An operation that adds a new relation to an array field.
     - Parameters:
        - key: A tuple consisting of the key and the respective KeyPath of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func addRelation<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                               objects: [V]) throws -> Self where V: ParseObject {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = try AddRelation(objects: objects)
        var values = target[keyPath: key.1] ?? []
        values.append(contentsOf: objects)
        mutableOperation.target?[keyPath: key.1] = values
        return mutableOperation
    }

    /**
     An operation that removes every instance of an element from
     an array field.
     - Parameters:
        - key: The key of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func remove<W>(_ key: String, objects: [W]) -> Self where W: Encodable {
        var mutableOperation = self
        mutableOperation.operations[key] = Remove(objects: objects)
        return mutableOperation
    }

    /**
     An operation that removes every instance of an element from
     an array field.
     - Parameters:
        - key: A tuple consisting of the key and the respective KeyPath of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func remove<V>(_ key: (String, WritableKeyPath<T, [V]>),
                          objects: [V]) throws -> Self where V: Encodable, V: Hashable {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = Remove(objects: objects)
        let values = target[keyPath: key.1]
        var set = Set<V>(values)
        objects.forEach {
            set.remove($0)
        }
        mutableOperation.target?[keyPath: key.1] = Array(set)
        return mutableOperation
    }

    /**
     An operation that removes every instance of an element from
     an array field.
     - Parameters:
        - key: A tuple consisting of the key and the respective KeyPath of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func remove<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                          objects: [V]) throws -> Self where V: Encodable, V: Hashable {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = Remove(objects: objects)
        let values = target[keyPath: key.1]
        var set = Set<V>(values ?? [])
        objects.forEach {
            set.remove($0)
        }
        mutableOperation.target?[keyPath: key.1] = Array(set)
        return mutableOperation
    }

    /**
     An operation that removes every instance of a relation from
     an array field.
     - Parameters:
        - key: The key of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func removeRelation<W>(_ key: String, objects: [W]) throws -> Self where W: ParseObject {
        guard self.target != nil else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key] = try RemoveRelation(objects: objects)
        return mutableOperation
    }

    /**
     An operation that removes every instance of a relation from
     an array field.
     - Parameters:
        - key: A tuple consisting of the key and the respective KeyPath of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func removeRelation<V>(_ key: (String, WritableKeyPath<T, [V]>),
                                  objects: [V]) throws -> Self where V: ParseObject {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = try RemoveRelation(objects: objects)
        let values = target[keyPath: key.1]
        var set = Set<V>(values)
        objects.forEach {
            set.remove($0)
        }
        mutableOperation.target?[keyPath: key.1] = Array(set)
        return mutableOperation
    }

    /**
     An operation that removes every instance of a relation from
     an array field.
     - Parameters:
        - key: A tuple consisting of the key and the respective KeyPath of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func removeRelation<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                                  objects: [V]) throws -> Self where V: ParseObject {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = try RemoveRelation(objects: objects)
        let values = target[keyPath: key.1]
        var set = Set<V>(values ?? [])
        objects.forEach {
            set.remove($0)
        }
        mutableOperation.target?[keyPath: key.1] = Array(set)
        return mutableOperation
    }

    /**
     An operation where a field is deleted from the object.
     - parameter key: The key of the object.
     - returns: The updated operations.
     */
    public func unset(_ key: String) -> Self {
        var mutableOperation = self
        mutableOperation.operations[key] = Delete()
        return mutableOperation
    }

    /**
     An operation where a field is deleted from the object.
     - Parameters:
        - key: A tuple consisting of the key and the respective KeyPath of the object.
        - returns: The updated operations.
     */
    public func unset<V>(_ key: (String, WritableKeyPath<T, V?>)) -> Self where V: Encodable {
        var mutableOperation = self
        mutableOperation.operations[key.0] = Delete()
        mutableOperation.target?[keyPath: key.1] = nil
        return mutableOperation
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

// MARK: Savable
extension ParseOperation {
    /**
     Saves the operations on the `ParseObject` *synchronously* and throws an error if there's an issue.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.

     - returns: Returns saved `ParseObject`.
    */
    public func save(options: API.Options = []) throws -> T {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil.")
        }
        if !target.isSaved {
            throw ParseError(code: .missingObjectId, message: "ParseObject isn't saved.")
        }
        return try saveCommand()
            .execute(options: options)
    }

    /**
     Saves the operations on the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<T, ParseError>)`.
    */
    public func save(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<T, ParseError>) -> Void
    ) {
        guard let target = self.target else {
            callbackQueue.async {
                let error = ParseError(code: .unknownError, message: "Target shouldn't be nil.")
                completion(.failure(error))
            }
            return
        }
        if !target.isSaved {
            callbackQueue.async {
                let error = ParseError(code: .missingObjectId, message: "ParseObject isn't saved.")
                completion(.failure(error))
            }
            return
        }
        do {
            try self.saveCommand().executeAsync(options: options) { result in
                callbackQueue.async {
                    completion(result)
                }
            }
        } catch {
            callbackQueue.async {
                let error = ParseError(code: .missingObjectId, message: "ParseObject isn't saved.")
                completion(.failure(error))
            }
        }
    }

    func saveCommand() throws -> API.NonParseBodyCommand<ParseOperation<T>, T> {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        return API.NonParseBodyCommand(method: .PUT, path: target.endpoint, body: self) {
            try ParseCoding.jsonDecoder().decode(UpdateResponse.self, from: $0).apply(to: target)
        }
    }
}

// MARK: ParseOperation
public extension ParseObject {

    /// Create a new operation.
    var operation: ParseOperation<Self> {
        return ParseOperation(target: self)
    }
}
