//
//  ParseLocalStorageTests.swift
//  ParseSwiftTests
//
//  Created by Damian Van de Kauter on 30/12/2022.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

final class ParseLocalStorageTests: XCTestCase {
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
                              offlinePolicy: .create,
                              requiringCustomObjectIds: true,
                              usingPostForQuery: true,
                              testing: true)

        var score1 = GameScore(points: 10)
        score1.points = 11
        score1.objectId = "yolo1"
        score1.createdAt = Date()
        score1.updatedAt = score1.createdAt
        score1.ACL = nil

        var score2 = GameScore(points: 10)
        score2.points = 22
        score2.objectId = "yolo2"
        score2.createdAt = Date()
        score2.updatedAt = score2.createdAt
        score2.ACL = nil

        MockLocalStorage = [score1, score2]
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    @MainActor
    func testFetchLocalStore() async throws {
        try await GameScore.fetchLocalStore(GameScore.self)
    }

    func testSave() throws {
        var score = GameScore(points: 10)
        score.points = 11
        score.objectId = "yolo"
        score.createdAt = Date()
        score.updatedAt = score.createdAt
        score.ACL = nil

        let query = GameScore.query("objectId" == score.objectId)
            .useLocalStore()
        XCTAssertNotEqual(query.queryIdentifier, "")

        try LocalStorage.save(score, queryIdentifier: query.queryIdentifier)
    }

    func testSaveAll() throws {
        var score1 = GameScore(points: 10)
        score1.points = 11
        score1.objectId = "yolo1"
        score1.createdAt = Date()
        score1.updatedAt = score1.createdAt
        score1.ACL = nil

        var score2 = GameScore(points: 10)
        score2.points = 22
        score2.objectId = "yolo2"
        score2.createdAt = Date()
        score2.updatedAt = score2.createdAt
        score2.ACL = nil

        let query = GameScore.query(containedIn(key: "objectId", array: [score1, score2].map({ $0.objectId })))
            .useLocalStore()
        XCTAssertNotEqual(query.queryIdentifier, "")

        try LocalStorage.saveAll([score1, score2], queryIdentifier: query.queryIdentifier)
    }

    func testSaveCheckObjectId() throws {
        var score1 = GameScore(points: 10)
        score1.points = 11
        score1.createdAt = Date()
        score1.updatedAt = score1.createdAt
        score1.ACL = nil

        var score2 = GameScore(points: 10)
        score2.points = 22
        score2.createdAt = Date()
        score2.updatedAt = score2.createdAt
        score2.ACL = nil

        let query = GameScore.query(containedIn(key: "objectId", array: [score1, score2].map({ $0.objectId })))
            .useLocalStore()
        XCTAssertNotEqual(query.queryIdentifier, "")

        do {
            try LocalStorage.saveAll([score1, score2], queryIdentifier: query.queryIdentifier)
        } catch {
            XCTAssertTrue(error.equalsTo(.missingObjectId))
        }

        do {
            try LocalStorage.save(score1, queryIdentifier: query.queryIdentifier)
        } catch {
            XCTAssertTrue(error.equalsTo(.missingObjectId))
        }
    }

    func testGet() throws {
        let query = GameScore.query("objectId" == "yolo")
            .useLocalStore()
        XCTAssertNotEqual(query.queryIdentifier, "")

        XCTAssertNoThrow(try LocalStorage.get(GameScore.self, queryIdentifier: query.queryIdentifier))
    }

    func testGetAll() throws {
        let query = GameScore.query(containedIn(key: "objectId", array: ["yolo1", "yolo2"]))
            .useLocalStore()
        XCTAssertNotEqual(query.queryIdentifier, "")

        XCTAssertNoThrow(try LocalStorage.getAll(GameScore.self, queryIdentifier: query.queryIdentifier))
    }

    func testSaveLocally() throws {
        var score1 = GameScore(points: 10)
        score1.points = 11
        score1.objectId = "yolo1"
        score1.createdAt = Date()
        score1.updatedAt = score1.createdAt
        score1.ACL = nil

        var score2 = GameScore(points: 10)
        score2.points = 22
        score2.objectId = "yolo2"
        score2.createdAt = Date()
        score2.updatedAt = score2.createdAt
        score2.ACL = nil

        let query1 = GameScore.query("objectId" == "yolo1")
            .useLocalStore()
        let query2 = GameScore.query("objectId" == ["yolo1", "yolo2"])
            .useLocalStore()

        XCTAssertNoThrow(try score1.saveLocally(method: .save,
                                                queryIdentifier: query1.queryIdentifier,
                                                error: ParseError(code: .notConnectedToInternet,
                                                                  message: "")))
        XCTAssertNoThrow(try score1.saveLocally(method: .save,
                                                queryIdentifier: query1.queryIdentifier))

        XCTAssertNoThrow(try [score1, score2].saveLocally(method: .save,
                                                          queryIdentifier: query2.queryIdentifier,
                                                          error: ParseError(code: .notConnectedToInternet,
                                                                            message: "")))
        XCTAssertNoThrow(try [score1, score2].saveLocally(method: .save,
                                                          queryIdentifier: query2.queryIdentifier))

        XCTAssertNoThrow(try score1.saveLocally(method: .create,
                                                queryIdentifier: query1.queryIdentifier,
                                                error: ParseError(code: .notConnectedToInternet,
                                                                  message: "")))
        XCTAssertNoThrow(try score1.saveLocally(method: .create,
                                                queryIdentifier: query1.queryIdentifier))

        XCTAssertNoThrow(try [score1, score2].saveLocally(method: .create,
                                                          queryIdentifier: query2.queryIdentifier,
                                                          error: ParseError(code: .notConnectedToInternet,
                                                                            message: "")))
        XCTAssertNoThrow(try [score1, score2].saveLocally(method: .create,
                                                          queryIdentifier: query2.queryIdentifier))

        XCTAssertNoThrow(try score1.saveLocally(method: .replace,
                                                queryIdentifier: query1.queryIdentifier,
                                                error: ParseError(code: .notConnectedToInternet,
                                                                  message: "")))
        XCTAssertNoThrow(try score1.saveLocally(method: .replace,
                                                queryIdentifier: query1.queryIdentifier))

        XCTAssertNoThrow(try [score1, score2].saveLocally(method: .replace,
                                                          queryIdentifier: query2.queryIdentifier,
                                                          error: ParseError(code: .notConnectedToInternet,
                                                                            message: "")))
        XCTAssertNoThrow(try [score1, score2].saveLocally(method: .replace,
                                                          queryIdentifier: query2.queryIdentifier))

        XCTAssertNoThrow(try score1.saveLocally(method: .update,
                                                queryIdentifier: query1.queryIdentifier,
                                                error: ParseError(code: .notConnectedToInternet,
                                                                  message: "")))
        XCTAssertNoThrow(try score1.saveLocally(method: .update,
                                                queryIdentifier: query1.queryIdentifier))

        XCTAssertNoThrow(try [score1, score2].saveLocally(method: .update,
                                                          queryIdentifier: query2.queryIdentifier,
                                                          error: ParseError(code: .notConnectedToInternet,
                                                                            message: "")))
        XCTAssertNoThrow(try [score1, score2].saveLocally(method: .update,
                                                          queryIdentifier: query2.queryIdentifier))
    }
}
#endif
