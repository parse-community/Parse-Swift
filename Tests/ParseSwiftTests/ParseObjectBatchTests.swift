//
//  ParseObjectBatchTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/27/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseObjectBatchTests: XCTestCase { // swiftlint:disable:this type_body_length

    struct GameScore: ParseObject {
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
        guard let url = URL(string: "https://localhost:1337/1") else {
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

    func testSaveAll() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        let score = GameScore(score: 10)
        let score2 = GameScore(score: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.objectId = "yolo"
        scoreOnServer2.createdAt = Date()
        scoreOnServer2.updatedAt = scoreOnServer2.createdAt
        scoreOnServer2.ACL = nil

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil),
        BatchResponseItem<GameScore>(success: scoreOnServer2, error: nil)]
        let encoded: Data!
        do {
           encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(response)
           //Get dates in correct format from ParseDecoding strategy
           let encoded1 = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getTestDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer2)
           scoreOnServer2 = try scoreOnServer.getTestDecoder().decode(GameScore.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let saved = try [score, score2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: scoreOnServer))
                guard let savedCreatedAt = first.createdAt,
                    let savedUpdatedAt = first.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = scoreOnServer.createdAt,
                    let originalUpdatedAt = scoreOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(first.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: scoreOnServer2))
                guard let savedCreatedAt = second.createdAt,
                    let savedUpdatedAt = second.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = scoreOnServer.createdAt,
                    let originalUpdatedAt = scoreOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(second.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try [score, score2].saveAll(options: [.installationId("hello")])
            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: scoreOnServer))
                guard let savedCreatedAt = first.createdAt,
                    let savedUpdatedAt = first.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = scoreOnServer.createdAt,
                    let originalUpdatedAt = scoreOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(first.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: scoreOnServer2))
                guard let savedCreatedAt = second.createdAt,
                    let savedUpdatedAt = second.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = scoreOnServer.createdAt,
                    let originalUpdatedAt = scoreOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(second.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAllErrorIncorrectServerResponse() {
        let score = GameScore(score: 10)
        let score2 = GameScore(score: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.objectId = "yolo"
        scoreOnServer2.createdAt = Date()
        scoreOnServer2.updatedAt = Date()
        scoreOnServer2.ACL = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try scoreOnServer.getEncoder(skipKeys: false).encode([scoreOnServer, scoreOnServer2])
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        do {
            let saved = try [score, score2].saveAll()

            XCTAssertEqual(saved.count, 2)
            XCTAssertThrowsError(try saved[0].get())
            XCTAssertThrowsError(try saved[1].get())

        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try [score, score2].saveAll(options: [.useMasterKey])

            XCTAssertEqual(saved.count, 2)
            XCTAssertThrowsError(try saved[0].get())
            XCTAssertThrowsError(try saved[1].get())

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdateAll() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var score2 = GameScore(score: 20)
        score2.objectId = "yolo"
        score2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score2.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score2.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
        var scoreOnServer2 = score2
        scoreOnServer2.updatedAt = Date()

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil),
        BatchResponseItem<GameScore>(success: scoreOnServer2, error: nil)]
        let encoded: Data!
        do {
           encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(response)
           //Get dates in correct format from ParseDecoding strategy
           let encoded1 = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getTestDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer2)
           scoreOnServer2 = try scoreOnServer.getTestDecoder().decode(GameScore.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let saved = try [score, score2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):

                guard let savedCreatedAt = first.createdAt,
                    let savedUpdatedAt = first.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = score.createdAt,
                    let originalUpdatedAt = score.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }

                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(first.ACL)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):

                guard let savedCreatedAt2 = second.createdAt,
                    let savedUpdatedAt2 = second.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt2 = score2.createdAt,
                    let originalUpdatedAt2 = score2.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }

                XCTAssertEqual(savedCreatedAt2, originalCreatedAt2)
                XCTAssertGreaterThan(savedUpdatedAt2, originalUpdatedAt2)
                XCTAssertNil(second.ACL)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try [score, score2].saveAll(options: [.useMasterKey])
            XCTAssertEqual(saved.count, 2)

            switch saved[0] {

            case .success(let first):
                guard let savedCreatedAt = first.createdAt,
                    let savedUpdatedAt = first.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = score.createdAt,
                    let originalUpdatedAt = score.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }

                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(first.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                guard let savedCreatedAt2 = second.createdAt,
                    let savedUpdatedAt2 = second.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt2 = score2.createdAt,
                    let originalUpdatedAt2 = score2.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                /*Date's are not exactly as their original because the URLMocking doesn't use the same dateEncoding
                 strategy, so we only compare the day*/
                XCTAssertTrue(Calendar.current.isDate(savedCreatedAt2,
                                                      equalTo: originalCreatedAt2, toGranularity: .day))
                XCTAssertGreaterThan(savedUpdatedAt2, originalUpdatedAt2)
                XCTAssertNil(second.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdateAllErrorIncorrectServerResponse() {
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var score2 = GameScore(score: 20)
        score2.objectId = "yolo"
        score2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score2.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score2.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
        var scoreOnServer2 = score2
        scoreOnServer2.updatedAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try scoreOnServer.getEncoder(skipKeys: false).encode([scoreOnServer, scoreOnServer2])
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let saved = try [score, score2].saveAll()
            XCTAssertEqual(saved.count, 2)
            XCTAssertThrowsError(try saved[0].get())
            XCTAssertThrowsError(try saved[1].get())

        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try [score, score2].saveAll(options: [.useMasterKey])

            XCTAssertEqual(saved.count, 2)
            XCTAssertThrowsError(try saved[0].get())
            XCTAssertThrowsError(try saved[1].get())

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAllMixed() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        let score = GameScore(score: 10)
        var score2 = GameScore(score: 20)
        score2.objectId = "yolo"
        score2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score2.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score2.ACL = nil

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.updatedAt = Date()

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil),
        BatchResponseItem<GameScore>(success: scoreOnServer2, error: nil)]

        let encoded: Data!
        do {
           encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(response)
           //Get dates in correct format from ParseDecoding strategy
           let encoded1 = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getTestDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer2)
           scoreOnServer2 = try scoreOnServer.getTestDecoder().decode(GameScore.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let saved = try [score, score2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: scoreOnServer))
                guard let savedCreatedAt = first.createdAt,
                    let savedUpdatedAt = first.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = scoreOnServer.createdAt,
                    let originalUpdatedAt = scoreOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(first.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                guard let savedCreatedAt = second.createdAt,
                    let savedUpdatedAt = second.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = score2.createdAt,
                    let originalUpdatedAt = score2.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(second.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try [score, score2].saveAll(options: [.useMasterKey])
            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssertNotNil(first.createdAt)
                XCTAssertNotNil(first.updatedAt)
                XCTAssertNil(first.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssertNotNil(second.createdAt)
                XCTAssertNotNil(second.updatedAt)
                XCTAssertNil(second.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func saveAllAsync(scores: [GameScore], // swiftlint:disable:this function_body_length cyclomatic_complexity
                      scoresOnServer: [GameScore], callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Save object1")
        guard let scoreOnServer = scoresOnServer.first,
            let scoreOnServer2 = scoresOnServer.last else {
            XCTFail("Should unwrap")
            return
        }

        scores.saveAll(options: [], callbackQueue: callbackQueue) { result in
            expectation1.fulfill()

            switch result {

            case .success(let saved):
                XCTAssertEqual(saved.count, 2)
                guard let firstObject = saved.first,
                    let secondObject = saved.last else {
                    XCTFail("Should unwrap")
                    return
                }

                switch firstObject {

                case .success(let first):
                    XCTAssert(first.hasSameObjectId(as: scoreOnServer))
                    guard let savedCreatedAt = first.createdAt,
                        let savedUpdatedAt = first.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    guard let originalCreatedAt = scoreOnServer.createdAt,
                        let originalUpdatedAt = scoreOnServer.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertNil(first.ACL)

                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

                switch secondObject {

                case .success(let second):
                    XCTAssert(second.hasSameObjectId(as: scoreOnServer2))
                    guard let savedCreatedAt = second.createdAt,
                        let savedUpdatedAt = second.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    guard let originalCreatedAt = scoreOnServer2.createdAt,
                        let originalUpdatedAt = scoreOnServer2.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertNil(second.ACL)

                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        }

        let expectation2 = XCTestExpectation(description: "Save object2")
        scores.saveAll(options: [.useMasterKey], callbackQueue: callbackQueue) { result in
            expectation2.fulfill()

            switch result {

            case .success(let saved):
                XCTAssertEqual(saved.count, 2)

                guard let firstObject = saved.first,
                    let secondObject = saved.last else {
                    XCTFail("Should unwrap")
                    return
                }

                switch firstObject {

                case .success(let first):
                    guard let savedCreatedAt = first.createdAt,
                        let savedUpdatedAt = first.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    guard let originalCreatedAt = scoreOnServer.createdAt,
                        let originalUpdatedAt = scoreOnServer.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertNil(first.ACL)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

                switch secondObject {

                case .success(let second):
                    guard let savedCreatedAt = second.createdAt,
                        let savedUpdatedAt = second.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    guard let originalCreatedAt = scoreOnServer2.createdAt,
                        let originalUpdatedAt = scoreOnServer2.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertNil(second.ACL)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        }
        wait(for: [expectation1, expectation2], timeout: 10.0)
    }

    func testThreadSafeSaveAllAsync() {
        let score = GameScore(score: 10)
        let score2 = GameScore(score: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.objectId = "yolo"
        scoreOnServer2.createdAt = Date()
        scoreOnServer2.updatedAt = Date()
        scoreOnServer2.ACL = nil

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil),
        BatchResponseItem<GameScore>(success: scoreOnServer2, error: nil)]
        let encoded: Data!
        do {
           encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(response)
           //Get dates in correct format from ParseDecoding strategy
           let encoded1 = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getTestDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer2)
           scoreOnServer2 = try scoreOnServer.getTestDecoder().decode(GameScore.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            self.saveAllAsync(scores: [score, score2], scoresOnServer: [scoreOnServer, scoreOnServer2],
                              callbackQueue: .global(qos: .background))
        }
    }

    func testSaveAllAsyncMainQueue() {
        let score = GameScore(score: 10)
        let score2 = GameScore(score: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.objectId = "yolo"
        scoreOnServer2.createdAt = Date()
        scoreOnServer2.updatedAt = scoreOnServer2.createdAt
        scoreOnServer2.ACL = nil

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil),
        BatchResponseItem<GameScore>(success: scoreOnServer2, error: nil)]
        let encoded: Data!
        do {
           encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(response)
           //Get dates in correct format from ParseDecoding strategy
           let encoded1 = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getTestDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer2)
           scoreOnServer2 = try scoreOnServer.getTestDecoder().decode(GameScore.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        self.saveAllAsync(scores: [score, score2], scoresOnServer: [scoreOnServer, scoreOnServer2],
                          callbackQueue: .main)
    }

    /* Note, the current batchCommand for updateAll returns the original object that was updated as
    opposed to the latestUpdated. The objective c one just returns true/false */
    func updateAllAsync(scores: [GameScore], // swiftlint:disable:this function_body_length cyclomatic_complexity
                        callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        scores.saveAll(options: [], callbackQueue: callbackQueue) { result in
            expectation1.fulfill()

            switch result {

            case .success(let saved):
                guard let firstObject = saved.first,
                    let secondObject = saved.last else {
                    XCTFail("Should unwrap")
                    return
                }

                switch firstObject {

                case .success(let first):
                    guard let savedCreatedAt = first.createdAt,
                        let savedUpdatedAt = first.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    guard let originalCreatedAt = scores.first?.createdAt,
                        let originalUpdatedAt = scores.first?.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }

                    XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                    XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertNil(first.ACL)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

                switch secondObject {

                case .success(let second):
                    guard let savedCreatedAt2 = second.createdAt,
                        let savedUpdatedAt2 = second.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    guard let originalCreatedAt2 = scores.last?.createdAt,
                        let originalUpdatedAt2 = scores.last?.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }

                    XCTAssertEqual(savedCreatedAt2, originalCreatedAt2)
                    XCTAssertGreaterThan(savedUpdatedAt2,
                                         originalUpdatedAt2)
                    XCTAssertNil(second.ACL)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        }

        let expectation2 = XCTestExpectation(description: "Update object2")
        scores.saveAll(options: [.useMasterKey], callbackQueue: callbackQueue) { result in
            expectation2.fulfill()

            switch result {

            case .success(let saved):
                guard let firstObject = saved.first,
                    let secondObject = saved.last else {
                    XCTFail("Should unwrap")
                    return
                }

                switch firstObject {

                case .success(let first):
                    guard let savedCreatedAt = first.createdAt,
                        let savedUpdatedAt = first.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    guard let originalCreatedAt = scores.first?.createdAt,
                        let originalUpdatedAt = scores.first?.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }

                    XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                    XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertNil(first.ACL)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

                switch secondObject {

                case .success(let second):
                    guard let savedCreatedAt2 = second.createdAt,
                        let savedUpdatedAt2 = second.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    guard let originalCreatedAt2 = scores.last?.createdAt,
                        let originalUpdatedAt2 = scores.last?.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }

                    XCTAssertEqual(savedCreatedAt2, originalCreatedAt2)
                    XCTAssertGreaterThan(savedUpdatedAt2,
                                         originalUpdatedAt2)
                    XCTAssertNil(second.ACL)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expectation1, expectation2], timeout: 10.0)
    }

    func testThreadSafeUpdateAllAsync() {
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var score2 = GameScore(score: 20)
        score2.objectId = "yolo"
        score2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score2.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score2.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
        var scoreOnServer2 = score2
        scoreOnServer2.updatedAt = Date()

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil),
                        BatchResponseItem<GameScore>(success: scoreOnServer2, error: nil)]

        let encoded: Data!
        do {
           encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(response)
           //Get dates in correct format from ParseDecoding strategy
           let encoded1 = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getTestDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer2)
           scoreOnServer2 = try scoreOnServer.getTestDecoder().decode(GameScore.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            self.updateAllAsync(scores: [score, score2], callbackQueue: .global(qos: .background))
        }
    }

    func testUpdateAllAsyncMainQueue() {
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var score2 = GameScore(score: 20)
        score2.objectId = "yolo"
        score2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score2.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score2.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
        var scoreOnServer2 = score2
        scoreOnServer2.updatedAt = Date()

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil),
                        BatchResponseItem<GameScore>(success: scoreOnServer2, error: nil)]

        let encoded: Data!
        do {
           encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(response)
           //Get dates in correct format from ParseDecoding strategy
           let encoded1 = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getTestDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer2)
           scoreOnServer2 = try scoreOnServer.getTestDecoder().decode(GameScore.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        self.updateAllAsync(scores: [score, score2], callbackQueue: .main)
    }
} // swiftlint:disable:this file_length
