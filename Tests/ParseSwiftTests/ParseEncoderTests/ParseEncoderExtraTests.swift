//
//  ParseEncoderTests.swift
//  ParseSwiftTests
//
//  Created by Pranjal Satija on 8/7/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import XCTest
@testable import ParseSwift

class ParseEncoderTests: XCTestCase {
    struct GameScore: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var score: Double?

        //: ParseUser property
        var emailVerified: Bool?

        //: Your own properties
        var points: Int

        //: a custom initializer
        init() {
            self.points = 5
        }
        init(points: Int) {
            self.points = points
        }
    }

    struct Address: Codable {
        let street: String
        let city: String
    }

    struct Name: Codable {
        let first: String
        let last: String
    }

    struct Person: Codable {
        let addresses: [String: Address]
        let age: Int
        let name: Name
        let nicknames: [Name]
        let phoneNumbers: [String]
    }

    func referenceEncoding<T: Encodable>(for object: T) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        guard let encoding = try? encoder.encode(object) else {
            XCTFail("Couldn't get a reference encoding.")
            return Data()
        }

        return encoding
    }

    func testNestedContatiner() throws {
        var newACL = ParseACL()
        newACL.publicRead = true

        let jsonEncoded = try JSONEncoder().encode(newACL)
        let jsonDecoded = try ParseCoding.jsonDecoder().decode([String: [String: Bool]].self, from: jsonEncoded)

        let parseEncoded = try ParseCoding.parseEncoder().encode(newACL, skipKeys: .object)
        let parseDecoded = try ParseCoding.jsonDecoder().decode([String: [String: Bool]].self, from: parseEncoded)

        XCTAssertEqual(jsonDecoded.keys.count, parseDecoded.keys.count)
        XCTAssertEqual(jsonDecoded.values.count, parseDecoded.values.count)
        XCTAssertEqual(jsonDecoded["*"]?["read"], true)
        XCTAssertEqual(parseDecoded["*"]?["read"], true)
    }

    func testSkipKeysDefaultCodingKeys() throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        score.createdAt = Date()
        score.updatedAt = score.createdAt
        score.emailVerified = true

        let encodedJSON = try ParseCoding.jsonEncoder().encode(score)
        let decodedJSON = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encodedJSON)
        XCTAssertEqual(decodedJSON["points"]?.value as? Int, score.points)
        XCTAssertNotNil(decodedJSON["objectId"])
        XCTAssertNotNil(decodedJSON["createdAt"])
        XCTAssertNotNil(decodedJSON["updatedAt"])
        XCTAssertNotNil(decodedJSON["emailVerified"])

        //ParseEncoder
        let encoded = try ParseCoding.parseEncoder().encode(score, skipKeys: .object)
        let decoded = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encoded)
        XCTAssertEqual(decoded["points"]?.value as? Int, score.points)
        XCTAssertNil(decoded["objectId"])
        XCTAssertNil(decoded["createdAt"])
        XCTAssertNil(decoded["updatedAt"])
        XCTAssertNil(decoded["emailVerified"])
        XCTAssertNil(decoded["className"])
        XCTAssertNil(decoded["score"])
        XCTAssertNil(decoded["id"])

        let encoded2 = try ParseCoding.parseEncoder().encode(score, skipKeys: .customObjectId)
        let decoded2 = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encoded2)
        XCTAssertEqual(decoded2["points"]?.value as? Int, score.points)
        XCTAssertNotNil(decoded2["objectId"])
        XCTAssertNil(decoded2["createdAt"])
        XCTAssertNil(decoded2["updatedAt"])
        XCTAssertNil(decoded2["emailVerified"])
        XCTAssertNil(decoded2["className"])
        XCTAssertNil(decoded2["score"])
        XCTAssertNil(decoded2["id"])
    }

    func testSkipKeysDefaultCodingKeysWithScore() throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        score.createdAt = Date()
        score.updatedAt = score.createdAt
        score.emailVerified = true
        
        var encodedJSON = try ParseCoding.jsonEncoder().encode(score)
        var decodedJSON = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encodedJSON)
        decodedJSON["score"] = 0.99
        encodedJSON = try ParseCoding.jsonEncoder().encode(decodedJSON)
        decodedJSON = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encodedJSON)
        XCTAssertNotNil(decodedJSON["score"])
        score = try ParseCoding.jsonDecoder().decode(GameScore.self, from: encodedJSON)
        XCTAssertNotNil(score.score)

        //ParseEncoder
        let encoded = try ParseCoding.parseEncoder().encode(score, skipKeys: .object)
        let decoded = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encoded)
        XCTAssertNil(decoded["score"])

        let encoded2 = try ParseCoding.parseEncoder().encode(score, skipKeys: .customObjectId)
        let decoded2 = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encoded2)
        XCTAssertNil(decoded2["score"])
    }

    func testDateStringEncoding() throws {
        let jsonScore = "{\"createdAt\":\"2021-03-15T02:24:47.841Z\",\"points\":5}"
        guard let encoded = jsonScore.data(using: .utf8) else {
            XCTFail("Shuld have created data")
            return
        }
        XCTAssertNoThrow(try ParseCoding.jsonDecoder().decode(GameScore.self, from: encoded))
    }
}
