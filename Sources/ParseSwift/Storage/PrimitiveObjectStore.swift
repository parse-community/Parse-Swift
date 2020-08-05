//
//  PrimitiveObjectStore.swift
//  
//
//  Created by Pranjal Satija on 7/19/20.
//

import Foundation

// MARK: PrimitiveObjectStore
public protocol PrimitiveObjectStore {
    mutating func delete(valueFor key: String) throws
    mutating func get<T: Decodable>(valueFor key: String) throws -> T?
    mutating func set<T: Encodable>(_ object: T, for key: String) throws
}

/// A `PrimitiveObjectStore` that lives in memory for unit testing purposes.
/// It works by encoding / decoding all values just like a real `Codable` store would
/// but it stores all values as `Data` blobs in memory.
struct CodableInMemoryPrimitiveObjectStore: PrimitiveObjectStore {
    var decoder = JSONDecoder()
    var encoder = JSONEncoder()
    var storage = [String: Data]()

    mutating func delete(valueFor key: String) throws {
        storage[key] = nil
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

// MARK: KeychainStore + PrimitiveObjectStore
extension KeychainStore: PrimitiveObjectStore {
    func delete(valueFor key: String) throws {
        _ = removeObject(forKey: key)
    }

    func get<T>(valueFor key: String) throws -> T? where T: Decodable {
        object(forKey: key)
    }

    func set<T>(_ object: T, for key: String) throws where T: Encodable {
        _ = set(object: object, forKey: key)
    }
}
