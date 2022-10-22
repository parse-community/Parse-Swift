//
//  ParseQueryAsyncTests.swift
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

class ParseQueryAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length
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
                              primaryKey: "primaryKey",
                              serverURL: url,
                              usingPostForQuery: true,
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
    func testFind() async throws {

        var scoreOnServer = GameScore(points: 10)
        scoreOnServer.points = 11
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

        let query = GameScore.query

        let found = try await query.find()
        guard let object = found.first else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssert(object.hasSameObjectId(as: scoreOnServer))
    }

    @MainActor
    func testWithCount() async throws {

        var scoreOnServer = GameScore(points: 10)
        scoreOnServer.points = 11
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

        let query = GameScore.query

        let found = try await query.withCount()
        guard let object = found.0.first else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertTrue(object.hasSameObjectId(as: scoreOnServer))
        XCTAssertEqual(found.1, 1)
    }

    @MainActor
    func testWithCountMissingCount() async throws {

        var scoreOnServer = GameScore(points: 10)
        scoreOnServer.points = 11
        scoreOnServer.objectId = "yolo"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: nil)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query

        let found = try await query.withCount()
        guard let object = found.0.first else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertTrue(object.hasSameObjectId(as: scoreOnServer))
        XCTAssertEqual(found.1, 0)
    }

    @MainActor
    func testWithCountLimitZero() async throws {

        var query = GameScore.query
        query.limit = 0
        let found = try await query.withCount()
        XCTAssertEqual(found.0.count, 0)
        XCTAssertEqual(found.1, 0)
    }

    @MainActor
    func testFindAll() async throws {

        var scoreOnServer = GameScore(points: 10)
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

        let found = try await GameScore.query.findAll()
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

        let query = GameScore.query
        let queryResult: [[String: String]] = try await query.findExplain()
        XCTAssertEqual(queryResult, json.results)
    }

    @MainActor
    func testFindExplainMongo() async throws {

        let json = AnyResultsMongoResponse(results: ["yolo": "yarr"])

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

        let query = GameScore.query
        let queryResult: [[String: String]] = try await query.findExplain(usingMongoDB: true)
        XCTAssertEqual(queryResult, [json.results])
    }

    @MainActor
    func testWithCountExplain() async throws {

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

        let query = GameScore.query
        let queryResult: [[String: String]] = try await query.withCountExplain()
        XCTAssertEqual(queryResult, json.results)
    }

    @MainActor
    func testWithCountExplainMongo() async throws {

        let json = AnyResultsMongoResponse(results: ["yolo": "yarr"])

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

        let query = GameScore.query
        let queryResult: [[String: String]] = try await query.withCountExplain(usingMongoDB: true)
        XCTAssertEqual(queryResult, [json.results])
    }

    @MainActor
    func testWithCountExplainLimitZero() async throws {

        var query = GameScore.query
        query.limit = 0
        let found: [[String: String]] = try await query.withCountExplain()
        XCTAssertEqual(found.count, 0)
    }

    @MainActor
    func testFirst() async throws {

        var scoreOnServer = GameScore(points: 10)
        scoreOnServer.points = 11
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

        let query = GameScore.query
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

        let query = GameScore.query

        let queryResult: [String: String] = try await query.firstExplain()
        XCTAssertEqual(queryResult, json.results.first)
    }

    @MainActor
    func testFirstExplainMongo() async throws {

        let json = AnyResultsMongoResponse(results: ["yolo": "yarr"])

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

        let query = GameScore.query

        let queryResult: [String: String] = try await query.firstExplain(usingMongoDB: true)
        XCTAssertEqual(queryResult, json.results)
    }

    @MainActor
    func testCount() async throws {

        var scoreOnServer = GameScore(points: 10)
        scoreOnServer.points = 11
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

        let query = GameScore.query

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

        let query = GameScore.query
        let queryResult: [[String: String]] = try await query.countExplain()
        XCTAssertEqual(queryResult, json.results)
    }

    @MainActor
    func testCountExplainMongo() async throws {

        let json = AnyResultsMongoResponse(results: ["yolo": "yarr"])

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

        let query = GameScore.query
        let queryResult: [[String: String]] = try await query.countExplain(usingMongoDB: true)
        XCTAssertEqual(queryResult, [json.results])
    }

    @MainActor
    func testAggregate() async throws {

        var scoreOnServer = GameScore(points: 10)
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

        let query = GameScore.query
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

        let query = GameScore.query
        let pipeline = [[String: String]]()
        let queryResult: [[String: String]] = try await query.aggregateExplain(pipeline)
        XCTAssertEqual(queryResult, json.results)
    }

    @MainActor
    func testAggregateExplainMongo() async throws {

        let json = AnyResultsMongoResponse(results: ["yolo": "yarr"])

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

        let query = GameScore.query
        let pipeline = [[String: String]]()
        let queryResult: [[String: String]] = try await query.aggregateExplain(pipeline,
                                                                               usingMongoDB: true)
        XCTAssertEqual(queryResult, [json.results])
    }

    @MainActor
    func testDistinct() async throws {

        var scoreOnServer = GameScore(points: 10)
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

        let query = GameScore.query
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

        let query = GameScore.query
        let queryResult: [[String: String]] = try await query.distinctExplain("hello")
        XCTAssertEqual(queryResult, json.results)
    }

    @MainActor
    func testDistinctExplainMongo() async throws {

        let json = AnyResultsMongoResponse(results: ["yolo": "yarr"])

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

        let query = GameScore.query
        let queryResult: [[String: String]] = try await query.distinctExplain("hello",
                                                                              usingMongoDB: true)
        XCTAssertEqual(queryResult, [json.results])
    }
}
#endif
