//
//  ParseOperationAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseOperationAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length
    struct GameScore: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int?
        var player: String?

        init() { }
        //custom initializers
        init (objectId: String?) {
            self.objectId = objectId
        }
        init(points: Int) {
            self.points = points
            self.player = "Jen"
        }
        init(points: Int, name: String) {
            self.points = points
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

    @MainActor
    func testSave() async throws {

        var score = GameScore(points: 10)
        score.objectId = "yarr"
        let operations = score.operation
            .increment("points", by: 1)

        var scoreOnServer = score
        scoreOnServer.points = 11
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

    @MainActor
    func testSaveServerError() async throws {

        var score = GameScore(points: 10)
        score.objectId = "yarr"
        let operations = score.operation
            .increment("points", by: 1)

        let serverError = ParseError(code: .operationForbidden, message: "Test error")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverError)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            try await operations.save()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(parseError, serverError)
        }
    }

    @MainActor
    func testSaveNoObjectId() async throws {
        var score = GameScore()
        score.points = 10
        let operations = score.operation
            .increment("points", by: 1)

        do {
            try await operations.save()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(parseError.code, .missingObjectId)
        }
    }

    @MainActor
    func testSaveKeyPath() async throws { // swiftlint:disable:this function_body_length
        var score = GameScore()
        score.objectId = "yarr"
        let operations = try score.operation
            .set(\.points, to: 15)
            .set(\.player, to: "hello")

        var scoreOnServer = score
        scoreOnServer.points = 15
        scoreOnServer.player = "hello"
        scoreOnServer.updatedAt = Date()

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
        do {
            let saved = try await operations.save()
            XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
            XCTAssertEqual(saved, scoreOnServer)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testSaveKeyPathOtherTypeOperationsExist() async throws { // swiftlint:disable:this function_body_length
        var score = GameScore()
        score.objectId = "yarr"
        let operations = try score.operation
            .set(\.points, to: 15)
            .set(("player", \.player), to: "hello")

        do {
            try await operations.save()
            XCTFail("Should have failed")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("Cannot combine"))
        }
    }

    @MainActor
    func testSaveKeyPathNilOperationsExist() async throws { // swiftlint:disable:this function_body_length
        var score = GameScore()
        score.objectId = "yarr"
        let operations = try score.operation
            .set(\.points, to: 15)
            .set(("points", \.points), to: nil)

        do {
            try await operations.save()
            XCTFail("Should have failed")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("Cannot combine"))
        }
    }
}
#endif
