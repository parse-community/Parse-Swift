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
        try KeychainStore.shared.deleteAll()
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
}
