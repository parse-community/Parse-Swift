//
//  ParseOperationAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency) && !os(Linux) && !os(Android)
import Foundation
import XCTest
@testable import ParseSwift

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
class ParseOperationAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length
    struct GameScore: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: Int?
        var player: String?

        init() { }
        //custom initializers
        init (objectId: String?) {
            self.objectId = objectId
        }
        init(score: Int) {
            self.score = score
            self.player = "Jen"
        }
        init(score: Int, name: String) {
            self.score = score
            self.player = name
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
        #if !os(Linux) && !os(Android)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    @MainActor
    func testSave() async throws {

        var score = GameScore(score: 10)
        score.objectId = "yarr"
        let operations = score.operation
            .increment("score", by: 1)

        var scoreOnServer = score
        scoreOnServer.score = 11
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            //Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let saved = try await operations.save()
        XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
        guard let savedUpdatedAt = saved.updatedAt else {
            XCTFail("Should unwrap dates")
            return
        }
        guard let originalUpdatedAt = scoreOnServer.updatedAt else {
            XCTFail("Should unwrap dates")
            return
        }
        XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
        XCTAssertNil(saved.ACL)
    }
}
#endif
