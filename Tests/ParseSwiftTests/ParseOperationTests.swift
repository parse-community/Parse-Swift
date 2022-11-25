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
        var originalData: Data?

        //: Your own properties
        var points: Int?
        var members: [String]?
        var levels: [String]?
        var previous: [Level]?
        var next: [Level]?

        init() {
        }

        // custom initializers
        init(points: Int) {
            self.points = points
            self.next = [Level(level: 5)]
            self.members = [String]()
        }
    }

    struct Level: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var level: Int?
        var members: [String]?

        init() {
        }

        //custom initializers
        init(level: Int) {
            self.level = level
            self.members = [String]()
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

    func testSaveCommand() throws {
        var score = GameScore()
        score.points = 10
        let objectId = "hello"
        score.objectId = objectId
        let operations = score.operation
            .increment("points", by: 1)
        let className = score.className

        let command = operations.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"points\":{\"__op\":\"Increment\",\"amount\":1}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testSave() { // swiftlint:disable:this function_body_length
        var score = GameScore()
        score.points = 10
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
            guard let originalUpdatedAt = scoreOnServer.updatedAt,
                  let originalPoints = scoreOnServer.points else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
            XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
            XCTAssertEqual(saved.points, originalPoints-1)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveNoObjectId() {
        var score = GameScore()
        score.points = 10
        let operations = score.operation
            .increment("points", by: 1)

        do {
            try operations.save()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(parseError.code, .missingObjectId)
        }
    }

    func testSaveKeyPath() throws { // swiftlint:disable:this function_body_length
        var score = GameScore()
        score.objectId = "yarr"
        let operations = try score.operation
            .set(\.points, to: 15)
            .set(\.levels, to: ["hello"])

        var scoreOnServer = score
        scoreOnServer.points = 15
        scoreOnServer.levels = ["hello"]
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
            XCTAssertEqual(saved, scoreOnServer)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveKeyPathOtherTypeOperationsExist() throws { // swiftlint:disable:this function_body_length
        var score = GameScore()
        score.objectId = "yarr"
        let operations = try score.operation
            .set(\.points, to: 15)
            .set(("levels", \.levels), to: ["hello"])

        do {
            try operations.save()
            XCTFail("Should have failed")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("Cannot combine"))
        }
    }

    func testSaveKeyPathNilOperationsExist() throws { // swiftlint:disable:this function_body_length
        var score = GameScore()
        score.objectId = "yarr"
        let operations = try score.operation
            .set(\.points, to: 15)
            .set(("points", \.points), to: nil)

        do {
            try operations.save()
            XCTFail("Should have failed")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("Cannot combine"))
        }
    }

    func testSaveAsyncMainQueue() {
        var score = GameScore()
        score.points = 10
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
                guard let originalUpdatedAt = scoreOnServer.updatedAt,
                      let originalPoints = scoreOnServer.points else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
                XCTAssertEqual(saved.points, originalPoints-1)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveSet() throws { // swiftlint:disable:this function_body_length
        var score = GameScore()
        score.points = 10
        score.objectId = "yarr"
        let operations = score.operation
            .set(("points", \.points), to: 15)

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

    func testSaveSetToNull() throws { // swiftlint:disable:this function_body_length
        var score = GameScore()
        score.points = 10
        score.objectId = "yarr"
        let operations = score.operation
            .set(("points", \.points), to: nil)

        var scoreOnServer = score
        scoreOnServer.points = nil
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
        var score = GameScore()
        score.points = 10
        score.objectId = "yarr"
        let operations = score.operation
            .set(("points", \.points), to: 15)

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

    func testIncrement() throws {
        let score = GameScore(points: 10)
        let operations = score.operation
            .increment("points", by: 1)
        let expected = "{\"points\":{\"__op\":\"Increment\",\"amount\":1}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAdd() throws {
        let score = GameScore(points: 10)
        let operations = score.operation
            .add("test", objects: ["hello"])
        let expected = "{\"test\":{\"__op\":\"Add\",\"objects\":[\"hello\"]}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddKeypath() throws {
        let score = GameScore(points: 10)
        let operations = score.operation
            .add(("test", \.levels), objects: ["hello"])
        let expected = "{\"test\":{\"__op\":\"Add\",\"objects\":[\"hello\"]}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddUnique() throws {
        let score = GameScore(points: 10)
        let operations = score.operation
            .addUnique("test", objects: ["hello"])
        let expected = "{\"test\":{\"__op\":\"AddUnique\",\"objects\":[\"hello\"]}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddUniqueKeypath() throws {
        let score = GameScore(points: 10)
        let operations = score.operation
            .addUnique(("test", \.levels), objects: ["hello"])
        let expected = "{\"test\":{\"__op\":\"AddUnique\",\"objects\":[\"hello\"]}}"
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
        let expected = "{\"test\":{\"__op\":\"AddRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"yolo\"}]}}"
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
            .addRelation(("previous", \.previous), objects: [level])
        // swiftlint:disable:next line_length
        let expected = "{\"previous\":{\"__op\":\"AddRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"yolo\"}]}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRemove() throws {
        let score = GameScore(points: 10)
        let operations = score.operation
            .remove("test", objects: ["hello"])
        let expected = "{\"test\":{\"__op\":\"Remove\",\"objects\":[\"hello\"]}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveKeypath() throws {
        let score = GameScore(points: 10)
        let operations = score.operation
            .remove(("test", \.levels), objects: ["hello"])
        let expected = "{\"test\":{\"__op\":\"Remove\",\"objects\":[\"hello\"]}}"
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
        let expected = "{\"test\":{\"__op\":\"RemoveRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"yolo\"}]}}"
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
            .removeRelation(("previous", \.previous), objects: [level])
        // swiftlint:disable:next line_length
        let expected = "{\"previous\":{\"__op\":\"RemoveRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Level\",\"objectId\":\"yolo\"}]}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testSet() throws {
        let score = GameScore(points: 10)
        let operations = score.operation.set(("points", \.points), to: 15)
            .set(("levels", \.levels), to: ["hello"])
        let expected = "{\"levels\":[\"hello\"],\"points\":15}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
        XCTAssertEqual(operations.target.points, 15)
        var level = Level(level: 12)
        level.members = ["hello", "world"]
        let operations2 = score.operation.set(("previous", \.previous), to: [level])
        let expected2 = "{\"previous\":[{\"level\":12,\"members\":[\"hello\",\"world\"]}]}"
        let encoded2 = try ParseCoding.parseEncoder()
            .encode(operations2)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
        XCTAssertEqual(operations2.target.previous, [level])
        let operations3 = score.operation.set(("points", \.points), to: nil)
            .set(("levels", \.levels), to: ["hello"])
        let expected3 = "{\"levels\":[\"hello\"],\"points\":null}"
        let encoded3 = try ParseCoding.parseEncoder()
            .encode(operations3)
        let decoded3 = try XCTUnwrap(String(data: encoded3, encoding: .utf8))
        XCTAssertEqual(decoded3, expected3)
        XCTAssertNil(operations3.target.points)
    }

    func testSetKeyPath() throws {
        var score = GameScore()
        score.points = 10
        score.objectId = "yolo"
        var operations = try score.operation.set(\.points, to: 15)
            .set(\.levels, to: ["hello"])
        var expected = GameScore()
        expected.points = 15
        expected.objectId = "yolo"
        expected.levels = ["hello"]
        XCTAssertNotNil(operations.target.originalData)
        XCTAssertNotEqual(operations.target, expected)
        operations.target.originalData = nil
        XCTAssertEqual(operations.target, expected)
    }

    func testSetKeyPathOtherTypeOperationsExist() throws {
        var score = GameScore()
        score.points = 10
        var operations = score.operation
            .set(("levels", \.levels), to: ["hello"])
        do {
            operations = try operations.set(\.points, to: 15)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("Cannot combine"))
        }
    }

    func testSetKeyPathNilOperationsExist() throws {
        var score = GameScore()
        score.points = 10
        var operations = score.operation
            .set(("points", \.points), to: nil)
        do {
            operations = try operations.set(\.points, to: 15)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("Cannot combine"))
        }
    }

    func testObjectIdSet() throws {
        var score = GameScore()
        score.objectId = "test"
        score.levels = nil
        let operations = score.operation.set(("objectId", \.objectId), to: "test")
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
        let operations2 = score.operation.set(("previous", \.previous), to: [level])
        let encoded2 = try ParseCoding.parseEncoder()
            .encode(operations2)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
        XCTAssertEqual(operations2.target.previous, [level])
    }

    func testUnchangedSet() throws {
        let score = GameScore(points: 10)
        let operations = score.operation.set(("points", \.points), to: 10)
        let expected = "{}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
        let operations2 = score.operation
            .set(("levels", \.levels), to: nil)
        let expected2 = "{}"
        let encoded2 = try ParseCoding.parseEncoder()
            .encode(operations2)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
        XCTAssertNil(operations2.target.levels)
    }

    func testForceSet() throws {
        let score = GameScore(points: 10)
        let operations = score.operation.forceSet(("points", \.points), value: 10)
        let expected = "{\"points\":10}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
        let operations2 = score.operation
            .forceSet(("points", \.points), value: nil)
        let expected2 = "{\"points\":null}"
        let encoded2 = try ParseCoding.parseEncoder()
            .encode(operations2)
        let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
        XCTAssertEqual(decoded2, expected2)
        XCTAssertNil(operations2.target.points)
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
