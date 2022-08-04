//
//  ParseQueryCacheTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 8/4/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseQueryCacheTests: XCTestCase { // swiftlint:disable:this type_body_length

    struct GameScore: ParseObject, ParseQueryScorable {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var score: Double?
        var originalData: Data?

        //: Your own properties
        var points: Int
        var isCounts: Bool?

        //: a custom initializer
        init() {
            self.points = 5
        }
        init(points: Int) {
            self.points = points
        }
    }

    struct GameScoreBroken: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        var points: Int?
    }

    struct AnyResultsResponse<U: Codable>: Codable {
        let results: [U]
    }

    struct AnyResultsMongoResponse<U: Codable>: Codable {
        let results: U
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
                              usingEqualQueryConstraint: false,
                              usingPostForQuery: false,
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

    func testQueryParameters() throws {
        let query = GameScore.query
            .order([.ascending("points"), .descending("oldScore")])
            .exclude("hello", "world")
            .include("foo", "bar")
            .select("yolo", "nolo")
        let queryParameters = try query.getQueryParameters()
        guard let whereParameter = queryParameters["where"],
            let orderParameter = queryParameters["order"],
            let skipParameter = queryParameters["skip"],
            let excludeKeysParameter = queryParameters["excludeKeys"],
            let limitParameter = queryParameters["limit"],
            let keysParameter = queryParameters["keys"],
            let includeParameter = queryParameters["include"] else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertTrue(whereParameter.contains("{}"))
        XCTAssertTrue(orderParameter.contains("\"points"))
        XCTAssertTrue(orderParameter.contains("\"-oldScore"))
        XCTAssertTrue(skipParameter.contains("0"))
        XCTAssertTrue(excludeKeysParameter.contains("\"hello"))
        XCTAssertTrue(excludeKeysParameter.contains("\"world"))
        XCTAssertTrue(limitParameter.contains("100"))
        XCTAssertTrue(keysParameter.contains("\"nolo"))
        XCTAssertTrue(keysParameter.contains("\"yolo"))
        XCTAssertTrue(includeParameter.contains("\"foo\""))
        XCTAssertTrue(includeParameter.contains("\"bar\""))
    }
}
