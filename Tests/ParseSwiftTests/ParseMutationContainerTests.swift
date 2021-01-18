//
//  ParseOperation.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/17/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseOperation: XCTestCase {
    struct GameScore: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: Int
        var members = [String]()
        var levels: [String]?

        //custom initializers
        init(score: Int) {
            self.score = score
        }
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url,
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        try KeychainStore.shared.deleteAll()
        try ParseStorage.shared.deleteAll()
    }

    func testIncrement() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .increment("score", by: 1)
        let expected = "{\"score\":{\"amount\":1,\"__op\":\"Increment\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testAdd() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .add("test", objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Add\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testAddKeypath() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .add(("test", \.members), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Add\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testAddOptionalKeypath() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .add(("test", \.levels), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Add\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testAddUnique() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .addUnique("test", objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"AddUnique\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testAddUniqueKeypath() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .addUnique(("test", \.members), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"AddUnique\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testAddUniqueOptionalKeypath() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .addUnique(("test", \.levels), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"AddUnique\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testRemove() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .remove("test", objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Remove\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveKeypath() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .remove(("test", \.members), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Remove\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveOptionalKeypath() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .remove(("test", \.levels), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Remove\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testUnset() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .unset("score")
        let expected = "{\"score\":{\"__op\":\"Delete\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testUnsetKeypath() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .unset(("score", \.levels))
        let expected = "{\"score\":{\"__op\":\"Delete\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }
}
