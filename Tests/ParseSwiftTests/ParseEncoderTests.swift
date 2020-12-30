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
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: Int

        //: a custom initializer
        init(score: Int) {
            self.score = score
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
/*
    func parseEncoding<T: Encodable>(for object: T) -> Data {
        let encoder = ParseEncoder()
        encoder.jsonEncoder.outputFormatting = .sortedKeys

        guard let encoding = try? encoder.encode(object) else {
            XCTFail("Couldn't get a Parse encoding.")
            return Data()
        }

        return encoding
    }*/

    func referenceEncoding<T: Encodable>(for object: T) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        guard let encoding = try? encoder.encode(object) else {
            XCTFail("Couldn't get a reference encoding.")
            return Data()
        }

        return encoding
    }
/*
    func test_encodingScalarValue() {
        let encoded = parseEncoding(for: ["<root>": 5])
        let reference = referenceEncoding(for: ["<root>": 5])
        XCTAssertEqual(encoded, reference)
    }

    func test_encodingComplexValue() {
        let value = Person(
            addresses: [
                "home": Address(street: "Parse St.", city: "San Francisco"),
                "work": Address(street: "Server Ave.", city: "Seattle")
            ],
            age: 21,
            name: Name(first: "Parse", last: "User"),
            nicknames: [
                Name(first: "Swift", last: "Developer"),
                Name(first: "iOS", last: "Engineer")
            ],
            phoneNumbers: [
                "1-800-PARSE",
                "1-999-SWIFT"
            ]
        )

        let encoded = parseEncoding(for: value)
        let reference = referenceEncoding(for: value)
        XCTAssertEqual(encoded.count, reference.count)
    }

    func testNestedContatiner() throws {
        var newACL = ParseACL()
        newACL.publicRead = true

        let jsonEncoded = try JSONEncoder().encode(newACL)
        let jsonDecoded = try ParseCoding.jsonDecoder().decode([String: [String: Bool]].self, from: jsonEncoded)

        let parseEncoded = try ParseCoding.parseEncoder().encode(newACL)
        let parseDecoded = try ParseCoding.jsonDecoder().decode([String: [String: Bool]].self, from: parseEncoded)

        XCTAssertEqual(jsonDecoded.keys.count, parseDecoded.keys.count)
        XCTAssertEqual(jsonDecoded.values.count, parseDecoded.values.count)
        XCTAssertEqual(jsonDecoded["*"]?["read"], true)
        XCTAssertEqual(parseDecoded["*"]?["read"], true)
    }
*/
    func testSkipKeysDefaultCodingKeys() throws {
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        score.createdAt = Date()
        score.updatedAt = Date()

        let encodedJSON = try ParseCoding.jsonEncoder().encode(score)
        let decodedJSON = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encodedJSON)
        XCTAssertEqual(decodedJSON["score"]?.value as? Int, score.score)
        XCTAssertNotNil(decodedJSON["createdAt"])
        XCTAssertNotNil(decodedJSON["updatedAt"])

        //ParseEncoder
        let encoded = try ParseCoding.parseEncoder().encode(score)
        let decoded = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encoded)
        XCTAssertEqual(decoded["score"]?.value as? Int, score.score)
        XCTAssertNil(decoded["createdAt"])
        XCTAssertNil(decoded["updatedAt"])
        XCTAssertNil(decoded["className"])
    }
}
