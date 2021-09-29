//
//  ParseQueryAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(_Concurrency) && !os(Linux) && !os(Android)
import Foundation
import XCTest
@testable import ParseSwift

@available(macOS 12.0, iOS 15.0, macCatalyst 15.0, watchOS 9.0, tvOS 15.0, *)
class ParseQueryAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length
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

    struct AnyResultResponse<U: Codable>: Codable {
        let result: U
    }

    struct AnyResultsResponse<U: Codable>: Codable {
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
    func testFind() async throws {

        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.score = 11
        scoreOnServer.objectId = "yolo"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query()

        let found = try await query.find()
        guard let object = found.first else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssert(object.hasSameObjectId(as: scoreOnServer))
    }

    @MainActor
    func testFindAll() async throws {

        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = AnyResultsResponse(results: [scoreOnServer])
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let found = try await GameScore.query().findAll()
        guard let object = found.first else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssert(object.hasSameObjectId(as: scoreOnServer))
    }

    @MainActor
    func testFindExplain() async throws {

        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let query = GameScore.query()
        let queryResult: [[String: String]] = try await query.findExplain()
        XCTAssertEqual(queryResult, json.results)
    }

    @MainActor
    func testFirst() async throws {

        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.score = 11
        scoreOnServer.objectId = "yolo"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query()
        let found = try await query.first()
        XCTAssert(found.hasSameObjectId(as: scoreOnServer))
    }

    @MainActor
    func testFirstExplain() async throws {

        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let query = GameScore.query()

        let queryResult: [String: String] = try await query.firstExplain()
        XCTAssertEqual(queryResult, json.results.first)
    }

    @MainActor
    func testCount() async throws {

        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.score = 11
        scoreOnServer.objectId = "yolo"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query()

        let found = try await query.count()
        XCTAssertEqual(found, 1)
    }

    @MainActor
    func testCountExplain() async throws {

        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let query = GameScore.query()
        let queryResult: [[String: String]] = try await query.countExplain()
        XCTAssertEqual(queryResult, json.results)
    }

    @MainActor
    func testAggregate() async throws {

        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query()
        let pipeline = [[String: AnyEncodable]]()
        let found = try await query.aggregate(pipeline)
        guard let object = found.first else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssert(object.hasSameObjectId(as: scoreOnServer))
    }

    @MainActor
    func testAggregateExplain() async throws {

        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let query = GameScore.query()
        let pipeline = [[String: String]]()
        let queryResult: [[String: String]] = try await query.aggregateExplain(pipeline)
        XCTAssertEqual(queryResult, json.results)
    }

    @MainActor
    func testDistinct() async throws {

        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query()
        let found = try await query.distinct("hello")
        guard let object = found.first else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssert(object.hasSameObjectId(as: scoreOnServer))
    }

    @MainActor
    func testDistinctExplain() async throws {

        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let query = GameScore.query()
        let queryResult: [[String: String]] = try await query.distinctExplain("hello")
        XCTAssertEqual(queryResult, json.results)
    }
}
#endif
