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

    struct GameScore: ParseSwift.ObjectType {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ACL?

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
    }

    func testConstructors() {
        let query = Query<GameScore>()
        XCTAssertEqual(query.className, GameScore.className)

        let query2 = GameScore.query()
        XCTAssertEqual(query2.className, GameScore.className)
        XCTAssertEqual(query2.className, query.className)
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
                let encoded = try scoreOnServer.getEncoderWithoutSkippingKeys().encode(results)
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
            XCTAssertEqual(score, scoreOnServer)
        } catch {
            XCTFail(error.localizedDescription)
        }

    }

    func findAsync(scoreOnServer: GameScore, callbackQueue: DispatchQueue) {
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.find(options: [], callbackQueue: callbackQueue) { result in
            expectation.fulfill()

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    return
                }
                XCTAssertEqual(score, scoreOnServer)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

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
                let encoded = try scoreOnServer.getEncoderWithoutSkippingKeys().encode(results)
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
                let encoded = try scoreOnServer.getEncoderWithoutSkippingKeys().encode(results)
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
                let encoded = try scoreOnServer.getEncoderWithoutSkippingKeys().encode(results)
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
            XCTAssertEqual(score, scoreOnServer)
        } catch {
            XCTFail(error.localizedDescription)
        }

    }

    func firstAsync(scoreOnServer: GameScore, callbackQueue: DispatchQueue) {
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.first(options: [], callbackQueue: callbackQueue) { result in
            expectation.fulfill()

            switch result {

            case .success(let score):
                XCTAssertEqual(score, scoreOnServer)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
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
                let encoded = try scoreOnServer.getEncoderWithoutSkippingKeys().encode(results)
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
                let encoded = try scoreOnServer.getEncoderWithoutSkippingKeys().encode(results)
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
                let encoded = try scoreOnServer.getEncoderWithoutSkippingKeys().encode(results)
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
            expectation.fulfill()

            switch result {

            case .success(let scoreCount):
                XCTAssertEqual(scoreCount, 1)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

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
                let encoded = try scoreOnServer.getEncoderWithoutSkippingKeys().encode(results)
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
                let encoded = try scoreOnServer.getEncoderWithoutSkippingKeys().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        countAsync(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }
}
