//
//  ParseObjectAsyncTests.swift
//  ParseObjectAsyncTests
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseObjectAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length

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

        //: Implement your own version of merge
        func merge(with object: Self) throws -> Self {
            var updated = try mergeParse(with: object)
            if updated.shouldRestoreKey(\.points,
                                         original: object) {
                updated.points = object.points
            }
            if updated.shouldRestoreKey(\.player,
                                         original: object) {
                updated.player = object.player
            }
            return updated
        }

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

    struct GameScoreDefault: ParseObject {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?
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

    @MainActor
    func testFetch() async throws {
        var score = GameScore(points: 10)
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
        let score = GameScore(points: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil
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

        let saved = try await score.save()
        XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
        guard let savedCreatedAt = saved.createdAt,
            let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
        }
        XCTAssertEqual(savedCreatedAt, scoreOnServer.createdAt)
        XCTAssertEqual(savedUpdatedAt, scoreOnServer.createdAt)
        XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
    }

    @MainActor
    func testSaveMutable() async throws {
        var original = GameScore(points: 10)
        original.objectId = "yarr"
        original.player = "beast"

        var originalResponse = original.mergeable
        originalResponse.createdAt = nil
        originalResponse.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())

        let encoded: Data!
        do {
            encoded = try originalResponse.getEncoder().encode(originalResponse, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            originalResponse = try originalResponse.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        let response = originalResponse
        var originalUpdated = original.mergeable
        originalUpdated.points = 50
        let updated = originalUpdated

        do {
            let saved = try await updated.save()
            XCTAssertTrue(saved.hasSameObjectId(as: response))
            XCTAssertEqual(saved.points, 50)
            XCTAssertEqual(saved.player, original.player)
            XCTAssertEqual(saved.createdAt, response.createdAt)
            XCTAssertEqual(saved.updatedAt, response.updatedAt)
            XCTAssertNil(saved.originalData)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testCreate() async throws {
        let score = GameScore(points: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

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

        let saved = try await score.create()
        XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
        guard let savedCreatedAt = saved.createdAt,
            let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
        }
        guard let originalCreatedAt = scoreOnServer.createdAt else {
                XCTFail("Should unwrap dates")
                return
        }
        XCTAssertEqual(savedCreatedAt, originalCreatedAt)
        XCTAssertEqual(savedUpdatedAt, originalCreatedAt)
        XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
    }

    @MainActor
    func testReplaceCreated() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

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

        let saved = try await score.replace()
        XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
        guard let originalCreatedAt = scoreOnServer.createdAt else {
                XCTFail("Should unwrap dates")
                return
        }
        XCTAssertEqual(saved.createdAt, originalCreatedAt)
        XCTAssertEqual(saved.updatedAt, originalCreatedAt)
        XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
    }

    @MainActor
    func testReplaceUpdated() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

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

        let saved = try await score.replace()
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
    }

    @MainActor
    func testReplaceClientMissingObjectId() async throws {
        let score = GameScore(points: 10)
        do {
            _ = try await score.replace()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertEqual(parseError.code, .missingObjectId)
        }
    }

    @MainActor
    func testUpdate() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

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

        let saved = try await score.update()
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
    }

    @MainActor
    func testUpdateClientMissingObjectId() async throws {
        let score = GameScore(points: 10)
        do {
            _ = try await score.update()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertEqual(parseError.code, .missingObjectId)
        }
    }

    @MainActor
    func testUpdateMutable() async throws {
        var original = GameScore(points: 10)
        original.objectId = "yarr"
        original.player = "beast"

        var originalResponse = original.mergeable
        originalResponse.createdAt = nil
        originalResponse.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())

        let encoded: Data!
        do {
            encoded = try originalResponse.getEncoder().encode(originalResponse, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            originalResponse = try originalResponse.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        let response = originalResponse
        var originalUpdated = original.mergeable
        originalUpdated.points = 50
        let updated = originalUpdated

        do {
            let saved = try await updated.update()
            XCTAssertTrue(saved.hasSameObjectId(as: response))
            XCTAssertEqual(saved.points, 50)
            XCTAssertEqual(saved.player, original.player)
            XCTAssertEqual(saved.createdAt, response.createdAt)
            XCTAssertEqual(saved.updatedAt, response.updatedAt)
            XCTAssertNil(saved.originalData)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testUpdateMutableDefault() async throws {
        var original = GameScoreDefault()
        original.objectId = "yarr"

        var originalResponse = original.mergeable
        originalResponse.createdAt = nil
        originalResponse.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())

        let encoded: Data!
        do {
            encoded = try originalResponse.getEncoder().encode(originalResponse, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            originalResponse = try originalResponse.getDecoder().decode(GameScoreDefault.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        let response = originalResponse
        let originalUpdated = original.mergeable
        let updated = originalUpdated

        do {
            let saved = try await updated.update()
            XCTAssertTrue(saved.hasSameObjectId(as: response))
            XCTAssertEqual(saved.createdAt, response.createdAt)
            XCTAssertEqual(saved.updatedAt, response.updatedAt)
            XCTAssertNil(saved.originalData)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testDelete() async throws {
        var score = GameScore(points: 10)
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
    func testDeleteError() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        let score2 = score

        let serverResponse = ParseError(code: .objectNotFound, message: "not found")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            try await score2.delete()
            XCTFail("Should have thrown error")
        } catch {

            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.message, serverResponse.message)
        }
    }

    @MainActor
    func testFetchAll() async throws {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)

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
            XCTAssertEqual(first.points, scoreOnServerImmutable.points)
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
            XCTAssertEqual(second.points, scoreOnServer2Immutable.points)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testSaveAll() async throws {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.objectId = "yolo"
        scoreOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        scoreOnServer2.ACL = nil

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil),
        BatchResponseItem<GameScore>(success: scoreOnServer2, error: nil)]
        let encoded: Data!
        do {
           encoded = try ParseCoding.jsonEncoder().encode(response)
           //Get dates in correct format from ParseDecoding strategy
           let encoded1 = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try ParseCoding.jsonEncoder().encode(scoreOnServer2)
            scoreOnServer2 = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded2)

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
            XCTAssert(first.hasSameObjectId(as: scoreOnServer))
            guard let savedCreatedAt = first.createdAt,
                let savedUpdatedAt = first.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, scoreOnServer.createdAt)
            XCTAssertEqual(savedUpdatedAt, scoreOnServer.createdAt)
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
            XCTAssertEqual(savedCreatedAt, scoreOnServer2.createdAt)
            XCTAssertEqual(savedUpdatedAt, scoreOnServer2.createdAt)
            XCTAssertNil(second.ACL)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testCreateAll() async throws {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.objectId = "yolo"
        scoreOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
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

        let saved = try await [score, score2].createAll()
        XCTAssertEqual(saved.count, 2)
        switch saved[0] {

        case .success(let first):
            XCTAssert(first.hasSameObjectId(as: scoreOnServerImmutable))
            guard let savedCreatedAt = first.createdAt,
                let savedUpdatedAt = first.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = scoreOnServerImmutable.createdAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, originalCreatedAt)
            XCTAssertEqual(savedUpdatedAt, originalCreatedAt)
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
            guard let originalCreatedAt = scoreOnServer2Immutable.createdAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, originalCreatedAt)
            XCTAssertEqual(savedUpdatedAt, originalCreatedAt)
            XCTAssertNil(second.ACL)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testCreateAllServerMissingObjectId() async throws {
        let score = GameScore(points: 10)

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil)]
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
        let saved = try await [score].createAll()
        XCTAssertEqual(saved.count, 1)
        guard let savedObject = saved.first else {
            XCTFail("Should have one item")
            return
        }
        if case .failure(let error) = savedObject {
            XCTAssertEqual(error.code, .missingObjectId)
            XCTAssertTrue(error.message.contains("objectId"))
        } else {
            XCTFail("Should have thrown error")
        }
    }

    @MainActor
    func testCreateAllServerMissingCreatedAt() async throws {
        let score = GameScore(points: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yolo"
        scoreOnServer.ACL = nil

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil)]
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
        let saved = try await [score].createAll()
        XCTAssertEqual(saved.count, 1)
        guard let savedObject = saved.first else {
            XCTFail("Should have one item")
            return
        }
        if case .failure(let error) = savedObject {
            XCTAssertEqual(error.code, .unknownError)
            XCTAssertTrue(error.message.contains("createdAt"))
        } else {
            XCTFail("Should have thrown error")
        }
    }

    @MainActor
    func testReplaceAll() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        var score2 = GameScore(points: 20)
        score2.objectId = "yolo"

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.objectId = "yolo"
        scoreOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
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

        let saved = try await [score, score2].replaceAll()
        XCTAssertEqual(saved.count, 2)
        switch saved[0] {

        case .success(let first):
            XCTAssert(first.hasSameObjectId(as: scoreOnServerImmutable))
            guard let savedCreatedAt = first.createdAt,
                let savedUpdatedAt = first.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = scoreOnServerImmutable.createdAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, originalCreatedAt)
            XCTAssertEqual(savedUpdatedAt, originalCreatedAt)
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
            guard let originalCreatedAt = scoreOnServer2Immutable.createdAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, originalCreatedAt)
            XCTAssertEqual(savedUpdatedAt, originalCreatedAt)
            XCTAssertNil(second.ACL)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testReplaceAllUpdate() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        var score2 = GameScore(points: 20)
        score2.objectId = "yolo"

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()

        var scoreOnServer2 = score2
        scoreOnServer2.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
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

        let saved = try await [score, score2].replaceAll()
        XCTAssertEqual(saved.count, 2)
        switch saved[0] {

        case .success(let first):
            XCTAssert(first.hasSameObjectId(as: scoreOnServerImmutable))
            guard let savedUpdatedAt = first.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalUpdatedAt = scoreOnServerImmutable.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(first.ACL)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        switch saved[1] {

        case .success(let second):
            XCTAssert(second.hasSameObjectId(as: scoreOnServer2Immutable))
            guard let savedUpdatedAt = second.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalUpdatedAt = scoreOnServer2Immutable.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(second.ACL)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testReplaceAllServerMissingObjectId() async throws {
        let score = GameScore(points: 10)

        do {
            _ = try await [score].replaceAll()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertEqual(parseError.code, .missingObjectId)
        }
    }

    @MainActor
    func testReplaceAllServerMissingUpdatedAt() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yolo"

        let scoreOnServer = score

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil)]
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
        let saved = try await [score].replaceAll()
        XCTAssertEqual(saved.count, 1)
        guard let savedObject = saved.first else {
            XCTFail("Should have one item")
            return
        }
        if case .failure(let error) = savedObject {
            XCTAssertEqual(error.code, .unknownError)
            XCTAssertTrue(error.message.contains("updatedAt"))
        } else {
            XCTFail("Should have thrown error")
        }
    }

    @MainActor
    func testUpdateAll() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        var score2 = GameScore(points: 20)
        score2.objectId = "yolo"

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()

        var scoreOnServer2 = score2
        scoreOnServer2.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
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

        let saved = try await [score, score2].updateAll()
        XCTAssertEqual(saved.count, 2)
        switch saved[0] {

        case .success(let first):
            XCTAssert(first.hasSameObjectId(as: scoreOnServerImmutable))
            guard let savedUpdatedAt = first.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalUpdatedAt = scoreOnServerImmutable.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(first.ACL)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        switch saved[1] {

        case .success(let second):
            XCTAssert(second.hasSameObjectId(as: scoreOnServer2Immutable))
            guard let savedUpdatedAt = second.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalUpdatedAt = scoreOnServer2Immutable.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(second.ACL)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testUpdateAllServerMissingUpdatedAt() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yolo"

        var scoreOnServer = score
        scoreOnServer.ACL = nil

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil)]
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
        let saved = try await [score].updateAll()
        XCTAssertEqual(saved.count, 1)
        guard let savedObject = saved.first else {
            XCTFail("Should have one item")
            return
        }
        if case .failure(let error) = savedObject {
            XCTAssertEqual(error.code, .unknownError)
            XCTAssertTrue(error.message.contains("updatedAt"))
        } else {
            XCTFail("Should have thrown error")
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
