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
    static var objectiveCService: String {
        guard let identifier = Bundle.main.bundleIdentifier else {
            return ""
        }
        return "\(identifier).com.parse.sdk"
    }
    static var shared = KeychainStore()
    static var objectiveC: KeychainStore? {
        KeychainStore(service: objectiveCService)
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

    func getObjectiveCKeychainQueryTemplate() -> [String: Any] {
        var query = [String: Any]()
        if !Self.objectiveCService.isEmpty {
            query[kSecAttrService as String] = Self.objectiveCService
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
                       useObjectiveCKeychain: Bool = false,
                       accessGroup: ParseKeychainAccessGroup) -> [String: Any] {
        if !useObjectiveCKeychain {
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
            if Parse.configuration.isUsingDataProtectionKeychain {
                query[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
            }
            #endif
            return query
        } else {
            var query: [String: Any] = getKeychainQueryTemplate()
            query[kSecAttrAccount as String] = key
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock as String
            return query
        }
    }

    func data(forKey key: String,
              useObjectiveCKeychain: Bool = false,
              accessGroup: ParseKeychainAccessGroup) -> Data? {
        var query: [String: Any] = keychainQuery(forKey: key,
                                                 useObjectiveCKeychain: useObjectiveCKeychain,
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
                     useObjectiveCKeychain: Bool = false,
                     oldAccessGroup: ParseKeychainAccessGroup,
                     newAccessGroup: ParseKeychainAccessGroup) throws {
        var query = keychainQuery(forKey: key,
                                  accessGroup: oldAccessGroup)
        var update: [String: Any] = [
            kSecValueData as String: data
        ]

        if !useObjectiveCKeychain {
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
        } else {
            update[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock as String
        }

        let status = synchronizationQueue.sync(flags: .barrier) { () -> OSStatus in
            let mergedQuery = query.merging(update) { (_, otherValue) -> Any in otherValue }
            if self.data(forKey: key,
                         accessGroup: newAccessGroup) != nil {
                let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
                guard updateStatus == errSecDuplicateItem,
                      SecItemDelete(mergedQuery as CFDictionary) == errSecSuccess else {
                    return updateStatus
                }
            }
            return SecItemAdd(mergedQuery as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            throw ParseError(code: .unknownError,
                             message: "Could not save to Keychain, OSStatus: \(status)")
        }
    }

    private func removeObject(forKey key: String,
                              useObjectiveCKeychain: Bool = false,
                              accessGroup: ParseKeychainAccessGroup) -> Bool {
        dispatchPrecondition(condition: .onQueue(synchronizationQueue))
        let query = keychainQuery(forKey: key,
                                  useObjectiveCKeychain: useObjectiveCKeychain,
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
                      isSyncableKey(key) else {
                    continue
                }
                guard self.removeObject(forKey: key,
                                        accessGroup: accessGroup) else {
                    return false
                }
            }
            return true
        }
    }

    func removeAllObjects(useObjectiveCKeychain: Bool) -> Bool {
        var query = useObjectiveCKeychain ? getObjectiveCKeychainQueryTemplate() : getKeychainQueryTemplate()
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
                                                             useObjectiveCKeychain: useObjectiveCKeychain,
                                                             accessGroup: Parse.configuration.keychainAccessGroup)
                if !useObjectiveCKeychain {
                    var mutatedKeychainAccessGroup = Parse.configuration.keychainAccessGroup
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
                             accessGroup: Parse.configuration.keychainAccessGroup)
        }) else {
            return nil
        }
        do {
            return try ParseCoding.jsonDecoder().decode(T.self, from: data)
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
                    oldAccessGroup: Parse.configuration.keychainAccessGroup,
                    newAccessGroup: Parse.configuration.keychainAccessGroup)
            return true
        } catch {
            return false
        }
    }

    subscript<T>(key: String) -> T? where T: Codable {
        get {
            object(forKey: key)
        }
        set (object) {
            _ = set(object: object, forKey: key)
        }
    }

    func removeObject(forKey key: String) -> Bool {
        return synchronizationQueue.sync {
            return removeObject(forKey: key,
                                accessGroup: Parse.configuration.keychainAccessGroup)
        }
    }

    func removeAllObjects() -> Bool {
        removeAllObjects(useObjectiveCKeychain: false)
    }
}

// MARK: TypedSubscript
extension KeychainStore {
    subscript(string key: String) -> String? {
        get {
            object(forKey: key)
        }
        set (object) {
            _ = set(object: object, forKey: key)
        }
    }

    subscript(bool key: String) -> Bool? {
        get {
            object(forKey: key)
        }
        set (object) {
            _ = set(object: object, forKey: key)
        }
    }
}

// MARK: Objective-C SDK Keychain
extension KeychainStore {
    func objectObjectiveC<T>(forKey key: String) -> T? where T: Decodable {
        guard let data = synchronizationQueue.sync(execute: { () -> Data? in
            return self.data(forKey: key,
                             useObjectiveCKeychain: true,
                             accessGroup: Parse.configuration.keychainAccessGroup)
        }) else {
            return nil
        }
        do {
            return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? T
        } catch {
            return nil
        }
    }

    func removeObjectObjectiveC(forKey key: String) -> Bool {
        return synchronizationQueue.sync {
            return removeObject(forKey: key,
                                useObjectiveCKeychain: true,
                                accessGroup: Parse.configuration.keychainAccessGroup)
        }
    }

    func setObjectiveC<T>(object: T?, forKey key: String) -> Bool where T: Encodable {
        guard let object = object else {
            return removeObjectObjectiveC(forKey: key)
        }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
            try set(data,
                    forKey: key,
                    useObjectiveCKeychain: true,
                    oldAccessGroup: Parse.configuration.keychainAccessGroup,
                    newAccessGroup: Parse.configuration.keychainAccessGroup)
            return true
        } catch {
            return false
        }
    }

    func deleteAllObjectiveC() throws {
        if !removeAllObjects(useObjectiveCKeychain: true) {
            throw ParseError(code: .objectNotFound, message: "Could not delete all objects in Keychain")
        }
    }
}

#endif
