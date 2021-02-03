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
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: Int
        var members = [String]()
        var levels: [String]?
        var previous: [Level]?

        //custom initializers
        init(score: Int) {
            self.score = score
        }
    }

    struct Level: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var level: Int
        var members = [String]()

        //custom initializers
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
        #if !os(Linux)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testSaveCommand() throws {
        var score = GameScore(score: 10)
        let objectId = "hello"
        score.objectId = objectId
        let operations = score.operation
            .increment("score", by: 1)
        let className = score.className

        let command = try operations.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"score\":{\"amount\":1,\"__op\":\"Increment\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testSave() { // swiftlint:disable:this function_body_length
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        let operations = score.operation
            .increment("score", by: 1)

        var scoreOnServer = score
        scoreOnServer.score = 11
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
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAsyncMainQueue() {
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        let operations = score.operation
            .increment("score", by: 1)

        var scoreOnServer = score
        scoreOnServer.score = 11
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
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testIncrement() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .increment("score", by: 1)
        let expected = "{\"score\":{\"amount\":1,\"__op\":\"Increment\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAdd() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .add("test", objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Add\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddKeypath() throws {
        let score = GameScore(score: 10)
        let operations = try score.operation
            .add(("test", \.members), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Add\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)

    }

    func testAddOptionalKeypath() throws {
        let score = GameScore(score: 10)
        let operations = try score.operation
            .add(("test", \.levels), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Add\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddUnique() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .addUnique("test", objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"AddUnique\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddUniqueKeypath() throws {
        let score = GameScore(score: 10)
        let operations = try score.operation
            .addUnique(("test", \.members), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"AddUnique\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddUniqueOptionalKeypath() throws {
        let score = GameScore(score: 10)
        let operations = try score.operation
            .addUnique(("test", \.levels), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"AddUnique\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAddRelation() throws {
        let score = GameScore(score: 10)
        var score2 = GameScore(score: 20)
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
        let score = GameScore(score: 10)
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

    func testAddRelationOptionalKeypath() throws {
        let score = GameScore(score: 10)
        var score2 = GameScore(score: 20)
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

    func testRemove() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .remove("test", objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Remove\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveKeypath() throws {
        let score = GameScore(score: 10)
        let operations = try score.operation
            .remove(("test", \.members), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Remove\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveOptionalKeypath() throws {
        let score = GameScore(score: 10)
        let operations = try score.operation
            .remove(("test", \.levels), objects: ["hello"])
        let expected = "{\"test\":{\"objects\":[\"hello\"],\"__op\":\"Remove\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testRemoveRelation() throws {
        let score = GameScore(score: 10)
        var score2 = GameScore(score: 20)
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
        let score = GameScore(score: 10)
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

    func testRemoveRelationOptionalKeypath() throws {
        let score = GameScore(score: 10)
        var score2 = GameScore(score: 20)
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

    func testUnset() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .unset("score")
        let expected = "{\"score\":{\"__op\":\"Delete\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testUnsetKeypath() throws {
        let score = GameScore(score: 10)
        let operations = score.operation
            .unset(("score", \.levels))
        let expected = "{\"score\":{\"__op\":\"Delete\"}}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(operations)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }
}
