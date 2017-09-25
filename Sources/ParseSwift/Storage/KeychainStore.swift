//
//  KeychainStore.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-09-25.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

func getKeychainQueryTemplate(forService service: String) -> [String: String] {
    var query = [String: String]()
    if service.characters.count > 0 {
        query[kSecAttrService as String] = service
    }
    query[kSecClass as String] = kSecClassGenericPassword as String
    query[kSecAttrAccessible as String] =  kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
    return query
}

struct KeychainStore: SecureStorage {
    private let synchronizationQueue: DispatchQueue
    private let keychainQueryTemplate: [String: String]
    init(service: String) {
        synchronizationQueue = DispatchQueue(label: "com.parse.keychain.\(service)",
                                             qos: .default,
                                             attributes: .concurrent,
                                             autoreleaseFrequency:.inherit,
                                             target: nil)
        keychainQueryTemplate = getKeychainQueryTemplate(forService: service)
    }

    private func keychainQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = keychainQueryTemplate
        query[kSecAttrAccount as String] = key
        return query
    }

    func object(forKey key: String) -> Any? {
        guard let data = synchronizationQueue.sync(execute: { () -> Data? in
            return self.data(forKey: key)
        }) else {
            return nil
        }
        return NSKeyedUnarchiver.unarchiveObject(with: data)
    }

    func set(object: Any?, forKey key: String) -> Bool {
        guard let object = object else {
            return removeObject(forKey: key)
        }
        let data = NSKeyedArchiver.archivedData(withRootObject: object)
        var query = keychainQuery(forKey: key)
        let update = [
            kSecValueData as String: data
        ]

        let status = synchronizationQueue.sync(flags: .barrier) { () -> OSStatus in
            if self.data(forKey: key) != nil {
                return SecItemUpdate(query as CFDictionary, update as CFDictionary)
            } else {
                query = query.merging(update) { (_, otherValue) -> Any in otherValue }
                return SecItemAdd(query as CFDictionary, nil)
            }
        }

        return status == errSecSuccess
    }

    subscript(key: String) -> Any? {
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

    private func removeObject(forKeyUnsafe key: String) -> Bool {
        if #available(iOS 10.0, macOS 10.12, *) {
            dispatchPrecondition(condition: .onQueue(synchronizationQueue))
        }
        return SecItemDelete(keychainQuery(forKey: key) as CFDictionary) == errSecSuccess
    }

}
