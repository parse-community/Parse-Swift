//
//  ParseMutationContainerTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/17/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseMutationContainerTests: XCTestCase {
    struct GameScore: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: Int

        //custom initializers
        init(score: Int) {
            self.score = score
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

    func testIncrement() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .increment("score", by: 1)
        let expected = "{\"score\":{\"amount\":1,\"__op\":\"Increment\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }
}
