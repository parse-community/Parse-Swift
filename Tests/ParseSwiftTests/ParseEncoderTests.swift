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

    func parseEncoding<T: Encodable>(for object: T) -> Data {
        let encoder = ParseEncoder()
        encoder.jsonEncoder.outputFormatting = .sortedKeys

        guard let encoding = try? encoder.encode(object) else {
            XCTFail("Couldn't get a Parse encoding.")
            return Data()
        }

        return encoding
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

    func test_encodingScalarValue() {
        let encoded = parseEncoding(for: 5)
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
        XCTAssertEqual(encoded, reference)
    }
}
