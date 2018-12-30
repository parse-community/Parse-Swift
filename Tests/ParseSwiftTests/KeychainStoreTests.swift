//
//  KeychainStoreTests.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-09-25.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation
import XCTest

@testable import ParseSwift

class KeychainStoreTests: XCTestCase {
    var testStore: KeychainStore!
    override func setUp() {
        super.setUp()
        testStore = KeychainStore(service: "test")
    }

    override func tearDown() {
        super.tearDown()
        testStore.removeAllObjects()
    }

    func testSetObject() {
        XCTAssertTrue(testStore.set(object: "yarr", forKey: "blah"), "Set should succeed")
    }

    func testGetObject() {
        let key = "yarrKey"
        let value = "yarrValue"
        testStore[key] = value
        let storedValue: String = testStore.object(forKey: key)!
        XCTAssertEqual(storedValue, value, "Values should be equal after get")
    }

    func testGetObjectSubscript() {
        let key = "yarrKey"
        let value = "yarrValue"
        testStore[key] = value
        XCTAssertEqual(testStore[key]!, value, "Values should be equal after get")
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
        XCTAssertNil(testStore[string: key], "Values should be equal after get")
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
        XCTAssertNil(testStore[bool: key], "Values should be equal after get")
    }

    func testSetComplextObject() {
        let complexObject: [Any] = [["key": "value"], "string2", 1234, NSNull()]
        testStore["complexObject"] = complexObject
        guard let retrievedObject: [Any] = testStore?["complexObject"] else {
            return XCTFail("Should retrieve the object")
        }

        XCTAssertTrue(retrievedObject.count == 4)
        retrievedObject.enumerated().forEach { (offset, retrievedValue) in
            let value = complexObject[offset]
            switch offset {
            case 0:
                guard let dict = value as? [String: String],
                    let retrivedDict = retrievedValue as? [String: String] else {
                        return XCTFail("Should be both dictionaries")
                }
                XCTAssertTrue(dict["key"] == retrivedDict["key"])
            case 1:
                guard let string = value as? String,
                    let retrievedString = retrievedValue as? String else {
                        return XCTFail("Should be both strings")
                }
                XCTAssertTrue(string == retrievedString)
            case 2:
                guard let int = value as? Int,
                    let retrievedInt = retrievedValue as? Int else {
                        return XCTFail("Should be both ints")
                }
                XCTAssertTrue(int == retrievedInt)
            case 3:
                guard let retrieved = retrievedValue as? NSNull else {
                        return XCTFail("Should be both ints")
                }
                XCTAssertTrue(retrieved == NSNull())
            default: break
            }
        }
    }

    func testRemoveObject() {
        testStore["key1"] = "value1"
        XCTAssertNotNil(testStore["key1"]!, "The value should be set")
        _ = testStore.removeObject(forKey: "key1")
        let key1Val: String? = testStore["key1"]
        XCTAssertNil(key1Val, "There should be no value after removal")
    }

    func testRemoveObjectSubscript() {
        testStore["key1"] = "value1"
        XCTAssertNotNil(testStore["key1"]!, "The value should be set")
        testStore[string: "key1"] = nil
        let key1Val: String? = testStore["key1"]
        XCTAssertNil(key1Val, "There should be no value after removal")
    }

    func testRemoveAllObjects() {
        testStore["key1"] = "value1"
        testStore["key2"] = "value2"
        XCTAssertNotNil(testStore["key1"]!, "The value should be set")
        XCTAssertNotNil(testStore["key2"]!, "The value should be set")
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
}
