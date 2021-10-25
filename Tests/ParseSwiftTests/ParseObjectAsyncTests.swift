//
//  ParseObjectAsyncTests.swift
//  ParseObjectAsyncTests
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency) && !os(Linux) && !os(Android)
import Foundation
import XCTest
@testable import ParseSwift

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
class ParseObjectAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length

    struct GameScore: ParseObject {

        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: Int?
        var player: String?

        init() { }

        //custom initializers
        init (objectId: String?) {
            self.objectId = objectId
        }
        init(score: Int) {
            self.score = score
            self.player = "Jen"
        }
        init(score: Int, name: String) {
            self.score = score
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
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    @MainActor
    func testFetch() async throws {
        var score = GameScore(score: 10)
        let objectId = "yarr"
        score.objectId = objectId
        let score2 = score

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let scoreOnServer2: GameScore!

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            //Get dates in correct format from ParseDecoding strategy
            scoreOnServer2 = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let fetched = try await score2.fetch()
        XCTAssert(fetched.hasSameObjectId(as: scoreOnServer2))
        guard let fetchedCreatedAt = fetched.createdAt,
            let fetchedUpdatedAt = fetched.updatedAt else {
                XCTFail("Should unwrap dates")
                return
        }
        guard let originalCreatedAt = scoreOnServer2.createdAt,
            let originalUpdatedAt = scoreOnServer2.updatedAt else {
                XCTFail("Should unwrap dates")
                return
        }
        XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
        XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
        XCTAssertNil(fetched.ACL)
    }

    @MainActor
    func testSave() async throws {
        let score = GameScore(score: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let scoreOnServer2: GameScore!
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            //Get dates in correct format from ParseDecoding strategy
            scoreOnServer2 = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let saved = try await score.save()
        XCTAssert(saved.hasSameObjectId(as: scoreOnServer2))
        guard let savedCreatedAt = saved.createdAt,
            let savedUpdatedAt = saved.updatedAt else {
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
        XCTAssertEqual(saved.ACL, scoreOnServer2.ACL)
    }

    @MainActor
    func testDelete() async throws {
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        let score2 = score

        let scoreOnServer = NoBody()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        try await score2.delete()
    }

    @MainActor
    func testFetchAll() async throws {
        let score = GameScore(score: 10)
        let score2 = GameScore(score: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let scoreOnServerImmutable: GameScore!
        let scoreOnServer2Immutable: GameScore!
        var scoreOnServer2 = score2
        scoreOnServer2.objectId = "yolo"
        scoreOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -2), to: Date())
        scoreOnServer2.updatedAt = scoreOnServer2.createdAt
        scoreOnServer2.ACL = nil

        let response = QueryResponse<GameScore>(results: [scoreOnServer, scoreOnServer2], count: 2)
        let encoded: Data!
        do {
           encoded = try ParseCoding.jsonEncoder().encode(response)
           //Get dates in correct format from ParseDecoding strategy
           let encoded1 = try ParseCoding.jsonEncoder().encode(scoreOnServer)
           scoreOnServerImmutable = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try ParseCoding.jsonEncoder().encode(scoreOnServer2)
           scoreOnServer2Immutable = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let fetched = try await [GameScore(objectId: "yarr"), GameScore(objectId: "yolo")].fetchAll()

        XCTAssertEqual(fetched.count, 2)
        guard let firstObject = try? fetched.first(where: {try $0.get().objectId == "yarr"}),
            let secondObject = try? fetched.first(where: {try $0.get().objectId == "yolo"}) else {
                XCTFail("Should unwrap")
                return
        }

        switch firstObject {

        case .success(let first):
            XCTAssert(first.hasSameObjectId(as: scoreOnServerImmutable))
            guard let fetchedCreatedAt = first.createdAt,
                let fetchedUpdatedAt = first.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = scoreOnServerImmutable.createdAt,
                let originalUpdatedAt = scoreOnServerImmutable.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(first.ACL)
            XCTAssertEqual(first.score, scoreOnServerImmutable.score)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        switch secondObject {

        case .success(let second):
            XCTAssert(second.hasSameObjectId(as: scoreOnServer2Immutable))
            guard let savedCreatedAt = second.createdAt,
                let savedUpdatedAt = second.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = scoreOnServer2Immutable.createdAt,
                let originalUpdatedAt = scoreOnServer2Immutable.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, originalCreatedAt)
            XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(second.ACL)
            XCTAssertEqual(second.score, scoreOnServer2Immutable.score)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testSaveAll() async throws {
        let score = GameScore(score: 10)
        let score2 = GameScore(score: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.objectId = "yolo"
        scoreOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        scoreOnServer2.updatedAt = scoreOnServer2.createdAt
        scoreOnServer2.ACL = nil
        let scoreOnServerImmutable: GameScore!
        let scoreOnServer2Immutable: GameScore!

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil),
        BatchResponseItem<GameScore>(success: scoreOnServer2, error: nil)]
        let encoded: Data!
        do {
           encoded = try ParseCoding.jsonEncoder().encode(response)
           //Get dates in correct format from ParseDecoding strategy
           let encoded1 = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            scoreOnServerImmutable = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try ParseCoding.jsonEncoder().encode(scoreOnServer2)
            scoreOnServer2Immutable = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let saved = try await [score, score2].saveAll()
        XCTAssertEqual(saved.count, 2)
        switch saved[0] {

        case .success(let first):
            XCTAssert(first.hasSameObjectId(as: scoreOnServerImmutable))
            guard let savedCreatedAt = first.createdAt,
                let savedUpdatedAt = first.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = scoreOnServerImmutable.createdAt,
                let originalUpdatedAt = scoreOnServerImmutable.updatedAt else {
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
            XCTAssert(second.hasSameObjectId(as: scoreOnServer2Immutable))
            guard let savedCreatedAt = second.createdAt,
                let savedUpdatedAt = second.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = scoreOnServer2Immutable.createdAt,
                let originalUpdatedAt = scoreOnServer2Immutable.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, originalCreatedAt)
            XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(second.ACL)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testDeleteAll() async throws {
        let response = [BatchResponseItem<NoBody>(success: NoBody(), error: nil),
                        BatchResponseItem<NoBody>(success: NoBody(), error: nil)]

        let encoded: Data!
        do {
           encoded = try ParseCoding.jsonEncoder().encode(response)
        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        let deleted = try await [GameScore(objectId: "yarr"), GameScore(objectId: "yolo")].deleteAll()
        XCTAssertEqual(deleted.count, 2)
        guard let firstObject = deleted.first else {
            XCTFail("Should unwrap")
            return
        }

        if case let .failure(error) = firstObject {
            XCTFail(error.localizedDescription)
        }

        guard let lastObject = deleted.last else {
            XCTFail("Should unwrap")
            return
        }

        if case let .failure(error) = lastObject {
            XCTFail(error.localizedDescription)
        }
    }
}

#endif
