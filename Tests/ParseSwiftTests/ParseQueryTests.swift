//
//  ParseQueryTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/26/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseQueryTests: XCTestCase { // swiftlint:disable:this type_body_length

    struct GameScore: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: Int

        //: a custom initializer
        init(score: Int) {
            self.score = score
        }
    }

    struct GameType: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
    }

    override func setUp() {
        super.setUp()
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

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.removeAll()
        #if !os(Linux)
        try? KeychainStore.shared.deleteAll()
        #endif
        try? ParseStorage.shared.deleteAll()
    }

    // MARK: Initialization
    func testConstructors() {
        let query = Query<GameScore>()
        XCTAssertEqual(query.className, GameScore.className)
        XCTAssertEqual(query.`where`.constraints.values.count, 0)

        let query2 = GameScore.query()
        XCTAssertEqual(query2.className, GameScore.className)
        XCTAssertEqual(query2.className, query.className)
        XCTAssertEqual(query2.`where`.constraints.values.count, 0)

        let query3 = GameScore.query("score" > 100, "createdAt" > Date())
        XCTAssertEqual(query3.className, GameScore.className)
        XCTAssertEqual(query3.className, query.className)
        XCTAssertEqual(query3.`where`.constraints.values.count, 2)

        let query4 = GameScore.query(["score" > 100, "createdAt" > Date()])
        XCTAssertEqual(query4.className, GameScore.className)
        XCTAssertEqual(query4.className, query.className)
        XCTAssertEqual(query4.`where`.constraints.values.count, 2)
    }

    func testEndPoints() {
        let query = Query<GameScore>()
        let userQuery = Query<BaseParseUser>()
        let installationQuery = Query<BaseParseInstallation>()
        XCTAssertEqual(query.endpoint.urlComponent, "/classes/GameScore")
        XCTAssertEqual(userQuery.endpoint.urlComponent, "/users")
        XCTAssertEqual(installationQuery.endpoint.urlComponent, "/installations")
    }

    func testStaticProperties() {
        XCTAssertEqual(Query<GameScore>.className, GameScore.className)
    }

    func testSkip() {
        let query = GameScore.query()
        XCTAssertEqual(query.skip, 0)
        _ = query.skip(1)
        XCTAssertEqual(query.skip, 1)
    }

    func testLimit() {
        let query = GameScore.query()
        XCTAssertEqual(query.limit, 100)
        _ = query.limit(10)
        XCTAssertEqual(query.limit, 10)
    }

    func testOrder() {
        let query = GameScore.query()
        XCTAssertNil(query.order)
        _ = query.order([.ascending("yolo")])
        XCTAssertNotNil(query.order)
    }

    func testReadPreferences() {
        let query = GameScore.query()
        XCTAssertNil(query.readPreference)
        XCTAssertNil(query.includeReadPreference)
        XCTAssertNil(query.subqueryReadPreference)
        _ = query.readPreference("PRIMARY",
                                                includeReadPreference: "SECONDARY",
                                                subqueryReadPreference: "SECONDARY_PREFERRED")
        XCTAssertNotNil(query.readPreference)
        XCTAssertNotNil(query.includeReadPreference)
        XCTAssertNotNil(query.subqueryReadPreference)
    }

    func testIncludeKeys() {
        let query = GameScore.query()
        XCTAssertNil(query.include)
        _ = query.include("yolo")
        XCTAssertEqual(query.include?.count, 1)
        XCTAssertEqual(query.include?.first, "yolo")
        _ = query.include("yolo", "wow")
        XCTAssertEqual(query.include?.count, 2)
        XCTAssertEqual(query.include, ["yolo", "wow"])
        _ = query.include(["yolo"])
        XCTAssertEqual(query.include?.count, 1)
        XCTAssertEqual(query.include, ["yolo"])
    }

    func testDistinct() throws {
        let query = GameScore.query()
            .distinct("yolo")

        let expected = "{\"limit\":100,\"skip\":0,\"distinct\":\"yolo\",\"_method\":\"GET\",\"where\":{}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(query)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testIncludeAllKeys() {
        let query = GameScore.query()
        XCTAssertNil(query.include)
        _ = query.includeAll()
        XCTAssertEqual(query.include?.count, 1)
        XCTAssertEqual(query.include, ["*"])
    }

    func testExcludeKeys() {
        let query = GameScore.query()
        XCTAssertNil(query.excludeKeys)
        _ = query.exclude(["yolo"])
        XCTAssertEqual(query.excludeKeys, ["yolo"])
        XCTAssertEqual(query.excludeKeys, ["yolo"])
    }

    func testSelectKeys() {
        let query = GameScore.query()
        XCTAssertNil(query.keys)
        _ = query.select("yolo")
        XCTAssertEqual(query.keys?.count, 1)
        XCTAssertEqual(query.keys?.first, "yolo")
        _ = query.select("yolo", "wow")
        XCTAssertEqual(query.keys?.count, 2)
        XCTAssertEqual(query.keys, ["yolo", "wow"])
        _ = query.select(["yolo"])
        XCTAssertEqual(query.keys?.count, 1)
        XCTAssertEqual(query.keys, ["yolo"])
    }

    func testAddingConstraints() {
        let query = GameScore.query()
        XCTAssertEqual(query.className, GameScore.className)
        XCTAssertEqual(query.className, query.className)
        XCTAssertEqual(query.`where`.constraints.values.count, 0)

        _ = query.`where`("score" > 100, "createdAt" > Date())
        XCTAssertEqual(query.`where`.constraints.values.count, 2)
    }

    // MARK: Querying Parse Server
    func testFind() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
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
        do {

            guard let score = try query.find(options: []).first else {
                XCTFail("Should unwrap first object found")
                return
            }
            XCTAssert(score.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }

    }

    // MARK: Querying Parse Server
    func testFindEncoded() throws {

        let afterDate = Date().addingTimeInterval(-300)
        let query = GameScore.query("createdAt" > afterDate)
        let encodedJSON = try ParseCoding.jsonEncoder().encode(query)
        let decodedJSON = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encodedJSON)
        let encodedParse = try ParseCoding.jsonEncoder().encode(query)
        let decodedParse = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encodedParse)

        guard let jsonSkipAny = decodedJSON["skip"],
              let jsonSkip = jsonSkipAny.value as? Int,
              let jsonMethodAny = decodedJSON["_method"],
              let jsonMethod = jsonMethodAny.value as? String,
              let jsonLimitAny = decodedJSON["limit"],
              let jsonLimit = jsonLimitAny.value as? Int,
              let jsonWhereAny = decodedJSON["where"],
              let jsonWhere = jsonWhereAny.value as? [String: [String: [String: String]]] else {
            XCTFail("Should have casted all")
            return
        }

        guard let parseSkipAny = decodedParse["skip"],
              let parseSkip = parseSkipAny.value as? Int,
              let parseMethodAny = decodedParse["_method"],
              let parseMethod = parseMethodAny.value as? String,
              let parseLimitAny = decodedParse["limit"],
              let parseLimit = parseLimitAny.value as? Int,
              let parseWhereAny = decodedParse["where"],
              let parseWhere = parseWhereAny.value as? [String: [String: [String: String]]] else {
            XCTFail("Should have casted all")
            return
        }

        XCTAssertEqual(jsonSkip, parseSkip, "Parse shoud always match JSON")
        XCTAssertEqual(jsonMethod, parseMethod, "Parse shoud always match JSON")
        XCTAssertEqual(jsonLimit, parseLimit, "Parse shoud always match JSON")
        XCTAssertEqual(jsonWhere, parseWhere, "Parse shoud always match JSON")
    }

    func findAsync(scoreOnServer: GameScore, callbackQueue: DispatchQueue) {
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.find(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testThreadSafeFindAsync() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
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

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            findAsync(scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }

    func testFindAsyncMainQueue() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
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
        findAsync(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testFirst() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
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
        do {

            guard let score = try query.first(options: []) else {
                XCTFail("Should unwrap first object found")
                return
            }
            XCTAssert(score.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }

    }

    func testFirstNoObjectFound() {

        let results = QueryResponse<GameScore>(results: [GameScore](), count: 0)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query()
        do {

            guard try query.first(options: []) == nil else {
                XCTFail("Should have thrown error")
                return
            }
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should have casted as ParseError")
                return
            }
            XCTAssertEqual(error.code.rawValue, 101)
        }

    }

    func firstAsyncNoObjectFound(scoreOnServer: GameScore, callbackQueue: DispatchQueue) {
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.first(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success:
                XCTFail("Should have failed")

            case .failure(let error):
                XCTAssertEqual(error.code.rawValue, 101)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func firstAsync(scoreOnServer: GameScore, callbackQueue: DispatchQueue) {
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.first(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let score):
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testThreadSafeFirstAsync() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
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

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            firstAsync(scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }

    func testFirstAsyncMainQueue() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
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
        firstAsync(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testThreadSafeFirstAsyncNoObjectFound() {
        let scoreOnServer = GameScore(score: 10)
        let results = QueryResponse<GameScore>(results: [GameScore](), count: 0)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            firstAsyncNoObjectFound(scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }

    func testFirstAsyncNoObjectFoundMainQueue() {
        let scoreOnServer = GameScore(score: 10)
        let results = QueryResponse<GameScore>(results: [GameScore](), count: 0)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        firstAsyncNoObjectFound(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testCount() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
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
        do {

            let scoreCount = try query.count(options: [])
            XCTAssertEqual(scoreCount, 1)
        } catch {
            XCTFail(error.localizedDescription)
        }

    }

    func countAsync(scoreOnServer: GameScore, callbackQueue: DispatchQueue) {
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.count(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let scoreCount):
                XCTAssertEqual(scoreCount, 1)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testThreadSafeCountAsync() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
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

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            countAsync(scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }

    func testCountAsyncMainQueue() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
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
        countAsync(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    // MARK: Standard Conditions
    func testWhereKeyExists() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$exists": true]
        ]
        let constraint = exists(key: "yolo")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Bool],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: Bool] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyDoesNotExist() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$exists": false]
        ]
        let constraint = doesNotExist(key: "yolo")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Bool],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: Bool] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyEqualTo() {
        let expected: [String: String] = [
            "yolo": "yarr"
        ]
        let query = GameScore.query("yolo" == "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decoded = try JSONDecoder().decode([String: String].self, from: encoded)

            XCTAssertEqual(expected, decoded)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNotEqualTo() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$ne": "yarr"]
        ]
        let query = GameScore.query("yolo" != "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyLessThan() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$lt": "yarr"]
        ]
        let query = GameScore.query("yolo" < "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyLessThanOrEqualTo() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$lte": "yarr"]
        ]
        let query = GameScore.query("yolo" <= "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyGreaterThan() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$gt": "yarr"]
        ]
        let query = GameScore.query("yolo" > "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyGreaterThanOrEqualTo() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$gte": "yarr"]
        ]
        let query = GameScore.query("yolo" >= "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesText() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$text": ["$search": ["$term": "yarr"]]]
        ]
        let constraint = matchesText(key: "yolo", text: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: [String: String]]],
                  let decodedValues = decodedDictionary.values.first?.value as?
                    [String: [String: [String: String]]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesRegex() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "yarr"]
        ]
        let constraint = matchesRegex(key: "yolo", regex: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesRegexModifiers() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$regex": "yarr",
                "$options": "i"
            ]
        ]
        let constraint = matchesRegex(key: "yolo", regex: "yarr", modifiers: "i")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyContainsString() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "\\Qyarr\\E"]
        ]
        let constraint = containsString(key: "yolo", substring: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyHasPrefix() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "^\\Qyarr\\E"]
        ]
        let constraint = hasPrefix(key: "yolo", prefix: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyHasSuffix() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "\\Qyarr\\E$"]
        ]
        let constraint = hasSuffix(key: "yolo", suffix: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testOrQuery() {
        let expected: [String: AnyCodable] = [
            "$or": [
                ["score": ["$lte": 50]],
                ["score": ["$lte": 200]]
            ]
        ]
        let query1 = GameScore.query("score" <= 50)
        let query2 = GameScore.query("score" <= 200)
        let constraint = or(queries: [query1, query2])
        let query = Query<GameScore>(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [[String: [String: Int]]],
                  let decodedValues = decodedDictionary.values.first?.value as? [[String: [String: Int]]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testAndQuery() {
        let expected: [String: AnyCodable] = [
            "$and": [
                ["score": ["$lte": 50]],
                ["score": ["$lte": 200]]
            ]
        ]
        let query1 = GameScore.query("score" <= 50)
        let query2 = GameScore.query("score" <= 200)
        let constraint = and(queries: [query1, query2])
        let query = Query<GameScore>(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [[String: [String: Int]]],
                  let decodedValues = decodedDictionary.values.first?.value as? [[String: [String: Int]]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesKeyInQuery() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$select": [
                    "query": ["where": ["test": ["$lte": "awk"]]],
                    "key": "yolo1"
                ]
            ]
        ]
        let inQuery = GameScore.query("test" <= "awk")
        let constraint = matchesKeyInQuery(key: "yolo", queryKey: "yolo1", query: inQuery)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedSelect = expectedValues["$select"],
                  let expectedKeyValue = expectedSelect["key"] as? String,
                  let expectedKeyQuery = expectedSelect["query"] as? [String: Any],
                  let expectedKeyWhere = expectedKeyQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedSelect = decodedValues["$select"],
                  let decodedKeyValue = decodedSelect["key"] as? String,
                  let decodedKeyQuery = decodedSelect["query"] as? [String: Any],
                  let decodedKeyWhere = decodedKeyQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKeyValue, decodedKeyValue)
            XCTAssertEqual(expectedKeyWhere, decodedKeyWhere)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyDoesNotMatchKeyInQuery() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$dontSelect": [
                    "query": ["where": ["test": ["$lte": "awk"]]],
                    "key": "yolo1"
                ]
            ]
        ]
        let inQuery = GameScore.query("test" <= "awk")
        let constraint = doesNotMatchKeyInQuery(key: "yolo", queryKey: "yolo1", query: inQuery)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedSelect = expectedValues["$dontSelect"],
                  let expectedKeyValue = expectedSelect["key"] as? String,
                  let expectedKeyQuery = expectedSelect["query"] as? [String: Any],
                  let expectedKeyWhere = expectedKeyQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedSelect = decodedValues["$dontSelect"],
                  let decodedKeyValue = decodedSelect["key"] as? String,
                  let decodedKeyQuery = decodedSelect["query"] as? [String: Any],
                  let decodedKeyWhere = decodedKeyQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKeyValue, decodedKeyValue)
            XCTAssertEqual(expectedKeyWhere, decodedKeyWhere)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesQuery() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$inQuery": [
                    "where": ["test": ["$lte": "awk"]]
                ]
            ]
        ]
        let inQuery = GameScore.query("test" <= "awk")
        let query = GameScore.query("yolo" == inQuery)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedInQuery = expectedValues["$inQuery"],
                  let expectedKeyWhere = expectedInQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedInQuery = decodedValues["$inQuery"],
                  let decodedKeyWhere = decodedInQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKeyWhere, decodedKeyWhere)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyDoesNotMatchQuery() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$notInQuery": [
                    "where": ["test": ["$lte": "awk"]]
                ]
            ]
        ]
        let inQuery = GameScore.query("test" <= "awk")
        let query = GameScore.query("yolo" != inQuery)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedInQuery = expectedValues["$notInQuery"],
                  let expectedKeyWhere = expectedInQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedInQuery = decodedValues["$notInQuery"],
                  let decodedKeyWhere = decodedInQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKeyWhere, decodedKeyWhere)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereContainedIn() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$in": ["yarr"]]
        ]
        let constraint = containedIn(key: "yolo", array: ["yarr"])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String]],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: [String]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereNotContainedIn() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nin": ["yarr"]]
        ]
        let constraint = notContainedIn(key: "yolo", array: ["yarr"])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String]],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: [String]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereContainsAll() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$all": ["yarr"]]
        ]
        let constraint = containsAll(key: "yolo", array: ["yarr"])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String]],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: [String]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyRelated() {
        let expected: [String: AnyCodable] = [
            "$relatedTo": [
                "key": "yolo",
                "object": ["score": 50]
            ]
        ]
        let object = GameScore(score: 50)
        let constraint = related(key: "yolo", parent: object)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedKey = expectedValues["key"] as? String,
                  let expectedObject = expectedValues["object"] as? [String: Int] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedKey = decodedValues["key"] as? String,
                  let decodedObject = decodedValues["object"] as? [String: Int] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKey, decodedKey)
            XCTAssertEqual(expectedObject, decodedObject)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    // MARK: GeoPoint
    func testWhereKeyNearGeoPoint() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nearSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"]]
        ]
        let geoPoint = ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = near(key: "yolo", geoPoint: geoPoint)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedLongitude = expectedValues["$nearSphere"]?["longitude"] as? Int,
                  let expectedLatitude = expectedValues["$nearSphere"]?["latitude"] as? Int,
                  let expectedType = expectedValues["$nearSphere"]?["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedLongitude = decodedValues["$nearSphere"]?["longitude"] as? Int,
                  let decodedLatitude = decodedValues["$nearSphere"]?["latitude"] as? Int,
                  let decodedType = decodedValues["$nearSphere"]?["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoPointWithinMiles() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nearSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"],
                     "$maxDistance": 1
            ]
        ]
        let geoPoint = ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinMiles(key: "yolo", geoPoint: geoPoint, distance: 3958.8)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$nearSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$nearSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoPointWithinKilometers() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nearSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"],
                     "$maxDistance": 1
            ]
        ]
        let geoPoint = ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinKilometers(key: "yolo", geoPoint: geoPoint, distance: 6371.0)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$nearSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$nearSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoPointWithinRadians() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nearSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"],
                     "$maxDistance": 10
            ]
        ]
        let geoPoint = ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinRadians(key: "yolo", geoPoint: geoPoint, distance: 10.0)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$nearSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$nearSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    // swiftlint:disable:next function_body_length
    func testWhereKeyNearGeoBox() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$within": ["$box": [
                                    ["latitude": 10, "longitude": 20, "__type": "GeoPoint"],
                                    ["latitude": 20, "longitude": 30, "__type": "GeoPoint"]]
                                ]
            ]
        ]
        let geoPoint1 = ParseGeoPoint(latitude: 10, longitude: 20)
        let geoPoint2 = ParseGeoPoint(latitude: 20, longitude: 30)
        let constraint = withinGeoBox(key: "yolo", fromSouthWest: geoPoint1, toNortheast: geoPoint2)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: [[String: Any]]]],
                  let expectedBox = expectedValues["$within"]?["$box"],
                  let expectedLongitude = expectedBox.first?["longitude"] as? Int,
                  let expectedLatitude = expectedBox.first?["latitude"] as? Int,
                  let expectedType = expectedBox.first?["__type"] as? String,
                  let expectedLongitude2 = expectedBox.last?["longitude"] as? Int,
                  let expectedLatitude2 = expectedBox.last?["latitude"] as? Int,
                  let expectedType2 = expectedBox.last?["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: [[String: Any]]]],
                  let decodedBox = decodedValues["$within"]?["$box"],
                  let decodedLongitude = decodedBox.first?["longitude"] as? Int,
                  let decodedLatitude = decodedBox.first?["latitude"] as? Int,
                  let decodedType = decodedBox.first?["__type"] as? String,
                  let decodedLongitude2 = decodedBox.last?["longitude"] as? Int,
                  let decodedLatitude2 = decodedBox.last?["latitude"] as? Int,
                  let decodedType2 = decodedBox.last?["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedLongitude2, decodedLongitude2)
            XCTAssertEqual(expectedLatitude2, decodedLatitude2)
            XCTAssertEqual(expectedType2, decodedType2)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    // swiftlint:disable:next function_body_length
    func testWhereKeyWithinPolygon() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$geoWithin": ["$polygon": [
                                    ["latitude": 10, "longitude": 20, "__type": "GeoPoint"],
                                    ["latitude": 20, "longitude": 30, "__type": "GeoPoint"],
                                    ["latitude": 30, "longitude": 40, "__type": "GeoPoint"]]
                                ]
            ]
        ]
        let geoPoint1 = ParseGeoPoint(latitude: 10, longitude: 20)
        let geoPoint2 = ParseGeoPoint(latitude: 20, longitude: 30)
        let geoPoint3 = ParseGeoPoint(latitude: 30, longitude: 40)
        let constraint = withinPolygon(key: "yolo", points: [geoPoint1, geoPoint2, geoPoint3])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: [[String: Any]]]],
                  let expectedBox = expectedValues["$geoWithin"]?["$polygon"],
                  let expectedLongitude = expectedBox.first?["longitude"] as? Int,
                  let expectedLatitude = expectedBox.first?["latitude"] as? Int,
                  let expectedType = expectedBox.first?["__type"] as? String,
                  let expectedLongitude2 = expectedBox[1]["longitude"] as? Int,
                  let expectedLatitude2 = expectedBox[1]["latitude"] as? Int,
                  let expectedType2 = expectedBox[1]["__type"] as? String,
                  let expectedLongitude3 = expectedBox.last?["longitude"] as? Int,
                  let expectedLatitude3 = expectedBox.last?["latitude"] as? Int,
                  let expectedType3 = expectedBox.last?["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: [[String: Any]]]],
                  let decodedBox = decodedValues["$geoWithin"]?["$polygon"],
                  let decodedLongitude = decodedBox.first?["longitude"] as? Int,
                  let decodedLatitude = decodedBox.first?["latitude"] as? Int,
                  let decodedType = decodedBox.first?["__type"] as? String,
                  let decodedLongitude2 = decodedBox[1]["longitude"] as? Int,
                  let decodedLatitude2 = decodedBox[1]["latitude"] as? Int,
                  let decodedType2 = decodedBox[1]["__type"] as? String,
                  let decodedLongitude3 = decodedBox.last?["longitude"] as? Int,
                  let decodedLatitude3 = decodedBox.last?["latitude"] as? Int,
                  let decodedType3 = decodedBox.last?["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedLongitude2, decodedLongitude2)
            XCTAssertEqual(expectedLatitude2, decodedLatitude2)
            XCTAssertEqual(expectedType2, decodedType2)
            XCTAssertEqual(expectedLongitude3, decodedLongitude3)
            XCTAssertEqual(expectedLatitude3, decodedLatitude3)
            XCTAssertEqual(expectedType3, decodedType3)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyPolygonContains() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$geoIntersects": ["$point":
                                    ["latitude": 10, "longitude": 20, "__type": "GeoPoint"]
                                ]
            ]
        ]
        let geoPoint = ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = polygonContains(key: "yolo", point: geoPoint)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: [String: Any]]],
                  let expectedNear = expectedValues["$geoIntersects"]?["$point"],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: [String: Any]]],
                  let decodedNear = decodedValues["$geoIntersects"]?["$point"],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    // MARK: JSON Responses
    func testExplainFindSynchronous() {
        let json = AnyResultsResponse(results: ["yolo": "yarr"])

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
        do {
            let queryResult = try query.find(explain: true)
            guard let response = queryResult.value as? [String: String],
                let expected = json.results?.value as? [String: String] else {
                XCTFail("Error: Should cast to string")
                return
            }
            XCTAssertEqual(response, expected)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testExplainFindAsynchronous() {
        let json = AnyResultsResponse(results: ["yolo": "yarr"])

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

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
        query.find(explain: true, callbackQueue: .main) { result in
            switch result {

            case .success(let queryResult):
                guard let response = queryResult.value as? [String: String],
                    let expected = json.results?.value as? [String: String] else {
                    XCTFail("Error: Should cast to string")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(response, expected)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testExplainFirstSynchronous() {
        let json = AnyResultsResponse(results: ["yolo": "yarr"])

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
        do {
            let queryResult = try query.first(explain: true)
            guard let response = queryResult.value as? [String: String],
                let expected = json.results?.value as? [String: String] else {
                XCTFail("Error: Should cast to string")
                return
            }
            XCTAssertEqual(response, expected)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testExplainFirstAsynchronous() {
        let json = AnyResultsResponse(results: ["yolo": "yarr"])

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

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
        query.first(explain: true, callbackQueue: .main) { result in
            switch result {

            case .success(let queryResult):
                guard let response = queryResult.value as? [String: String],
                    let expected = json.results?.value as? [String: String] else {
                    XCTFail("Error: Should cast to string")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(response, expected)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testExplainCountSynchronous() {
        let json = AnyResultsResponse(results: ["yolo": "yarr"])

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
        do {
            let queryResult = try query.count(explain: true)
            guard let response = queryResult.value as? [String: String],
                let expected = json.results?.value as? [String: String] else {
                XCTFail("Error: Should cast to string")
                return
            }
            XCTAssertEqual(response, expected)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testExplainCountAsynchronous() {
        let json = AnyResultsResponse(results: ["yolo": "yarr"])

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

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
        query.count(explain: true, callbackQueue: .main) { result in
            switch result {

            case .success(let queryResult):
                guard let response = queryResult.value as? [String: String],
                    let expected = json.results?.value as? [String: String] else {
                    XCTFail("Error: Should cast to string")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(response, expected)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testHintFindSynchronous() {
        let json = AnyResultsResponse(results: ["yolo": "yarr"])

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
        do {
            let queryResult = try query.find(explain: false, hint: "_id_")
            guard let response = queryResult.value as? [String: String],
                let expected = json.results?.value as? [String: String] else {
                XCTFail("Error: Should cast to string")
                return
            }
            XCTAssertEqual(response, expected)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testHintFindAsynchronous() {
        let json = AnyResultsResponse(results: ["yolo": "yarr"])

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

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
        query.find(explain: false, hint: "_id_", callbackQueue: .main) { result in
            switch result {

            case .success(let queryResult):
                guard let response = queryResult.value as? [String: String],
                    let expected = json.results?.value as? [String: String] else {
                    XCTFail("Error: Should cast to string")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(response, expected)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testHintFirstSynchronous() {
        let json = AnyResultsResponse(results: ["yolo": "yarr"])

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
        do {
            let queryResult = try query.first(explain: false, hint: "_id_")
            guard let response = queryResult.value as? [String: String],
                let expected = json.results?.value as? [String: String] else {
                XCTFail("Error: Should cast to string")
                return
            }
            XCTAssertEqual(response, expected)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testHintFirstAsynchronous() {
        let json = AnyResultsResponse(results: ["yolo": "yarr"])

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

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
        query.first(explain: false, hint: "_id_", callbackQueue: .main) { result in
            switch result {

            case .success(let queryResult):
                guard let response = queryResult.value as? [String: String],
                    let expected = json.results?.value as? [String: String] else {
                    XCTFail("Error: Should cast to string")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(response, expected)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testHintCountSynchronous() {
        let json = AnyResultsResponse(results: ["yolo": "yarr"])

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
        do {
            let queryResult = try query.count(explain: false, hint: "_id_")
            guard let response = queryResult.value as? [String: String],
                let expected = json.results?.value as? [String: String] else {
                XCTFail("Error: Should cast to string")
                return
            }
            XCTAssertEqual(response, expected)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testHintCountAsynchronous() {
        let json = AnyResultsResponse(results: ["yolo": "yarr"])

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

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
        query.count(explain: false, hint: "_id_", callbackQueue: .main) { result in
            switch result {

            case .success(let queryResult):
                guard let response = queryResult.value as? [String: String],
                    let expected = json.results?.value as? [String: String] else {
                    XCTFail("Error: Should cast to string")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(response, expected)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testAggregateCommand() throws {
        let query = GameScore.query()
        let pipeline = [[String: String]]()
        let aggregate = query.aggregateCommand(pipeline)

        let expected = "{\"path\":\"\\/aggregate\\/GameScore\",\"method\":\"POST\",\"body\":[]}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(aggregate)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testAggregate() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
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
        do {
            let pipeline = [[String: String]]()
            guard let score = try query.aggregate(pipeline).first else {
                XCTFail("Should unwrap first object found")
                return
            }
            XCTAssert(score.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAggregateWithWhere() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
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

        let query = GameScore.query("score" > 9)
        do {
            let pipeline = [[String: String]]()
            guard let score = try query.aggregate(pipeline).first else {
                XCTFail("Should unwrap first object found")
                return
            }
            XCTAssert(score.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAggregateAsyncMainQueue() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
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
        let expectation = XCTestExpectation(description: "Count object1")
        let pipeline = [[String: String]]()
        query.aggregate(pipeline, options: [], callbackQueue: .main) { result in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testAggregateWhereAsyncMainQueue() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
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
        let query = GameScore.query("score" > 9)
        let expectation = XCTestExpectation(description: "Count object1")
        let pipeline = [[String: String]]()
        query.aggregate(pipeline, options: [], callbackQueue: .main) { result in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }
}
// swiftlint:disable:this file_length
