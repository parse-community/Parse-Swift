//
//  ParsePrimitiveStorable.swift
//  
//
//  Created by Pranjal Satija on 7/19/20.
//

import Foundation

/**
 A store that supports key/value storage. It should be able
 to handle any object that conforms to encodable and decodable.
 */
@available(*, deprecated, renamed: "ParsePrimitiveStorable")
public typealias ParseKeyValueStore = ParsePrimitiveStorable

/**
 A store that supports key/value storage. It should be able
 to handle any object that conforms to encodable and decodable.
 */
public protocol ParsePrimitiveStorable {
    /// Delete an object from the store.
    /// - parameter key: The unique key value of the object.
    mutating func delete(valueFor key: String) throws
    /// Delete all objects from the store.
    mutating func deleteAll() throws
    /// Gets an object from the store based on its `key`.
    /// - parameter key: The unique key value of the object.
    mutating func get<T: Decodable>(valueFor key: String) throws -> T?
    /// Stores an object in the store with a given `key`.
    /// - parameter object: The object to store.
    /// - parameter key: The unique key value of the object.
    mutating func set<T: Encodable>(_ object: T, for key: String) throws
}

// MARK: InMemoryKeyValueStore

/// A `ParseKeyValueStore` that lives in memory for unit testing purposes.
/// It works by encoding / decoding all values just like a real `Codable` store would
/// but it stores all values as `Data` blobs in memory.
struct InMemoryKeyValueStore: ParsePrimitiveStorable {
    var decoder = ParseCoding.jsonDecoder()
    var encoder = ParseCoding.jsonEncoder()
    var storage = [String: Data]()

    mutating func delete(valueFor key: String) throws {
        storage[key] = nil
    }

    mutating func deleteAll() throws {
        storage.removeAll()
    }

    mutating func get<T>(valueFor key: String) throws -> T? where T: Decodable {
        guard let data = storage[key] else { return nil }
        return try decoder.decode(T.self, from: data)
    }

    mutating func set<T>(_ object: T, for key: String) throws where T: Encodable {
        let data = try encoder.encode(object)
        storage[key] = data
    }
}

#if !os(Linux) && !os(Android) && !os(Windows)

// MARK: KeychainStore + ParseKeyValueStore
extension KeychainStore: ParsePrimitiveStorable {

    func delete(valueFor key: String) throws {
        if !removeObject(forKey: key) {
            throw ParseError(code: .objectNotFound, message: "Object for key \"\(key)\" not found in Keychain")
        }
    }

    func deleteAll() throws {
        if !removeAllObjects() {
            throw ParseError(code: .objectNotFound, message: "Could not delete all objects in Keychain")
        }
    }

    func get<T>(valueFor key: String) throws -> T? where T: Decodable {
        object(forKey: key)
    }

    func set<T>(_ object: T, for key: String) throws where T: Encodable {
        if !set(object: object, forKey: key) {
            throw ParseError(code: .unknownError,
                             message: "Could not save object: \(object) key \"\(key)\" in Keychain")
        }
    }
}

#endif
