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

#if !os(Linux) && !os(Android) && !os(Windows)

/**
 KeychainStore is UserDefaults-like wrapper on top of Keychain.
 It supports any object, with Coding support. All objects are available after the
 first device unlock and are not backed up.
 */
struct KeychainStore: SecureStorage {

    let synchronizationQueue: DispatchQueue
    let service: String
    static var shared = KeychainStore()
    static var objectiveC: KeychainStore? {
        if let identifier = Bundle.main.bundleIdentifier {
            return KeychainStore(service: "\(identifier).com.parse.sdk")
        } else {
            return nil
        }
    }
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
        self.service = keychainService
        synchronizationQueue = DispatchQueue(label: "\(keychainService).keychain",
                                             qos: .default,
                                             attributes: .concurrent,
                                             autoreleaseFrequency: .inherit,
                                             target: nil)
    }

    func getKeychainQueryTemplate() -> [String: Any] {
        var query = [String: Any]()
        if !service.isEmpty {
            query[kSecAttrService as String] = service
        }
        query[kSecClass as String] = kSecClassGenericPassword as String
        return query
    }

    func copy(_ keychain: KeychainStore,
              oldAccessGroup: ParseKeychainAccessGroup,
              newAccessGroup: ParseKeychainAccessGroup) throws {
        if let user = keychain.data(forKey: ParseStorage.Keys.currentUser,
                                    accessGroup: oldAccessGroup) {
            try set(user,
                    forKey: ParseStorage.Keys.currentUser,
                    oldAccessGroup: oldAccessGroup,
                    newAccessGroup: newAccessGroup)
        }
        if let installation = keychain.data(forKey: ParseStorage.Keys.currentInstallation,
                                            accessGroup: oldAccessGroup) {
            try set(installation,
                    forKey: ParseStorage.Keys.currentInstallation,
                    oldAccessGroup: oldAccessGroup,
                    newAccessGroup: newAccessGroup)
        }
        if let version = keychain.data(forKey: ParseStorage.Keys.currentVersion,
                                       accessGroup: oldAccessGroup) {
            try set(version,
                    forKey: ParseStorage.Keys.currentVersion,
                    oldAccessGroup: oldAccessGroup,
                    newAccessGroup: newAccessGroup)
        }
        if let config = keychain.data(forKey: ParseStorage.Keys.currentConfig,
                                      accessGroup: oldAccessGroup) {
            try set(config,
                    forKey: ParseStorage.Keys.currentConfig,
                    oldAccessGroup: oldAccessGroup,
                    newAccessGroup: newAccessGroup)
        }
        if let acl = keychain.data(forKey: ParseStorage.Keys.defaultACL,
                                   accessGroup: oldAccessGroup) {
            try set(acl,
                    forKey: ParseStorage.Keys.defaultACL,
                    oldAccessGroup: oldAccessGroup,
                    newAccessGroup: newAccessGroup)
        }
        if let keychainAccessGroup = keychain.data(forKey: ParseStorage.Keys.currentAccessGroup,
                                                   accessGroup: oldAccessGroup) {
            try set(keychainAccessGroup,
                    forKey: ParseStorage.Keys.currentAccessGroup,
                    oldAccessGroup: oldAccessGroup,
                    newAccessGroup: newAccessGroup)
        }
    }

    func isSyncableKey(_ key: String) -> Bool {
        key != ParseStorage.Keys.currentInstallation &&
        key != ParseStorage.Keys.currentVersion &&
        key != ParseStorage.Keys.currentAccessGroup
    }

    func keychainQuery(forKey key: String,
                       accessGroup: ParseKeychainAccessGroup) -> [String: Any] {
        var query: [String: Any] = getKeychainQueryTemplate()
        query[kSecAttrAccount as String] = key
        if let keychainAccessGroup = accessGroup.accessGroup {
            query[kSecAttrAccessGroup as String] = keychainAccessGroup
            if accessGroup.isSyncingKeychainAcrossDevices && isSyncableKey(key) {
                query[kSecAttrSynchronizable as String] = kCFBooleanTrue
                query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock as String
            } else {
                query[kSecAttrSynchronizable as String] = kCFBooleanFalse
                query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
            }
        } else {
            query[kSecAttrSynchronizable as String] = kCFBooleanFalse
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        }
        #if os(macOS)
        if !ParseSwift.configuration.isTestingSDK {
            query[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
        }
        #endif
        return query
    }

    func data(forKey key: String,
              accessGroup: ParseKeychainAccessGroup) -> Data? {
        var query: [String: Any] = keychainQuery(forKey: key,
                                                 accessGroup: accessGroup)
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

    private func set(_ data: Data,
                     forKey key: String,
                     oldAccessGroup: ParseKeychainAccessGroup,
                     newAccessGroup: ParseKeychainAccessGroup) throws {
        var query = keychainQuery(forKey: key,
                                  accessGroup: oldAccessGroup)
        var update: [String: Any] = [
            kSecValueData as String: data
        ]

        if let newKeychainAccessGroup = newAccessGroup.accessGroup {
            update[kSecAttrAccessGroup as String] = newKeychainAccessGroup
            if newAccessGroup.isSyncingKeychainAcrossDevices && isSyncableKey(key) {
                update[kSecAttrSynchronizable as String] = kCFBooleanTrue
                update[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock as String
            } else {
                update[kSecAttrSynchronizable as String] = kCFBooleanFalse
                update[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
            }
        } else {
            query.removeValue(forKey: kSecAttrAccessGroup as String)
            update[kSecAttrSynchronizable as String] = kCFBooleanFalse
            update[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        }

        let status = synchronizationQueue.sync(flags: .barrier) { () -> OSStatus in
            if self.data(forKey: key,
                         accessGroup: newAccessGroup) != nil {
                return SecItemUpdate(query as CFDictionary, update as CFDictionary)
            }
            let mergedQuery = query.merging(update) { (_, otherValue) -> Any in otherValue }
            return SecItemAdd(mergedQuery as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            throw ParseError(code: .unknownError,
                             message: "Could not save to Keychain, OSStatus: \(status)")
        }
    }

    private func removeObject(forKey key: String,
                              accessGroup: ParseKeychainAccessGroup) -> Bool {
        dispatchPrecondition(condition: .onQueue(synchronizationQueue))
        let query = keychainQuery(forKey: key,
                                  accessGroup: accessGroup) as CFDictionary
        return SecItemDelete(query) == errSecSuccess
    }

    func removeOldObjects(accessGroup: ParseKeychainAccessGroup) -> Bool {
        var query = getKeychainQueryTemplate()
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitAll

        return synchronizationQueue.sync(flags: .barrier) { () -> Bool in
            var result: AnyObject?
            let status = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }
            if status != errSecSuccess { return true }

            guard let results = result as? [[String: Any]] else { return false }

            for item in results {
                guard let key = item[kSecAttrAccount as String] as? String,
                      isSyncableKey(key) == true else {
                    continue
                }
                guard self.removeObject(forKey: key,
                                        accessGroup: accessGroup) == true else {
                    return false
                }
            }
            return true
        }
    }
}

// MARK: SecureStorage
extension KeychainStore {
    func object<T>(forKey key: String) -> T? where T: Decodable {
        guard let data = synchronizationQueue.sync(execute: { () -> Data? in
            return self.data(forKey: key,
                             accessGroup: ParseSwift.configuration.keychainAccessGroup)
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
            try set(data,
                    forKey: key,
                    oldAccessGroup: ParseSwift.configuration.keychainAccessGroup,
                    newAccessGroup: ParseSwift.configuration.keychainAccessGroup)
            return true
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
            return removeObject(forKey: key,
                                accessGroup: ParseSwift.configuration.keychainAccessGroup)
        }
    }

    func removeAllObjects() -> Bool {
        var query = getKeychainQueryTemplate()
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitAll

        return synchronizationQueue.sync(flags: .barrier) { () -> Bool in
            var result: AnyObject?
            let status = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }
            if status != errSecSuccess { return true }

            guard let results = result as? [[String: Any]] else { return false }

            for item in results {
                guard let key = item[kSecAttrAccount as String] as? String else {
                    continue
                }
                let removedDefaultObject = self.removeObject(forKey: key,
                                                             accessGroup: ParseSwift.configuration.keychainAccessGroup)
                var mutatedKeychainAccessGroup = ParseSwift.configuration.keychainAccessGroup
                mutatedKeychainAccessGroup.isSyncingKeychainAcrossDevices.toggle()
                let removedToggledObject = self.removeObject(forKey: key,
                                                             accessGroup: mutatedKeychainAccessGroup)
                mutatedKeychainAccessGroup.accessGroup = nil
                let removedNoAccessGroupObject = self.removeObject(forKey: key,
                                                                   accessGroup: mutatedKeychainAccessGroup)
                if !(removedDefaultObject || removedToggledObject || removedNoAccessGroupObject) {
                    return false
                }
            }
            return true
        }
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
