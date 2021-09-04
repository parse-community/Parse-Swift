//
//  KeychainStore.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-09-25.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation
#if canImport(Security)
import Security
#endif

#if !os(Linux) && !os(Android)

func getKeychainQueryTemplate(forService service: String) -> [String: String] {
    var query = [String: String]()
    if service.count > 0 {
        query[kSecAttrService as String] = service
    }
    query[kSecClass as String] = kSecClassGenericPassword as String
    query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
    return query
}

/**
 KeychainStore is UserDefaults-like wrapper on top of Keychain.
 It supports any object, with Coding support. All objects are available after the
 first device unlock and are not backed up.
 */
struct KeychainStore: SecureStorage {
    let synchronizationQueue: DispatchQueue
    private let keychainQueryTemplate: [String: String]
    static var shared = KeychainStore()
    // This Keychain was used by SDK <= 1.9.7
    static var old = KeychainStore(service: "shared")

    init(service: String? = nil) {
        var keychainService = ".parseSwift.sdk"
        if let service = service {
            keychainService = service
        } else if let identifier = Bundle.main.bundleIdentifier {
            keychainService = "\(identifier)\(keychainService)"
        } else {
            keychainService = "com\(keychainService)"
        }
        synchronizationQueue = DispatchQueue(label: "\(keychainService).keychain",
                                             qos: .default,
                                             attributes: .concurrent,
                                             autoreleaseFrequency: .inherit,
                                             target: nil)
        keychainQueryTemplate = getKeychainQueryTemplate(forService: keychainService)
    }

    func copy(keychain: KeychainStore) {
        if let user = keychain.data(forKey: ParseStorage.Keys.currentUser) {
            _ = try? set(user, forKey: ParseStorage.Keys.currentUser)
        }
        if let installation = keychain.data(forKey: ParseStorage.Keys.currentInstallation) {
            _ = try? set(installation, forKey: ParseStorage.Keys.currentInstallation)
        }
        if let version = keychain.data(forKey: ParseStorage.Keys.currentVersion) {
            _ = try? set(version, forKey: ParseStorage.Keys.currentVersion)
        }
        if let config = keychain.data(forKey: ParseStorage.Keys.currentConfig) {
            _ = try? set(config, forKey: ParseStorage.Keys.currentConfig)
        }
        if let acl = keychain.data(forKey: ParseStorage.Keys.defaultACL) {
            _ = try? set(acl, forKey: ParseStorage.Keys.defaultACL)
        }
    }

    private func keychainQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = keychainQueryTemplate
        query[kSecAttrAccount as String] = key
        return query
    }

    func object<T>(forKey key: String) -> T? where T: Decodable {
        guard let data = synchronizationQueue.sync(execute: { () -> Data? in
            return self.data(forKey: key)
        }) else {
            return nil
        }
        do {
            let object = try ParseCoding.jsonDecoder().decode(T.self, from: data)
            return object
        } catch {
            return nil
        }
    }

    func set<T>(object: T?, forKey key: String) -> Bool where T: Encodable {
        guard let object = object else {
            return removeObject(forKey: key)
        }
        do {
            let data = try ParseCoding.jsonEncoder().encode(object)
            return try set(data, forKey: key)
        } catch {
            return false
        }
    }

    subscript<T>(key: String) -> T? where T: Codable {
        get {
            return object(forKey: key)
        }
        set (object) {
            _ = set(object: object, forKey: key)
        }
    }

    func removeObject(forKey key: String) -> Bool {
        return synchronizationQueue.sync {
            return removeObject(forKeyUnsafe: key)
        }
    }

    func removeAllObjects() -> Bool {
        var query = keychainQueryTemplate as [String: Any]
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitAll

        return synchronizationQueue.sync(flags: .barrier) { () -> Bool in
            var result: AnyObject?
            let status = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }
            if status != errSecSuccess { return true }

            guard let results = result as? [[String: Any]] else { return false }

            for dict in results {
                guard let key = dict[kSecAttrAccount as String] as? String,
                    self.removeObject(forKeyUnsafe: key) else {
                        return false
                }
            }
            return true
        }
    }

    private func data(forKey key: String) -> Data? {
        var query: [String: Any] = keychainQuery(forKey: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanTrue

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        guard status == errSecSuccess,
            let data = result as? Data else {
            return nil
        }

        return data
    }

    private func set(_ data: Data, forKey key: String) throws -> Bool {
        let query = keychainQuery(forKey: key)
        let update = [
            kSecValueData as String: data
        ]

        let status = synchronizationQueue.sync(flags: .barrier) { () -> OSStatus in
            if self.data(forKey: key) != nil {
                return SecItemUpdate(query as CFDictionary, update as CFDictionary)
            }
            let mergedQuery = query.merging(update) { (_, otherValue) -> Any in otherValue }
            return SecItemAdd(mergedQuery as CFDictionary, nil)
        }

        return status == errSecSuccess
    }

    private func removeObject(forKeyUnsafe key: String) -> Bool {
        dispatchPrecondition(condition: .onQueue(synchronizationQueue))
        return SecItemDelete(keychainQuery(forKey: key) as CFDictionary) == errSecSuccess
    }
}

// MARK: TypedSubscript
extension KeychainStore {
    subscript(string key: String) -> String? {
        get {
            return object(forKey: key)
        }
        set (object) {
            _ = set(object: object, forKey: key)
        }
    }

    subscript(bool key: String) -> Bool? {
        get {
            return object(forKey: key)
        }
        set (object) {
            _ = set(object: object, forKey: key)
        }
    }
}
#endif
