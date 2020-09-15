//
//  ParseStorage.swift
//  
//
//  Created by Pranjal Satija on 7/19/20.
//

// MARK: ParseStorage
public struct ParseStorage {
    public static var shared = ParseStorage()

    private var backingStore: PrimitiveObjectStore!

    mutating func use(_ store: PrimitiveObjectStore) {
        self.backingStore = store
    }

    private mutating func requireBackingStore() {
        guard backingStore != nil else {
            print("You can't use ParseStorage without a backing store. An in-memory store is being used as a fallback.")
            return
        }
    }

    enum Keys {
        static let currentUser = "_currentUser"
        static let currentInstallation = "_currentInstallation"
        static let defaultACL = "_defaultACL"
    }
}

// MARK: PrimitiveObjectStore
extension ParseStorage: PrimitiveObjectStore {
    public mutating func delete(valueFor key: String) throws {
        requireBackingStore()
        return try backingStore.delete(valueFor: key)
    }

    public mutating func deleteAll() throws {
        requireBackingStore()
        return try backingStore.deleteAll()
    }
    public mutating func get<T>(valueFor key: String) throws -> T? where T: Decodable {
        requireBackingStore()
        return try backingStore.get(valueFor: key)
    }

    public mutating func set<T>(_ object: T, for key: String) throws where T: Encodable {
        requireBackingStore()
        return try backingStore.set(object, for: key)
    }
}
