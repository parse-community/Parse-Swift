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
 
 In most cases, you should not call this class directly as a `ParseOperation` can be
 indirectly created from any `ParseObject` by using its' `operation` property.
 */
public struct ParseOperation<T>: Savable where T: ParseObject {

    var target: T?
    var operations = [String: Encodable]()

    public init(target: T) {
        self.target = target
    }

    /**
     An operation that increases a numeric field's value by a given amount.
     - Parameters:
        - key: The key of the object.
        - amount: How much to increment by.
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
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
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
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
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
     */
    public func add<W>(_ key: String, objects: [W]) -> Self where W: Encodable {
        var mutableOperation = self
        mutableOperation.operations[key] = Add(objects: objects)
        return mutableOperation
    }

    /**
     An operation that adds a new element to an array field.
     - Parameters:
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
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
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
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
     */
    public func addRelation<W>(_ key: String, objects: [W]) -> Self where W: ParseObject {
        var mutableOperation = self
        mutableOperation.operations[key] = AddRelation(objects: objects)
        return mutableOperation
    }

    /**
     An operation that adds a new relation to an array field.
     - Parameters:
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
     */
    public func addRelation<V>(_ key: (String, WritableKeyPath<T, [V]>),
                               objects: [V]) throws -> Self where V: ParseObject {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = AddRelation(objects: objects)
        var values = target[keyPath: key.1]
        values.append(contentsOf: objects)
        mutableOperation.target?[keyPath: key.1] = values
        return mutableOperation
    }

    /**
     An operation that adds a new relation to an array field.
     - Parameters:
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
     */
    public func addRelation<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                               objects: [V]) throws -> Self where V: ParseObject {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = AddRelation(objects: objects)
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
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
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
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
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
     */
    public func removeRelation<W>(_ key: String, objects: [W]) -> Self where W: ParseObject {
        var mutableOperation = self
        mutableOperation.operations[key] = RemoveRelation(objects: objects)
        return mutableOperation
    }

    /**
     An operation that removes every instance of a relation from
     an array field.
     - Parameters:
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
     */
    public func removeRelation<V>(_ key: (String, WritableKeyPath<T, [V]>),
                                  objects: [V]) throws -> Self where V: ParseObject {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = RemoveRelation(objects: objects)
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
        - key: A tuple consisting of the key and KeyPath of the object.
        - objects: The field of objects.
     */
    public func removeRelation<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                                  objects: [V]) throws -> Self where V: ParseObject {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
        }
        var mutableOperation = self
        mutableOperation.operations[key.0] = RemoveRelation(objects: objects)
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
     */
    public func unset(_ key: String) -> Self {
        var mutableOperation = self
        mutableOperation.operations[key] = Delete()
        return mutableOperation
    }

    /**
     An operation where a field is deleted from the object.
     - Parameters:
        - key: A tuple consisting of the key and KeyPath of the object.
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

extension ParseOperation {
    /**
     Saves the operations on the `ParseObject` *synchronously* and throws an error if there's an issue.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.

     - returns: Returns saved `ParseObject`.
    */
    public func save(options: API.Options = []) throws -> T {
        guard let target = self.target else {
            throw ParseError(code: .unknownError, message: "Target shouldn't be nil")
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
                let error = ParseError(code: .missingObjectId, message: "ParseObject isn't saved.")
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
