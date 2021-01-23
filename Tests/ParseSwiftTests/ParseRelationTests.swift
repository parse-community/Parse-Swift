//
//  ParseRelationTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/20/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseRelationTests: XCTestCase {
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

    struct Level: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var level: Int
        var members = [String]()

        //custom initializers
        init(level: Int) {
            self.level = level
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
        #if !os(Linux)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testEncoding() throws {
        var score = GameScore(score: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation

        let expected = "{\"__type\":\"Relation\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(relation)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)

        relation.className = "hello"
        let expected2 = "{\"className\":\"hello\",\"__type\":\"Relation\"}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(relation)
        let decoded2 = String(data: encoded2, encoding: .utf8)
        XCTAssertEqual(decoded2, expected2)
    }

    func testParseObjectRelation() throws {
        var score = GameScore(score: 10)
        let objectId = "hello"
        score.objectId = objectId

        var level = Level(level: 1)
        level.objectId = "nice"

        var relation = score.relation("yolo", child: level)

        let expected = "{\"className\":\"Level\",\"__type\":\"Relation\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(relation)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)

        relation.className = "hello"
        let expected2 = "{\"className\":\"hello\",\"__type\":\"Relation\"}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(relation)
        let decoded2 = String(data: encoded2, encoding: .utf8)
        XCTAssertEqual(decoded2, expected2)

        var relation2 = score.relation("yolo", className: "Level")

        let expected3 = "{\"className\":\"Level\",\"__type\":\"Relation\"}"
        let encoded3 = try ParseCoding.jsonEncoder().encode(relation2)
        let decoded3 = String(data: encoded3, encoding: .utf8)
        XCTAssertEqual(decoded3, expected3)

        relation2.className = "hello"
        let expected4 = "{\"className\":\"hello\",\"__type\":\"Relation\"}"
        let encoded4 = try ParseCoding.jsonEncoder().encode(relation2)
        let decoded4 = String(data: encoded4, encoding: .utf8)
        XCTAssertEqual(decoded4, expected4)
    }

    func testInitWithChild() throws {
        var score = GameScore(score: 10)
        let objectId = "hello"
        score.objectId = objectId

        var level = Level(level: 1)
        level.objectId = "nice"
        var relation = ParseRelation<GameScore>(parent: score, child: level)

        let expected = "{\"className\":\"Level\",\"__type\":\"Relation\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(relation)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)

        relation.className = "hello"
        let expected2 = "{\"className\":\"hello\",\"__type\":\"Relation\"}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(relation)
        let decoded2 = String(data: encoded2, encoding: .utf8)
        XCTAssertEqual(decoded2, expected2)
    }

    func testAddIncorrectClassError() throws {
        var score = GameScore(score: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        relation.className = "hello"
        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try relation.add("level", objects: [level]))
    }

    func testAddIncorrectKeyError() throws {
        var score = GameScore(score: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        relation.className = "Level"
        relation.key = "test"
        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try relation.add("level", objects: [level]))
    }

    func testAddOperations() throws {
        var score = GameScore(score: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className

        let operation = try relation.add("level", objects: [level])
        // swiftlint:disable:next line_length
        let expected = "{\"level\":{\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"nice\"}],\"__op\":\"AddRelation\"}}"
        let encoded = try ParseCoding.jsonEncoder().encode(operation)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testAddOperationsKeyCheck() throws {
        var score = GameScore(score: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className
        relation.key = "level"

        let operation = try relation.add("level", objects: [level])
        // swiftlint:disable:next line_length
        let expected = "{\"level\":{\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"nice\"}],\"__op\":\"AddRelation\"}}"
        let encoded = try ParseCoding.jsonEncoder().encode(operation)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveIncorrectClassError() throws {
        var score = GameScore(score: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        relation.className = "hello"
        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try relation.remove("level", objects: [level]))
    }

    func testRemoveIncorrectKeyError() throws {
        var score = GameScore(score: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        relation.className = "Level"
        relation.key = "test"
        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try relation.remove("level", objects: [level]))
    }

    func testRemoveOperations() throws {
        var score = GameScore(score: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className

        let operation = try relation.remove("level", objects: [level])
        // swiftlint:disable:next line_length
        let expected = "{\"level\":{\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"nice\"}],\"__op\":\"RemoveRelation\"}}"
        let encoded = try ParseCoding.jsonEncoder().encode(operation)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveOperationsKeyCheck() throws {
        var score = GameScore(score: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className
        relation.key = "level"

        let operation = try relation.remove("level", objects: [level])
        // swiftlint:disable:next line_length
        let expected = "{\"level\":{\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"nice\"}],\"__op\":\"RemoveRelation\"}}"
        let encoded = try ParseCoding.jsonEncoder().encode(operation)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testQuery() throws {
        var score = GameScore(score: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className

        //No Key, this should throw
        XCTAssertThrowsError(try relation.query(level))

        //Wrong child for the relation, should throw
        XCTAssertThrowsError(try relation.query(score))

        relation.key = "level"
        let query = try relation.query(level)

        // swiftlint:disable:next line_length
        let expected = "{\"limit\":100,\"skip\":0,\"_method\":\"GET\",\"where\":{\"$relatedTo\":{\"key\":\"level\",\"object\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}}"
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }
}
