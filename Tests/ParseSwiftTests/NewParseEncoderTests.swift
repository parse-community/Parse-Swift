//
//  NewParseEncoderTests.swift
//  ParseSwiftTests
//
//  Created by Pranjal Satija on 8/3/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest

@testable import ParseSwift

class NewParseEncoderTests: XCTestCase {
    struct NestedComplex: Codable {
        let str: String
        let int: Int
        let arr: [Int]
        let nestedArr: [[Int]]
    }

    struct Complex: Codable {
        let str: String
        let int: Int
        let arr: [Int]
        let nestedArr: [[Int]]
        let nestedComplex: NestedComplex
    }

    struct GameScore: ParseObject {
        var ACL: ACL?
        var createdAt: Date?
        var objectId: String?
        var updatedAt: Date?
        var score: Int?
        var complex: Complex
    }

    func test_thatItWorks() {
        let score = GameScore(ACL: nil, createdAt: nil, objectId: "test", updatedAt: nil, score: 5, complex: Complex(
            str: "yeeee",
            int: 50,
            arr: [1, 2, 3],
            nestedArr: [[1], [2], [3]],
            nestedComplex: NestedComplex(
                str: "yooooo", int: 60, arr: [4, 5, 6], nestedArr: [[4], [5], [6]]
            )
        ))

        do {
            let encoded = try NewParseEncoder().encode(score)
            print(encoded)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
