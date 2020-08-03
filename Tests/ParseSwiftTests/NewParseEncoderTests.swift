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
    struct Complex: Codable {
        let str: String
        let int: Int
        let arr: [Int]
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
            arr: [1, 2, 3]
        ))

        do {
            let encoded = try NewParseEncoder().encode(score)
            print(encoded)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
