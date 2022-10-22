//
//  KeychainStoreTests.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-09-25.
//  Copyright © 2020 Parse Community. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows)
import Foundation
import XCTest
@testable import ParseSwift

class KeychainStoreTests: XCTestCase {
    var testStore: KeychainStore!
    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              primaryKey: "primaryKey",
                              serverURL: url, testing: true)
        testStore = KeychainStore(service: "test")
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        _ = testStore.removeAllObjects()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        try? KeychainStore.objectiveC?.deleteAllObjectiveC()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testSetObject() {
        XCTAssertTrue(testStore.set(object: "yarr", forKey: "blah"), "Set should succeed")
    }

    func testGetObject() {
        let key = "yarrKey"
        let value = "yarrValue"
        testStore[key] = value
        guard let storedValue: String = testStore.object(forKey: key) else {
            XCTFail("Should unwrap to String")
            return
        }
        XCTAssertEqual(storedValue, value, "Values should be equal after get")
    }

    func testGetObjectSubscript() {
        let key = "yarrKey"
        let value = "yarrValue"
        testStore[key] = value
        guard let storedValue: String = testStore[key] else {
            XCTFail("Should unwrap to String")
            return
        }
        XCTAssertEqual(storedValue, value, "Values should be equal after get")
    }

    func testGetObjectStringTypedSubscript() {
        let key = "yarrKey"
        let value = "yarrValue"
        testStore[key] = value
        XCTAssertEqual(testStore[string: key], value, "Values should be equal after get")
    }

    func testGetObjectWrongStringTypedSubscript() {
        let key = "yarrKey"
        let value = 1
        testStore[key] = value
        XCTAssertNil(testStore[string: key], "Values should be nil after get")
    }

    func testGetObjectBoolTypedSubscript() {
        let key = "yarrKey"
        let value = true
        testStore[bool: key] = value
        XCTAssertEqual(testStore[bool: key], true, "Values should be equal after get")
    }

    func testGetObjectWrongBoolTypedSubscript() {
        let key = "yarrKey"
        let value = "Yo!"
        testStore[key] = value
        XCTAssertNil(testStore[bool: key], "Values should be nil after get")
    }

    func testGetAnyCodableObject() {
        let key = "yarrKey"
        let value: AnyCodable = "yarrValue"
        testStore[key] = value
        guard let storedValue: AnyCodable = testStore.object(forKey: key) else {
            XCTFail("Should unwrap to AnyCodable")
            return
        }
        XCTAssertEqual(storedValue, value, "Values should be equal after get")
    }

    func testSetComplextObject() {
        let complexObject: [AnyCodable] = [["key": "value"], "string2", 1234]
        testStore["complexObject"] = complexObject
        guard let retrievedObject: [AnyCodable] = testStore["complexObject"] else {
            return XCTFail("Should retrieve the object")
        }
        XCTAssertTrue(retrievedObject.count == 3)
        retrievedObject.enumerated().forEach { (offset, retrievedValue) in
            let value = complexObject[offset].value
            switch offset {
            case 0:
                guard let dict = value as? [String: String],
                    let retrievedDictionary = retrievedValue.value as? [String: String] else {
                        return XCTFail("Should be both dictionaries")
                }
                XCTAssertTrue(dict == retrievedDictionary)
            case 1:
                guard let string = value as? String,
                    let retrievedString = retrievedValue.value as? String else {
                        return XCTFail("Should be both strings")
                }
                XCTAssertTrue(string == retrievedString)
            case 2:
                guard let int = value as? Int,
                    let retrievedInt = retrievedValue.value as? Int else {
                        return XCTFail("Should be both ints")
                }
                XCTAssertTrue(int == retrievedInt)
            default: break
            }
        }
    }

    func testRemoveObject() {
        testStore["key1"] = "value1"
        XCTAssertNotNil(testStore[string: "key1"], "The value should be set")
        _ = testStore.removeObject(forKey: "key1")
        let key1Val: String? = testStore["key1"]
        XCTAssertNil(key1Val, "There should be no value after removal")
    }

    func testRemoveObjectSubscript() {
        testStore["key1"] = "value1"
        XCTAssertNotNil(testStore[string: "key1"], "The value should be set")
        testStore[string: "key1"] = nil
        let key1Val: String? = testStore["key1"]
        XCTAssertNil(key1Val, "There should be no value after removal")
    }

    func testRemoveAllObjects() {
        testStore["key1"] = "value1"
        testStore["key2"] = "value2"
        XCTAssertNotNil(testStore[string: "key1"], "The value should be set")
        XCTAssertNotNil(testStore[string: "key2"], "The value should be set")
        _ = testStore.removeAllObjects()
        let key1Val: String? = testStore["key1"]
        let key2Val: String? = testStore["key1"]
        XCTAssertNil(key1Val, "There should be no value after removal")
        XCTAssertNil(key2Val, "There should be no value after removal")
    }

    func testThreadSafeSet() {
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            XCTAssertTrue(testStore.set(object: "yarr", forKey: "pirate"), "Should set value")
        }
    }

    func testThreadSafeRemoveObject() {
        DispatchQueue.concurrentPerform(iterations: 100) { (index) in
            XCTAssertTrue(testStore.set(object: "yarr", forKey: "\(index)"), "Should set value")
            XCTAssertTrue(testStore.removeObject(forKey: "\(index)"), "Should set value")
        }
    }

    func testThreadSafeRemoveAllObjects() {
        DispatchQueue.concurrentPerform(iterations: 100) { (_) in
            XCTAssertTrue(testStore.set(object: "yarr", forKey: "pirate1"), "Should set value")
            XCTAssertTrue(testStore.set(object: "yarr", forKey: "pirate2"), "Should set value")
            XCTAssertTrue(testStore.removeAllObjects(), "Should set value")
        }
    }

    func testQueryTemplate() throws {
        let query = KeychainStore.shared.getKeychainQueryTemplate()
        XCTAssertEqual(query.count, 2)
        XCTAssertEqual(query[kSecAttrService as String] as? String, KeychainStore.shared.service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
    }

    func testQueryNoAccessGroup() throws {
        let accessGroup = ParseKeychainAccessGroup()
        let query = KeychainStore.shared.keychainQuery(forKey: "hello", accessGroup: accessGroup)
        XCTAssertEqual(query.count, 5)
        XCTAssertEqual(query[kSecAttrService as String] as? String, KeychainStore.shared.service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, "hello")
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, kCFBooleanFalse as? Bool)
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
    }

    func testQueryAccessGroupSyncableKeyTrue() throws {
        let accessGroup = ParseKeychainAccessGroup(accessGroup: "world", isSyncingKeychainAcrossDevices: true)
        let query = KeychainStore.shared.keychainQuery(forKey: "hello", accessGroup: accessGroup)
        XCTAssertEqual(query.count, 6)
        XCTAssertEqual(query[kSecAttrService as String] as? String, KeychainStore.shared.service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, "hello")
        XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, "world")
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, kCFBooleanTrue as? Bool)
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleAfterFirstUnlock as String)
    }

    func testQueryAccessGroupSyncableKeyFalse() throws {
        let accessGroup = ParseKeychainAccessGroup(accessGroup: "world", isSyncingKeychainAcrossDevices: false)
        let query = KeychainStore.shared.keychainQuery(forKey: "hello", accessGroup: accessGroup)
        XCTAssertEqual(query.count, 6)
        XCTAssertEqual(query[kSecAttrService as String] as? String, KeychainStore.shared.service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, "hello")
        XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, "world")
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, kCFBooleanFalse as? Bool)
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
    }

    func testQueryAccessGroupNoSyncableKeyTrue() throws {
        let key = ParseStorage.Keys.currentInstallation
        let accessGroup = ParseKeychainAccessGroup(accessGroup: "world", isSyncingKeychainAcrossDevices: true)
        let query = KeychainStore.shared.keychainQuery(forKey: key, accessGroup: accessGroup)
        XCTAssertEqual(query.count, 6)
        XCTAssertEqual(query[kSecAttrService as String] as? String, KeychainStore.shared.service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, key)
        XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, "world")
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, kCFBooleanFalse as? Bool)
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
    }

    func testQueryAccessGroupNoSyncableKeyFalse() throws {
        let key = ParseStorage.Keys.currentInstallation
        let accessGroup = ParseKeychainAccessGroup(accessGroup: "world", isSyncingKeychainAcrossDevices: false)
        let query = KeychainStore.shared.keychainQuery(forKey: key, accessGroup: accessGroup)
        XCTAssertEqual(query.count, 6)
        XCTAssertEqual(query[kSecAttrService as String] as? String, KeychainStore.shared.service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, key)
        XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, "world")
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, kCFBooleanFalse as? Bool)
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
    }

    func testSetObjectiveC() throws {
        // Set keychain the way objc sets keychain
        guard let objcParseKeychain = KeychainStore.objectiveC else {
            XCTFail("Should have unwrapped")
            return
        }
        let objcInstallationId = "helloWorld"
        _ = objcParseKeychain.setObjectiveC(object: objcInstallationId, forKey: "installationId")

        guard let retrievedValue: String = objcParseKeychain.objectObjectiveC(forKey: "installationId") else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(retrievedValue, objcInstallationId)
        let newInstallationId: String? = nil
        _ = objcParseKeychain.setObjectiveC(object: newInstallationId, forKey: "installationId")
        let retrievedValue2: String? = objcParseKeychain.objectObjectiveC(forKey: "installationId")
        XCTAssertNil(retrievedValue2)
    }
}
#endif
