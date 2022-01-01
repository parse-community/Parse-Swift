//
//  ParseOperation.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/17/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseOperationTests: XCTestCase {
    struct GameScore: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var score: Double?

        //: Your own properties
        var points: Int
        var members = [String]()
        var levels: [String]?
        var previous: [Level]?
        var next: [Level]

        //custom initializers
        init() {
            self.points = 5
            self.next = [Level()]
        }

        init(points: Int) {
            self.points = points
            self.next = [Level()]
        }
    }

    struct Level: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var score: Double?

        //: Your own properties
        var level: Int
        var members = [String]()

        //custom initializers
        init() {
            self.level = 5
        }
        init(level: Int) {
            self.level = level
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
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testSaveCommand() throws {
        var score = GameScore(points: 10)
        let objectId = "hello"
        score.objectId = objectId
        let operations = score.operation
            .increment("points", by: 1)
        let className = score.className

        let command = try operations.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"points\":{\"amount\":1,\"__op\":\"Increment\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }
    #endif

    func testSave() { // swiftlint:disable:this function_body_length
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        let operations = score.operation
            .increment("points", by: 1)

        var scoreOnServer = score
        scoreOnServer.points = 11
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
            let saved = try operations.save()
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
            XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
            XCTAssertEqual(saved.points+1, scoreOnServer.points)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAsyncMainQueue() {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        let operations = score.operation
            .increment("points", by: 1)

        var scoreOnServer = score
        scoreOnServer.points = 11
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            //Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation1 = XCTestExpectation(description: "Save object1")

        operations.save(options: [], callbackQueue: .main) { result in

            switch result {

            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
                guard let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                guard let originalUpdatedAt = scoreOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
                XCTAssertEqual(saved.points+1, scoreOnServer.points)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveSet() throws { // swiftlint:disable:this function_body_length
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        let operations = try score.operation
            .set(("points", \.points), value: 15)

        var scoreOnServer = score
        scoreOnServer.points = 15
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
            let saved = try operations.save()
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
            XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
            XCTAssertEqual(saved.points, scoreOnServer.points)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveSetAsyncMainQueue() throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        let operations = try score.operation
            .set(("points", \.points), value: 15)

        var scoreOnServer = score
        scoreOnServer.points = 15
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            //Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation1 = XCTestExpectation(description: "Save object1")

        operations.save(options: [], callbackQueue: .main) { result in

            switch result {

            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
                guard let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                guard let originalUpdatedAt = scoreOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
                XCTAssertEqual(saved.points, scoreOnServer.points)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    //Linux decodes in different order
    #if !os(Linux) && !os(Android) && !os(Windows)
    func testIncrement() throws {
        let score = GameScore(points: 10)
        let operations = score.operation
            .increment("points", by: 1)
        let expected = "{\"points\":{\"amount\":1,\"__op\":\"Increment\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAdd() throws {
        let score = GameScore(points: 10)
        let operations = score.operation
            .add("test", objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Add\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddKeypath() throws {
        let score = GameScore(points: 10)
        let operations = try score.operation
            .add(("test", \.members), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Add\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)

    }

    func testAddOptionalKeypath() throws {
        let score = GameScore(points: 10)
        let operations = try score.operation
            .add(("test", \.levels), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Add\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddUnique() throws {
        let score = GameScore(points: 10)
        let operations = score.operation
            .addUnique("test", objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"AddUnique\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddUniqueKeypath() throws {
        let score = GameScore(points: 10)
        let operations = try score.operation
            .addUnique(("test", \.members), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"AddUnique\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddUniqueOptionalKeypath() throws {
        let score = GameScore(points: 10)
        let operations = try score.operation
            .addUnique(("test", \.levels), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"AddUnique\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddRelation() throws {
        let score = GameScore(points: 10)
        var score2 = GameScore(points: 20)
        score2.objectId = "yolo"
        let operations = try score.operation
            .addRelation("test", objects: [score2])
        // swiftlint:disable:next line_length
        let expected = "{\"test\":{\"objects\":[{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"yolo\"}],\"__op\":\"AddRelation\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddRelationKeypath() throws {
        let score = GameScore(points: 10)
        var level = Level(level: 2)
        level.objectId = "yolo"
        let operations = try score.operation
            .addRelation(("next", \.next), objects: [level])
        // swiftlint:disable:next line_length
        let expected = "{\"next\":{\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"yolo\"}],\"__op\":\"AddRelation\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddRelationOptionalKeypath() throws {
        let score = GameScore(points: 10)
        var level = Level(level: 2)
        level.objectId = "yolo"
        let operations = try score.operation
            .addRelation(("previous", \.previous), objects: [level])
        // swiftlint:disable:next line_length
        let expected = "{\"previous\":{\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"yolo\"}],\"__op\":\"AddRelation\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRemove() throws {
        let score = GameScore(points: 10)
        let operations = score.operation
            .remove("test", objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Remove\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveKeypath() throws {
        let score = GameScore(points: 10)
        let operations = try score.operation
            .remove(("test", \.members), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Remove\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveOptionalKeypath() throws {
        let score = GameScore(points: 10)
        let operations = try score.operation
            .remove(("test", \.levels), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Remove\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveRelation() throws {
        let score = GameScore(points: 10)
        var score2 = GameScore(points: 20)
        score2.objectId = "yolo"
        let operations = try score.operation
            .removeRelation("test", objects: [score2])
        // swiftlint:disable:next line_length
        let expected = "{\"test\":{\"objects\":[{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"yolo\"}],\"__op\":\"RemoveRelation\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveRelationKeypath() throws {
        let score = GameScore(points: 10)
        var level = Level(level: 2)
        level.objectId = "yolo"
        let operations = try score.operation
            .removeRelation(("next", \.next), objects: [level])
        // swiftlint:disable:next line_length
        let expected = "{\"next\":{\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"yolo\"}],\"__op\":\"RemoveRelation\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveRelationOptionalKeypath() throws {
        let score = GameScore(points: 10)
        var level = Level(level: 2)
        level.objectId = "yolo"
        let operations = try score.operation
            .removeRelation(("previous", \.previous), objects: [level])
        // swiftlint:disable:next line_length
        let expected = "{\"previous\":{\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"yolo\"}],\"__op\":\"RemoveRelation\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testSet() throws {
        let score = GameScore(points: 10)
        let operations = try score.operation.set(("points", \.points), value: 15)
            .set(("levels", \.levels), value: ["hello"])
        let expected = "{\"points\":15,\"levels\":[\"hello\"]}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
        XCTAssertEqual(operations.target.points, 15)
        var level = Level(level: 12)
        level.members = ["hello", "world"]
        let operations2 = try score.operation.set(("previous", \.previous), value: [level])
        let expected2 = "{\"previous\":[{\"level\":12,\"members\":[\"hello\",\"world\"]}]}"
        let encoded2 = try ParseCoding.parseEncoder()
            .encode(operations2)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
        XCTAssertEqual(operations2.target.previous, [level])
    }

    func testObjectIdSet() throws {
        var score = GameScore()
        score.objectId = "test"
        score.levels = nil
        let operations = try score.operation.set(("objectId", \.objectId), value: "test")
        let expected = "{}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
        XCTAssertEqual(operations.target.objectId, "test")
        var level = Level(level: 12)
        level.members = ["hello", "world"]
        score.previous = [level]
        let expected2 = "{}"
        let operations2 = try score.operation.set(("previous", \.previous), value: [level])
        let encoded2 = try ParseCoding.parseEncoder()
            .encode(operations2)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
        XCTAssertEqual(operations2.target.previous, [level])
    }
    #endif

    func testUnchangedSet() throws {
        let score = GameScore(points: 10)
        let operations = try score.operation.set(("points", \.points), value: 10)
        let expected = "{}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testForceSet() throws {
        let score = GameScore(points: 10)
        let operations = try score.operation.forceSet(("points", \.points), value: 10)
        let expected = "{\"points\":10}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testUnset() throws {
        let score = GameScore(points: 10)
        let operations = score.operation
            .unset("points")
        let expected = "{\"points\":{\"__op\":\"Delete\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testUnsetKeypath() throws {
        let score = GameScore(points: 10)
        let operations = score.operation
            .unset(("points", \.levels))
        let expected = "{\"points\":{\"__op\":\"Delete\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }
}
