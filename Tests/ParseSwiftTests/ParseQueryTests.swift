//
//  ParseQueryTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/26/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//
#if !os(watchOS)
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

    override func setUp() {
        super.setUp()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url)
    }

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.removeAll()
        try? KeychainStore.shared.deleteAll()
        try? ParseStorage.shared.deleteAll()
    }

    func testConstructors() {
        let query = Query<GameScore>()
        XCTAssertEqual(query.className, GameScore.className)

        let query2 = GameScore.query()
        XCTAssertEqual(query2.className, GameScore.className)
        XCTAssertEqual(query2.className, query.className)

        let query3 = GameScore.query("score" > 100, "createdAt" > Date())
        XCTAssertEqual(query3.className, GameScore.className)
        XCTAssertEqual(query3.className, query.className)

        let query4 = GameScore.query(["score" > 100, "createdAt" > Date()])
        XCTAssertEqual(query4.className, GameScore.className)
        XCTAssertEqual(query4.className, query.className)
    }

    func testFind() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        let results = FindResult<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(results)
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
        wait(for: [expectation], timeout: 10.0)
    }

    func testThreadSafeFindAsync() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        let results = FindResult<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(results)
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

        let results = FindResult<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(results)
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

        let results = FindResult<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(results)
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
        wait(for: [expectation], timeout: 10.0)
    }

    func testThreadSafeFirstAsync() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        let results = FindResult<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(results)
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

        let results = FindResult<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        firstAsync(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testCount() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        let results = FindResult<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(results)
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
        wait(for: [expectation], timeout: 10.0)
    }

    func testThreadSafeCountAsync() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        let results = FindResult<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(results)
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

        let results = FindResult<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        countAsync(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testWhereKeyNearGeoPoint() {
        let geoPoint = GeoPoint(latitude: 10, longitude: 20)
        let constraint = near(key: "yolo", geoPoint: geoPoint)
        let query = GameScore.query(constraint)
        let queryConstraints = query.`where`.constraints

        guard let testConstraints = queryConstraints["yolo"]?.first else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints.comparator.rawValue, "$nearSphere")

        guard let testValue = testConstraints.value as? GeoPoint else {
            XCTFail("Should have casted to GeoPoint")
            return
        }
        XCTAssertEqual(testValue, geoPoint)
    }

    func testWhereKeyNearGeoPointWithinMiles() {
        let geoPoint = GeoPoint(latitude: 10, longitude: 20)
        let constraint = withinMiles(key: "yolo", geoPoint: geoPoint, distance: 3958.8)
        let query = GameScore.query(constraint)
        let queryConstraints = query.`where`.constraints

        guard let testConstraints = queryConstraints["yolo"]?.first else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints.comparator.rawValue, "$nearSphere")

        guard let testValue = testConstraints.value as? GeoPoint else {
            XCTFail("Should have casted to GeoPoint")
            return
        }
        XCTAssertEqual(testValue, geoPoint)

        guard let testConstraints2 = queryConstraints["yolo"]?.last else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints2.comparator.rawValue, "$maxDistance")

        guard let testValue2 = testConstraints2.value as? Double else {
            XCTFail("Should have casted to Double")
            return
        }
        XCTAssertEqual(testValue2, 1.0)
    }

    func testWhereKeyNearGeoPointWithinKilometers() {
        let geoPoint = GeoPoint(latitude: 10, longitude: 20)
        let constraint = withinKilometers(key: "yolo", geoPoint: geoPoint, distance: 6371.0)
        let query = GameScore.query(constraint)
        let queryConstraints = query.`where`.constraints

        guard let testConstraints = queryConstraints["yolo"]?.first else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints.comparator.rawValue, "$nearSphere")

        guard let testValue = testConstraints.value as? GeoPoint else {
            XCTFail("Should have casted to GeoPoint")
            return
        }
        XCTAssertEqual(testValue, geoPoint)

        guard let testConstraints2 = queryConstraints["yolo"]?.last else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints2.comparator.rawValue, "$maxDistance")

        guard let testValue2 = testConstraints2.value as? Double else {
            XCTFail("Should have casted to Double")
            return
        }
        XCTAssertEqual(testValue2, 1.0)
    }

    func testWhereKeyNearGeoPointWithinRadians() {
        let geoPoint = GeoPoint(latitude: 10, longitude: 20)
        let constraint = withinRadians(key: "yolo", geoPoint: geoPoint, distance: 10.0)
        let query = GameScore.query(constraint)
        let queryConstraints = query.`where`.constraints

        guard let testConstraints = queryConstraints["yolo"]?.first else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints.comparator.rawValue, "$nearSphere")

        guard let testValue = testConstraints.value as? GeoPoint else {
            XCTFail("Should have casted to GeoPoint")
            return
        }
        XCTAssertEqual(testValue, geoPoint)

        guard let testConstraints2 = queryConstraints["yolo"]?.last else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints2.comparator.rawValue, "$maxDistance")

        guard let testValue2 = testConstraints2.value as? Double else {
            XCTFail("Should have casted to Double")
            return
        }
        XCTAssertEqual(testValue2, 10.0)
    }

    func testWhereKeyNearGeoBox() {
        let geoPoint1 = GeoPoint(latitude: 10, longitude: 20)
        let geoPoint2 = GeoPoint(latitude: 20, longitude: 30)
        let constraint = withinGeoBox(key: "yolo", fromSouthWest: geoPoint1, toNortheast: geoPoint2)
        let query = GameScore.query(constraint)
        let queryConstraints = query.`where`.constraints

        guard let testConstraints = queryConstraints["yolo"]?.first else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints.comparator.rawValue, "$within")

        guard let testValue = testConstraints.value as? [QueryConstraint.Comparator: [GeoPoint]],
              let key = testValue.keys.first else {
            XCTFail("Should have casted to GeoPoint")
            return
        }
        XCTAssertEqual(key.rawValue, "$box")

        guard let testConstraints2 = testValue[key]?.first else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints2, geoPoint1)

        guard let testConstraints3 = testValue[key]?.last else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints3, geoPoint2)
    }

    func testWhereKeyWithinPolygon() {
        let geoPoint1 = GeoPoint(latitude: 10, longitude: 20)
        let geoPoint2 = GeoPoint(latitude: 20, longitude: 30)
        let geoPoint3 = GeoPoint(latitude: 30, longitude: 40)
        let constraint = withinPolygon(key: "yolo", points: [geoPoint1, geoPoint2, geoPoint3])
        let query = GameScore.query(constraint)
        let queryConstraints = query.`where`.constraints

        guard let testConstraints = queryConstraints["yolo"]?.first else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints.comparator.rawValue, "$geoWithin")

        guard let testValue = testConstraints.value as? [QueryConstraint.Comparator: [GeoPoint]],
              let key = testValue.keys.first else {
            XCTFail("Should have casted to GeoPoint")
            return
        }
        XCTAssertEqual(key.rawValue, "$polygon")

        guard let testConstraints2 = testValue[key]?.first else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints2, geoPoint1)

        guard let testConstraints3 = testValue[key]?[1] else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints3, geoPoint2)

        guard let testConstraints4 = testValue[key]?.last else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints4, geoPoint3)
    }

    func testWhereKeyPolygonContains() {
        let geoPoint = GeoPoint(latitude: 10, longitude: 20)
        let constraint = polygonContains(key: "yolo", point: geoPoint)
        let query = GameScore.query(constraint)
        let queryConstraints = query.`where`.constraints

        guard let testConstraints = queryConstraints["yolo"]?.first else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints.comparator.rawValue, "$geoIntersects")

        guard let testValue = testConstraints.value as? [QueryConstraint.Comparator: GeoPoint],
              let key = testValue.keys.first else {
            XCTFail("Should have casted to GeoPoint")
            return
        }
        XCTAssertEqual(key.rawValue, "$point")

        guard let testConstraints2 = testValue[key] else {
            XCTFail("Should have unwraped")
            return
        }
        XCTAssertEqual(testConstraints2, geoPoint)
    }
}
#endif
// swiftlint:disable:this file_length
