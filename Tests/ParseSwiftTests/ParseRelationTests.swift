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
        var originalData: Data?

        //: Your own properties
        var points: Int
        var members = [String]()
        var levels: ParseRelation<Self>?

        //custom initializers
        init() {
            self.points = 5
        }
        init(points: Int) {
            self.points = points
        }
    }

    struct GameScore2: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int
        var members = [String]()
        var levels: ParseRelation<Self>?

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
        var originalData: Data?

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
                              primaryKey: "primaryKey",
                              serverURL: url,
                              testing: true)
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
        guard var relation = score.relation else {
            XCTFail("Should have unwrapped")
            return
        }

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
                       "{\"__type\":\"Relation\",\"className\":\"hello\"}")
        XCTAssertEqual(relation.description,
                       "{\"__type\":\"Relation\",\"className\":\"hello\"}")
    }

    func testParseObjectRelation() throws {
        var score = GameScore(points: 10)
        var level = Level(level: 1)
        level.objectId = "nice"

        // Should not produce a relation without an objectId.
        XCTAssertThrowsError(try score.relation("yolo", child: level))

        let objectId = "hello"
        score.objectId = objectId
        var relation = try score.relation("yolo", child: level)

        let expected = "{\"__type\":\"Relation\",\"className\":\"Level\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(relation)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)

        relation.className = "hello"
        let expected2 = "{\"__type\":\"Relation\",\"className\":\"hello\"}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(relation)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)

        var relation2 = try score.relation("yolo", className: "Level")

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
        var relation = try ParseRelation<GameScore>(parent: score, child: level)

        let expected = "{\"__type\":\"Relation\",\"className\":\"Level\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(relation)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)

        relation.className = "hello"
        let expected2 = "{\"__type\":\"Relation\",\"className\":\"hello\"}"
        let encoded2 = try ParseCoding.jsonEncoder().encode(relation)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)

        _ = try ParseRelation<GameScore>(parent: score,
                                         key: "yolo",
                                         child: try level.toPointer())
    }

    func testAddIncorrectClassError() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        guard var relation = score.relation else {
            XCTFail("Should have unwrapped")
            return
        }
        relation.className = "hello"
        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try relation.add("level", objects: [level]))
    }

    func testAddIncorrectKeyError() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        guard var relation = score.relation else {
            XCTFail("Should have unwrapped")
            return
        }
        relation.className = "Level"
        relation.key = "test"
        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try relation.add("level", objects: [level]))
    }

    func testAddOperation() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        guard var relation = score.relation else {
            XCTFail("Should have unwrapped")
            return
        }
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

    func testAddOpperationNoObjectId() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId

        var relation = try ParseRelation(parent: score, key: "yolo")
        relation.parent = nil // This will happen with decoded ParseRelations

        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className

        // Should not produce a relation without an objectId.
        XCTAssertThrowsError(try relation.add([level]))
        XCTAssertThrowsError(try relation.add("yolo", objects: [level]))
    }

    func testAddOperationNoKey() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        guard var relation = score.relation else {
            XCTFail("Should have unwrapped")
            return
        }
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

    func testAddOperationKeyCheck() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        guard var relation = score.relation else {
            XCTFail("Should have unwrapped")
            return
        }
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
        var score = GameScore(points: 10)
        score.objectId = "yolo"
        guard let relation = score.relation else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertFalse(relation.isSameClass([GameScore]()))
    }

    func testRemoveIncorrectClassError() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        guard var relation = score.relation else {
            XCTFail("Should have unwrapped")
            return
        }
        relation.className = "hello"
        var level = Level(level: 1)
        level.objectId = "nice"
        XCTAssertThrowsError(try relation.remove("level", objects: [level]))
    }

    func testRemoveIncorrectKeyError() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        guard var relation = score.relation else {
            XCTFail("Should have unwrapped")
            return
        }
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
        guard var relation = score.relation else {
            XCTFail("Should have unwrapped")
            return
        }
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

    func testRemoveOpperationNoObjectId() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId

        var relation = try ParseRelation(parent: score, key: "yolo")
        relation.parent = nil // This will happen with decoded ParseRelations

        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className

        // Should not produce a relation without an objectId.
        XCTAssertThrowsError(try relation.remove([level]))
        XCTAssertThrowsError(try relation.remove("yolo", objects: [level]))
    }

    func testRemoveOperationsNoKey() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        guard var relation = score.relation else {
            XCTFail("Should have unwrapped")
            return
        }
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
        guard var relation = score.relation else {
            XCTFail("Should have unwrapped")
            return
        }
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
        guard var relation = score.relation else {
            XCTFail("Should have unwrapped")
            return
        }
        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className

        // No Key, this should throw
        do {
            let _: Query<Level> = try relation.query()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }

        do {
            let _: Query<GameScore> = try relation.query()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }

        // Wrong child for the relation, should throw
        relation.key = "naw"
        do {
            let _: Query<GameScore> = try relation.query()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }

        relation.key = "levels"
        do {
            let query: Query<Level> = try relation.query()
            // swiftlint:disable:next line_length
            let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"$relatedTo\":{\"key\":\"levels\",\"object\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}}"
            let encoded = try ParseCoding.jsonEncoder().encode(query)
            let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
            XCTAssertEqual(decoded, expected)

            let query2: Query<Level> = try relation.query("wow")
            // swiftlint:disable:next line_length
            let expected2 = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"$relatedTo\":{\"key\":\"wow\",\"object\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}}"
            let encoded2 = try ParseCoding.jsonEncoder().encode(query2)
            let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
            XCTAssertEqual(decoded2, expected2)

            guard let query3 = try level.relation?.query("levels", parent: score) else {
                XCTFail("Should have unwrapped")
                return
            }
            // swiftlint:disable:next line_length
            let expected3 = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"$relatedTo\":{\"key\":\"levels\",\"object\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}}"
            let encoded3 = try ParseCoding.jsonEncoder().encode(query3)
            let decoded3 = try XCTUnwrap(String(data: encoded3, encoding: .utf8))
            XCTAssertEqual(decoded3, expected3)
        } catch {
            XCTFail("Should not have thrown error")
        }
    }

    func testQueryNoObjectId() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId

        var relation = try ParseRelation(parent: score, key: "yolo")
        relation.parent = nil // This will happen with decoded ParseRelations

        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className

        // Should not produce a relation without an objectId.
        do {
            let _: Query<Level> = try relation.query()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }
        do {
            let _: Query<Level> = try relation.query("yolo")
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }
    }

    func testQueryStoredRelationParentSelf() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId

        var relation = try ParseRelation(parent: score)
        relation.parent = nil // This will happen with decoded ParseRelations

        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className

        do {
            let usableStoredRelation = try score.relation(relation, key: "levels")
            let query: Query<Level> = try usableStoredRelation.query()
            // swiftlint:disable:next line_length
            let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"$relatedTo\":{\"key\":\"levels\",\"object\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}}"
            let encoded = try ParseCoding.jsonEncoder().encode(query)
            let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
            XCTAssertEqual(decoded, expected)
        } catch {
            XCTFail("Should not have thrown error")
        }
    }

    func testQueryStoredRelation() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId

        var score2 = GameScore2(points: 15)
        let objectId2 = "yolo"
        score2.objectId = objectId2

        var relation = try ParseRelation(parent: score2)
        relation.parent = nil // This will happen with decoded ParseRelations

        var level = Level(level: 1)
        level.objectId = "nice"
        relation.className = level.className

        XCTAssertThrowsError(try score.relation(nil, key: "levels", with: score2))

        do {
            let usableStoredRelation = try score.relation(relation, key: "levels", with: score2)
            let query: Query<Level> = try usableStoredRelation.query()
            // swiftlint:disable:next line_length
            let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"$relatedTo\":{\"key\":\"levels\",\"object\":{\"__type\":\"Pointer\",\"className\":\"GameScore2\",\"objectId\":\"yolo\"}}}}"
            let encoded = try ParseCoding.jsonEncoder().encode(query)
            let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
            XCTAssertEqual(decoded, expected)
        } catch {
            XCTFail("Should not have thrown error")
        }
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
