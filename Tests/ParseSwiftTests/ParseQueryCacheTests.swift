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

// swiftlint:disable line_length

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
                              primaryKey: "primaryKey",
                              serverURL: url,
                              usingEqualQueryConstraint: false,
                              usingPostForQuery: false,
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        ParseSwift.clearCache()
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
            .hint("right")
            .readPreference("now")

        let queryParameters = try query.getQueryParameters()
        guard let whereParameter = queryParameters["where"],
            let orderParameter = queryParameters["order"],
            let skipParameter = queryParameters["skip"],
            let excludeKeysParameter = queryParameters["excludeKeys"],
            let limitParameter = queryParameters["limit"],
            let keysParameter = queryParameters["keys"],
            let includeParameter = queryParameters["include"],
            let hintParameter = queryParameters["hint"],
            let readPreferenceParameter = queryParameters["readPreference"] else {
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
        XCTAssertTrue(hintParameter.contains("\"right\""))
        XCTAssertTrue(readPreferenceParameter.contains("\"now\""))
    }

    func testAggregateQueryParameters() throws {
        var query = GameScore.query
            .order([.ascending("points"), .descending("oldScore")])
            .exclude("hello", "world")
            .include("foo", "bar")
            .select("yolo", "nolo")
            .hint("right")

        query.includeReadPreference = "now"
        query.explain = true
        query.pipeline = [["yo": "no"]]

        let aggregate = Query<GameScore>.AggregateBody(query: query)

        let queryParameters = try aggregate.getQueryParameters()
        guard let explainParameter = queryParameters["explain"],
            let pipelineParameter = queryParameters["pipeline"],
            let hintParameter = queryParameters["hint"],
            let readPreferenceParameter = queryParameters["includeReadPreference"] else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertTrue(explainParameter.contains("true"))
        XCTAssertTrue(pipelineParameter.contains("\"yo"))
        XCTAssertTrue(pipelineParameter.contains("\"no"))
        XCTAssertTrue(hintParameter.contains("\"right\""))
        XCTAssertTrue(readPreferenceParameter.contains("\"now\""))
    }

#if compiler(>=5.5.2) && canImport(_Concurrency)
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let found2 = try await query.withCount(options: [.cachePolicy(.returnCacheDataDontLoad)])
        guard let object2 = found2.0.first else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertTrue(object2.hasSameObjectId(as: scoreOnServer))
        XCTAssertEqual(found2.1, 1)
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let found2 = try await query.withCount(options: [.cachePolicy(.returnCacheDataDontLoad)])
        guard let object2 = found2.0.first else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertTrue(object2.hasSameObjectId(as: scoreOnServer))
        XCTAssertEqual(found2.1, 0)
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let found2 = try await GameScore.query.findAll(options: [.cachePolicy(.returnCacheDataDontLoad)])
        guard let object2 = found2.first else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssert(object2.hasSameObjectId(as: scoreOnServer))
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let queryResult2: [[String: String]] = try await query.findExplain(options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(queryResult2, json.results)
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let queryResult2: [[String: String]] = try await query.findExplain(usingMongoDB: true,
                                                                           options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(queryResult2, [json.results])
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let queryResult2: [[String: String]] = try await query.withCountExplain(options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(queryResult2, json.results)
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let queryResult2: [[String: String]] = try await query.withCountExplain(usingMongoDB: true,
                                                                                options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(queryResult2, [json.results])
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let found2 = try await query.first(options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssert(found2.hasSameObjectId(as: scoreOnServer))
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let queryResult2: [String: String] = try await query.firstExplain(options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(queryResult2, json.results.first)
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let queryResult2: [String: String] = try await query.firstExplain(usingMongoDB: true,
                                                                          options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(queryResult2, json.results)
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let found2 = try await query.count(options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(found2, 1)
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let queryResult2: [[String: String]] = try await query.countExplain(options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(queryResult2, json.results)
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let queryResult2: [[String: String]] = try await query.countExplain(usingMongoDB: true,
                                                                            options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(queryResult2, [json.results])
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let found2 = try await query.aggregate(pipeline,
                                               options: [.cachePolicy(.returnCacheDataDontLoad)])
        guard let object2 = found2.first else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssert(object2.hasSameObjectId(as: scoreOnServer))
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let queryResult2: [[String: String]] = try await query.aggregateExplain(pipeline,
                                                                                options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(queryResult2, json.results)
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let queryResult2: [[String: String]] = try await query.aggregateExplain(pipeline,
                                                                                usingMongoDB: true,
                                                                                options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(queryResult2, [json.results])
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let found2 = try await query.distinct("hello",
                                              options: [.cachePolicy(.returnCacheDataDontLoad)])
        guard let object2 = found2.first else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssert(object2.hasSameObjectId(as: scoreOnServer))
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let queryResult2: [[String: String]] = try await query.distinctExplain("hello",
                                                                               options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(queryResult2, json.results)
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let queryResult2: [[String: String]] = try await query.distinctExplain("hello",
                                                                               usingMongoDB: true,
                                                                               options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(queryResult2, [json.results])
    }
#endif
}
