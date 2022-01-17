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
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
<<<<<<< HEAD
        var score: Double?
        var originalData: Data?
=======
>>>>>>> main

        //: Your own properties
        var points: Int
        var members = [String]()
        var levels: [String]?

        //custom initializers
        init() {
            self.points = 5
        }
        init(points: Int) {
            self.points = points
        }
    }

    struct Level: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
<<<<<<< HEAD
        var score: Double?
        var originalData: Data?
=======
>>>>>>> main

        //: Your own properties
        var level: Int
        var members = [String]()

        //custom initializers
        init() {
            self.level = 5
        }

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
                              isTesting: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testEncoding() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation

        let expected = "{\"__type\":\"Relation\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(relation)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)

        relation.className = "hello"
        let expected2 = "{\"__type\":\"Relation\",\"className\":\"hello\"}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(relation)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
        XCTAssertEqual(relation.debugDescription,
                       "ParseRelation ({\"__type\":\"Relation\",\"className\":\"hello\"})")
        XCTAssertEqual(relation.description,
                       "ParseRelation ({\"__type\":\"Relation\",\"className\":\"hello\"})")
    }

    func testParseObjectRelation() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId

        var level = Level(level: 1)
        level.objectId = "nice"

        var relation = score.relation("yolo", child: level)

        let expected = "{\"__type\":\"Relation\",\"className\":\"Level\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(relation)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)

        relation.className = "hello"
        let expected2 = "{\"__type\":\"Relation\",\"className\":\"hello\"}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(relation)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)

        var relation2 = score.relation("yolo", className: "Level")

        let expected3 = "{\"__type\":\"Relation\",\"className\":\"Level\"}"
        let encoded3 = try ParseCoding.jsonEncoder().encode(relation2)
        let decoded3 = try XCTUnwrap(String(data: encoded3, encoding: .utf8))
        XCTAssertEqual(decoded3, expected3)

        relation2.className = "hello"
        let expected4 = "{\"__type\":\"Relation\",\"className\":\"hello\"}"
        let encoded4 = try ParseCoding.jsonEncoder().encode(relation2)
        let decoded4 = try XCTUnwrap(String(data: encoded4, encoding: .utf8))
        XCTAssertEqual(decoded4, expected4)
    }

    func testInitWithChild() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId

        var level = Level(level: 1)
        level.objectId = "nice"
        var relation = ParseRelation<GameScore>(parent: score, child: level)

        let expected = "{\"__type\":\"Relation\",\"className\":\"Level\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(relation)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)

        relation.className = "hello"
        let expected2 = "{\"__type\":\"Relation\",\"className\":\"hello\"}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(relation)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
    }

    func testAddIncorrectClassError() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        relation.className = "hello"
        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try relation.add("level", objects: [level]))
    }

    func testAddIncorrectKeyError() throws {
        var score = GameScore(points: 10)
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
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className

        let operation = try relation.add("level", objects: [level])
        // swiftlint:disable:next line_length
        let expected = "{\"level\":{\"__op\":\"AddRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"nice\"}]}}"
        let encoded = try ParseCoding.jsonEncoder().encode(operation)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddOperationsNoKey() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className

        XCTAssertThrowsError(try relation.add([level]))
        relation.key = "level"
        let operation = try relation.add([level])
        // swiftlint:disable:next line_length
        let expected = "{\"level\":{\"__op\":\"AddRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"nice\"}]}}"
        let encoded = try ParseCoding.jsonEncoder().encode(operation)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddOperationsKeyCheck() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className
        relation.key = "level"

        let operation = try relation.add("level", objects: [level])
        // swiftlint:disable:next line_length
        let expected = "{\"level\":{\"__op\":\"AddRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"nice\"}]}}"
        let encoded = try ParseCoding.jsonEncoder().encode(operation)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testIsSameClassNone() throws {
        let score = GameScore(points: 10)
        let relation = score.relation
        XCTAssertFalse(relation.isSameClass([GameScore]()))
    }

    func testRemoveIncorrectClassError() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        relation.className = "hello"
        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try relation.remove("level", objects: [level]))
    }

    func testRemoveIncorrectKeyError() throws {
        var score = GameScore(points: 10)
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
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className

        let operation = try relation.remove("level", objects: [level])
        // swiftlint:disable:next line_length
        let expected = "{\"level\":{\"__op\":\"RemoveRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"nice\"}]}}"
        let encoded = try ParseCoding.jsonEncoder().encode(operation)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveOperationsNoKey() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className

        XCTAssertThrowsError(try relation.remove([level]))
        relation.key = "level"
        let operation = try relation.remove([level])
        // swiftlint:disable:next line_length
        let expected = "{\"level\":{\"__op\":\"RemoveRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"nice\"}]}}"
        let encoded = try ParseCoding.jsonEncoder().encode(operation)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveOperationsKeyCheck() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className
        relation.key = "level"

        let operation = try relation.remove("level", objects: [level])
        // swiftlint:disable:next line_length
        let expected = "{\"level\":{\"__op\":\"RemoveRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"nice\"}]}}"
        let encoded = try ParseCoding.jsonEncoder().encode(operation)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testQuery() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        var relation = score.relation
        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className

        // No Key, this should throw
        XCTAssertThrowsError(try relation.query(level))

        // No child for the relation, should throw
        XCTAssertThrowsError(try relation.query(score))

        // Wrong child for the relation, should throw
        relation.key = "naw"
        XCTAssertThrowsError(try relation.query(score))

        relation.key = "levels"
        let query = try relation.query(level)

        // swiftlint:disable:next line_length
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"$relatedTo\":{\"key\":\"levels\",\"object\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}}"
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)

        let query2 = try relation.query("wow", child: level)
        // swiftlint:disable:next line_length
        let expected2 = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"$relatedTo\":{\"key\":\"wow\",\"object\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(query2)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)

        let query3 = try level.relation.query("levels", parent: score)
        // swiftlint:disable:next line_length
        let expected3 = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"$relatedTo\":{\"key\":\"levels\",\"object\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}}"
        let encoded3 = try ParseCoding.jsonEncoder().encode(query3)
        let decoded3 = try XCTUnwrap(String(data: encoded3, encoding: .utf8))
        XCTAssertEqual(decoded3, expected3)
    }

    func testQueryStatic() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId

        let query = Level.queryRelations("levels", parent: try score.toPointer())
        // swiftlint:disable:next line_length
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"$relatedTo\":{\"key\":\"levels\",\"object\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}}"
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)

        let query2 = try Level.queryRelations("levels", parent: score)
        // swiftlint:disable:next line_length
        let expected2 = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"$relatedTo\":{\"key\":\"levels\",\"object\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(query2)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
    }
}
