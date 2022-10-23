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
        // These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // Custom properties
        var points: Int = 0
        var other: Game2?
        var otherArray: [Game2]?

        //custom initializers
        init() {
            self.points = 5
        }
        init(points: Int) {
            self.points = points
        }

        init(objectId: String?) {
            self.objectId = objectId
        }
    }

    struct Game2: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var name = "Hello"
        var profilePicture: ParseFile?
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

    func testEncodeEmbeddedSavedObjectWithBatching() throws {
        var score = GameScore(points: 10)
        score.objectId = "yolo"
        score.createdAt = Date()
        score.updatedAt = Date()
        var game = Game2()
        game.createdAt = Date()
        game.updatedAt = Date()
        game.objectId = "brave"
        score.other = game
        let command = try score.saveCommand()
        let batch = API.Command<GameScore, GameScore>
            .batch(commands: [command], transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"body\":{\"requests\":[{\"body\":{\"other\":{\"__type\":\"Pointer\",\"className\":\"Game2\",\"objectId\":\"brave\"},\"points\":10},\"method\":\"PUT\",\"path\":\"\\/1\\/classes\\/GameScore\\/yolo\"}],\"transaction\":false},\"method\":\"POST\",\"path\":\"\\/batch\"}"
        let encoded = try ParseCoding.parseEncoder().encode(batch,
                                                            batching: true)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testEncodeMutltipleEmbeddedSavedObjectWithBatching() throws {
        var score = GameScore(points: 10)
        score.objectId = "yolo"
        score.createdAt = Date()
        score.updatedAt = Date()
        var game = Game2()
        game.createdAt = Date()
        game.updatedAt = Date()
        game.objectId = "brave"
        score.other = game
        let command = try score.saveCommand()
        let batch = API.Command<GameScore, GameScore>
            .batch(commands: [command, command], transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"body\":{\"requests\":[{\"body\":{\"other\":{\"__type\":\"Pointer\",\"className\":\"Game2\",\"objectId\":\"brave\"},\"points\":10},\"method\":\"PUT\",\"path\":\"\\/1\\/classes\\/GameScore\\/yolo\"},{\"body\":{\"other\":{\"__type\":\"Pointer\",\"className\":\"Game2\",\"objectId\":\"brave\"},\"points\":10},\"method\":\"PUT\",\"path\":\"\\/1\\/classes\\/GameScore\\/yolo\"}],\"transaction\":false},\"method\":\"POST\",\"path\":\"\\/batch\"}"
        let encoded = try ParseCoding.parseEncoder().encode(batch,
                                                            batching: true)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testSaveAllCommand() throws {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)

        let objects = [score, score2]
        let commands = try objects.map { try $0.saveCommand() }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"body\":{\"points\":10},\"method\":\"POST\",\"path\":\"\\/classes\\/GameScore\"},{\"body\":{\"points\":20},\"method\":\"POST\",\"path\":\"\\/classes\\/GameScore\"}],\"transaction\":false}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body,
                    batching: true,
                    collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testSaveAll() { // swiftlint:disable:this function_body_length cyclomatic_complexity
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
           encoded = try scoreOnServer.getJSONEncoder().encode(response)
           // Get dates in correct format from ParseDecoding strategy
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

        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try [score, score2].saveAll(transaction: true,
                                                    options: [.installationId("hello")])
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
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAllWithPointer() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        var score = GameScore(points: 10)
        score.other = Game2()

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil)]
        let encoded: Data!
        do {
           encoded = try scoreOnServer.getJSONEncoder().encode(response)
           // Get dates in correct format from ParseDecoding strategy
           let encoded1 = try ParseCoding.jsonEncoder().encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded1)
        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {

            let saved = try [score].saveAll()

            XCTAssertEqual(saved.count, 1)
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

        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            _ = try [score].saveAll(transaction: true,
                                    options: [.installationId("hello")])
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("originally"))
        }
    }

    func testSaveAllWithPointerArray() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        var score = GameScore(points: 10)
        score.otherArray = [Game2()]

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil)]
        let encoded: Data!
        do {
           encoded = try scoreOnServer.getJSONEncoder().encode(response)
           // Get dates in correct format from ParseDecoding strategy
           let encoded1 = try ParseCoding.jsonEncoder().encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded1)
        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {

            let saved = try [score].saveAll()

            XCTAssertEqual(saved.count, 1)
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

        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            _ = try [score].saveAll(transaction: true,
                                    options: [.installationId("hello")])
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("originally"))
        }
    }

    func testSaveAllTransaction() { // swiftlint:disable:this function_body_length cyclomatic_complexity
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
           encoded = try scoreOnServer.getJSONEncoder().encode(response)
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

        do {

            let saved = try [score, score2].saveAll(transaction: true)

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

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAllTransactionErrorTooMany() {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)
        do {
            _ = try [score, score2].saveAll(batchLimit: 1, transaction: true)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Error should have casted to ParseError")
                return
            }
            XCTAssertEqual(parseError.code, .unknownError)
            XCTAssertTrue(parseError.message.contains("exceed"))
        }
    }

    func testSaveAllTransactionErrorChild() {
        let score = GameScore(points: 10)
        var score2 = GameScore(points: 20)
        score2.other = Game2()
        do {
            _ = try [score, score2].saveAll(transaction: true)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Error should have casted to ParseError")
                return
            }
            XCTAssertEqual(parseError.code, .unknownError)
            XCTAssertTrue(parseError.message.contains("originally"))
        }
    }

    func testSaveAllErrorIncorrectServerResponse() {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.objectId = "yolo"
        scoreOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -2), to: Date())
        scoreOnServer2.ACL = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode([scoreOnServer, scoreOnServer2])
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
            let saved = try [score, score2].saveAll(transaction: true,
                                                    options: [.usePrimaryKey])

            XCTAssertEqual(saved.count, 2)
            XCTAssertThrowsError(try saved[0].get())
            XCTAssertThrowsError(try saved[1].get())

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdateAllCommand() throws {
        var score = GameScore(points: 10)
        var score2 = GameScore(points: 20)

        score.objectId = "yarr"
        score.createdAt = Date()
        score.updatedAt = score.createdAt
        score2.objectId = "yolo"
        score2.createdAt = Date()
        score2.updatedAt = score2.createdAt

        let objects = [score, score2]
        let initialCommands = try objects.map { try $0.saveCommand() }
        let commands = initialCommands.compactMap { (command) -> API.Command<GameScore, GameScore>? in
            let path = ParseSwift.configuration.mountPath + command.path.urlComponent
            guard let body = command.body else {
                return nil
            }
            return API.Command<GameScore, GameScore>(method: command.method, path: .any(path),
                                     body: body, mapper: command.mapper)
        }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"body\":{\"points\":10},\"method\":\"PUT\",\"path\":\"\\/1\\/classes\\/GameScore\\/yarr\"},{\"body\":{\"points\":20},\"method\":\"PUT\",\"path\":\"\\/1\\/classes\\/GameScore\\/yolo\"}],\"transaction\":false}"

        let encoded = try ParseCoding.parseEncoder()
            .encode(body,
                    batching: true,
                    collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testUpdateAll() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil
        var game = Game2()
        game.objectId = "brave"
        score.other = game

        var score2 = GameScore(points: 20)
        score2.objectId = "yolo"
        score2.updatedAt = Calendar.current.date(byAdding: .init(day: -2), to: Date())
        score2.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
        var scoreOnServer2 = score2
        scoreOnServer2.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

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

        do {
            let saved = try [score, score2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):

                guard let savedUpdatedAt = first.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
                }
                guard let originalUpdatedAt = score.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
                }
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(first.ACL)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):

                guard let savedUpdatedAt2 = second.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
                }
                guard let originalUpdatedAt2 = score2.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
                }

                XCTAssertGreaterThan(savedUpdatedAt2, originalUpdatedAt2)
                XCTAssertNil(second.ACL)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try [score, score2].saveAll(transaction: true,
                                                    options: [.usePrimaryKey])
            XCTAssertEqual(saved.count, 2)

            switch saved[0] {

            case .success(let first):
                guard let savedUpdatedAt = first.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
                }
                guard let originalUpdatedAt = score.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
                }
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(first.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                guard let savedUpdatedAt2 = second.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
                }
                guard let originalUpdatedAt2 = score2.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
                }
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
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var score2 = GameScore(points: 20)
        score2.objectId = "yolo"
        score2.updatedAt = Calendar.current.date(byAdding: .init(day: -2), to: Date())
        score2.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
        var scoreOnServer2 = score2
        scoreOnServer2.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode([scoreOnServer, scoreOnServer2])
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
            let saved = try [score, score2].saveAll(transaction: true,
                                                    options: [.usePrimaryKey])

            XCTAssertEqual(saved.count, 2)
            XCTAssertThrowsError(try saved[0].get())
            XCTAssertThrowsError(try saved[1].get())

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAllMixed() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        let score = GameScore(points: 10)
        var score2 = GameScore(points: 20)
        score2.objectId = "yolo"
        score2.updatedAt = Calendar.current.date(byAdding: .init(day: -2), to: Date())
        score2.ACL = nil

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

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
                XCTAssertEqual(savedCreatedAt, scoreOnServer.createdAt)
                XCTAssertEqual(savedUpdatedAt, scoreOnServer.createdAt)
                XCTAssertNil(first.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                guard let savedUpdatedAt = second.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedUpdatedAt, scoreOnServer2.updatedAt)
                XCTAssertNil(second.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try [score, score2].saveAll(transaction: true,
                                                    options: [.usePrimaryKey])
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
                XCTAssertNil(second.createdAt)
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
                      transaction: Bool = false,
                      scoresOnServer: [GameScore], callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Save object1")
        guard let scoreOnServer = scoresOnServer.first,
            let scoreOnServer2 = scoresOnServer.last else {
            XCTFail("Should unwrap")
            expectation1.fulfill()
            return
        }

        scores.saveAll(transaction: transaction,
                       callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertEqual(saved.count, 2)
                guard let firstObject = saved.first,
                    let secondObject = saved.last else {
                        XCTFail("Should unwrap")
                        expectation1.fulfill()
                        return
                }

                switch firstObject {

                case .success(let first):
                    XCTAssert(first.hasSameObjectId(as: scoreOnServer))
                    guard let savedCreatedAt = first.createdAt,
                        let savedUpdatedAt = first.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    XCTAssertEqual(savedCreatedAt, scoreOnServer.createdAt)
                    XCTAssertEqual(savedUpdatedAt, scoreOnServer.createdAt)
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
                            expectation1.fulfill()
                            return
                    }
                    XCTAssertEqual(savedCreatedAt, scoreOnServer2.createdAt)
                    XCTAssertEqual(savedUpdatedAt, scoreOnServer2.createdAt)
                    XCTAssertNil(second.ACL)

                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Save object2")
        scores.saveAll(transaction: true,
                       options: [.usePrimaryKey],
                       callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertEqual(saved.count, 2)

                guard let firstObject = saved.first,
                    let secondObject = saved.last else {
                        XCTFail("Should unwrap")
                        expectation2.fulfill()
                        return
                }

                switch firstObject {

                case .success(let first):
                    guard let savedCreatedAt = first.createdAt,
                        let savedUpdatedAt = first.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation2.fulfill()
                            return
                    }
                    XCTAssertEqual(savedCreatedAt, scoreOnServer.createdAt)
                    XCTAssertEqual(savedUpdatedAt, scoreOnServer.createdAt)
                    XCTAssertNil(first.ACL)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

                switch secondObject {

                case .success(let second):
                    guard let savedCreatedAt = second.createdAt,
                        let savedUpdatedAt = second.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation2.fulfill()
                            return
                    }
                    XCTAssertEqual(savedCreatedAt, scoreOnServer2.createdAt)
                    XCTAssertEqual(savedUpdatedAt, scoreOnServer2.createdAt)
                    XCTAssertNil(second.ACL)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func saveAllAsyncPointer(scores: [GameScore], // swiftlint:disable:this function_body_length cyclomatic_complexity
                             transaction: Bool = false,
                             scoresOnServer: [GameScore], callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Save object1")
        guard let scoreOnServer = scoresOnServer.first else {
            XCTFail("Should unwrap")
            expectation1.fulfill()
            return
        }

        scores.saveAll(transaction: transaction,
                       callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertEqual(saved.count, 1)
                guard let firstObject = saved.first else {
                    XCTFail("Should unwrap")
                    expectation1.fulfill()
                    return
                }

                switch firstObject {

                case .success(let first):
                    XCTAssert(first.hasSameObjectId(as: scoreOnServer))
                    guard let savedCreatedAt = first.createdAt,
                        let savedUpdatedAt = first.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    XCTAssertEqual(savedCreatedAt, scoreOnServer.createdAt)
                    XCTAssertEqual(savedUpdatedAt, scoreOnServer.createdAt)
                    XCTAssertNil(first.ACL)

                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Save object2")
        scores.saveAll(transaction: true,
                       options: [.usePrimaryKey],
                       callbackQueue: callbackQueue) { result in

            switch result {

            case .success:
                XCTFail("Should have thrown error")
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("originally"))
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeSaveAllAsync() {
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

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            self.saveAllAsync(scores: [score, score2], scoresOnServer: [scoreOnServer, scoreOnServer2],
                              callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testSaveAllAsyncMainQueue() {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.objectId = "yolo"
        scoreOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -2), to: Date())
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
        self.saveAllAsync(scores: [score, score2], scoresOnServer: [scoreOnServer, scoreOnServer2],
                          callbackQueue: .main)
    }

    func testSaveAllAsyncPointer() {
        var score = GameScore(points: 10)
        score.other = Game2()

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil)]
        let encoded: Data!
        do {
           encoded = try ParseCoding.jsonEncoder().encode(response)
           // Get dates in correct format from ParseDecoding strategy
           let encoded1 = try ParseCoding.jsonEncoder().encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded1)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        self.saveAllAsyncPointer(scores: [score], scoresOnServer: [scoreOnServer],
                                 callbackQueue: .main)
    }

    func testSaveAlreadySavedEncode() throws {
        var score = GameScore(points: 10)
        var game = Game2()
        game.objectId = "brave"
        score.other = game
        // swiftlint:disable:next line_length
        let expected = "{\"other\":{\"__type\":\"Pointer\",\"className\":\"Game2\",\"objectId\":\"brave\"},\"points\":10}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(score, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testSaveAllAsyncPointerArray() {
        var score = GameScore(points: 10)
        score.otherArray = [Game2()]

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil)]
        let encoded: Data!
        do {
           encoded = try ParseCoding.jsonEncoder().encode(response)
           // Get dates in correct format from ParseDecoding strategy
           let encoded1 = try ParseCoding.jsonEncoder().encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded1)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        self.saveAllAsyncPointer(scores: [score], scoresOnServer: [scoreOnServer],
                                 callbackQueue: .main)
    }

    func testSaveAllAsyncTransaction() { // swiftlint:disable:this function_body_length cyclomatic_complexity
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
           encoded = try scoreOnServer.getJSONEncoder().encode(response)
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

        self.saveAllAsync(scores: [score, score2],
                          transaction: true,
                          scoresOnServer: [scoreOnServer, scoreOnServer2],
                          callbackQueue: .main)
    }

    func testSaveAllAsyncTransactionErrorTooMany() {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)
        let expectation1 = XCTestExpectation(description: "Save object1")
        [score, score2].saveAll(batchLimit: 1, transaction: true) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.code, .unknownError)
                XCTAssertTrue(error.message.contains("exceed"))
            } else {
                XCTFail("Should have received error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveAllAsyncTransactionErrorChild() {
        let score = GameScore(points: 10)
        var score2 = GameScore(points: 20)
        score2.other = Game2()
        let expectation1 = XCTestExpectation(description: "Save object1")
        [score, score2].saveAll(transaction: true) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.code, .unknownError)
                XCTAssertTrue(error.message.contains("originally"))
            } else {
                XCTFail("Should have received error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    /* Note, the current batchCommand for updateAll returns the original object that was updated as
    opposed to the latestUpdated. The objective c one just returns true/false */
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func updateAllAsync(scores: [GameScore], scoresOnServer: [GameScore],
                        callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        scores.saveAll(callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                guard let firstObject = saved.first,
                    let secondObject = saved.last else {
                        XCTFail("Should unwrap")
                        expectation1.fulfill()
                    return
                }

                switch firstObject {

                case .success(let first):
                    guard let savedUpdatedAt = first.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                    }
                    guard let originalUpdatedAt = scores.first?.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }

                    XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertNil(first.ACL)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

                switch secondObject {

                case .success(let second):
                    guard let savedUpdatedAt2 = second.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                    }
                    guard let originalUpdatedAt2 = scores.last?.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                    }

                    XCTAssertGreaterThan(savedUpdatedAt2,
                                         originalUpdatedAt2)
                    XCTAssertNil(second.ACL)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Update object2")
        scores.saveAll(transaction: true,
                       options: [.usePrimaryKey],
                       callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                guard let firstObject = saved.first,
                    let secondObject = saved.last else {
                        expectation2.fulfill()
                        XCTFail("Should unwrap")
                    return
                }

                switch firstObject {

                case .success(let first):
                    guard let savedUpdatedAt = first.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                    }
                    guard let originalUpdatedAt = scores.first?.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                    }

                    XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertNil(first.ACL)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

                switch secondObject {

                case .success(let second):
                    guard let savedUpdatedAt2 = second.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                    }
                    guard let originalUpdatedAt2 = scores.last?.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                    }

                    XCTAssertGreaterThan(savedUpdatedAt2,
                                         originalUpdatedAt2)
                    XCTAssertNil(second.ACL)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeUpdateAllAsync() {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var score2 = GameScore(points: 20)
        score2.objectId = "yolo"
        score2.updatedAt = Calendar.current.date(byAdding: .init(day: -2), to: Date())
        score2.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
        var scoreOnServer2 = score2
        scoreOnServer2.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

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

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            self.updateAllAsync(scores: [score, score2],
                                scoresOnServer: [scoreOnServer, scoreOnServer2],
                                callbackQueue: .global(qos: .background))
        }
    }

    func testUpdateAllAsyncMainQueue() {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var score2 = GameScore(points: 20)
        score2.objectId = "yolo"
        score2.updatedAt = Calendar.current.date(byAdding: .init(day: -2), to: Date())
        score2.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
        var scoreOnServer2 = score2
        scoreOnServer2.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

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
        self.updateAllAsync(scores: [score, score2],
                            scoresOnServer: [scoreOnServer, scoreOnServer2],
                            callbackQueue: .main)
    }
    #endif

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func testFetchAll() {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

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

        do {
            let fetched = try [GameScore(objectId: "yarr"), GameScore(objectId: "yolo")].fetchAll()

            XCTAssertEqual(fetched.count, 2)
            guard let firstObject = try? fetched.first(where: {try $0.get().objectId == "yarr"}),
                let secondObject = try? fetched.first(where: {try $0.get().objectId == "yolo"}) else {
                    XCTFail("Should unwrap")
                    return
            }

            switch firstObject {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: scoreOnServer))
                guard let fetchedCreatedAt = first.createdAt,
                    let fetchedUpdatedAt = first.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = scoreOnServer.createdAt,
                    let originalUpdatedAt = scoreOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(first.ACL)
                XCTAssertEqual(first.points, scoreOnServer.points)
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
                XCTAssertEqual(second.points, scoreOnServer2.points)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func fetchAllAsync(scores: [GameScore], scoresOnServer: [GameScore],
                       callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Fetch object1")
        guard let scoreOnServer = scoresOnServer.first,
            let scoreOnServer2 = scoresOnServer.last else {
            XCTFail("Should unwrap")
            expectation1.fulfill()
            return
        }

        [GameScore(objectId: "yarr"), GameScore(objectId: "yolo")].fetchAll(options: [],
                                                                            callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let fetched):
                XCTAssertEqual(fetched.count, 2)
                guard let firstObject = try? fetched.first(where: {try $0.get().objectId == "yarr"}),
                    let secondObject = try? fetched.first(where: {try $0.get().objectId == "yolo"}) else {
                        XCTFail("Should unwrap")
                        expectation1.fulfill()
                        return
                }

                switch firstObject {

                case .success(let first):
                    XCTAssert(first.hasSameObjectId(as: scoreOnServer))
                    guard let savedCreatedAt = first.createdAt,
                        let savedUpdatedAt = first.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    guard let originalCreatedAt = scoreOnServer.createdAt,
                        let originalUpdatedAt = scoreOnServer.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertNil(first.ACL)
                    XCTAssertEqual(first.points, scoreOnServer.points)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

                switch secondObject {

                case .success(let second):
                    XCTAssert(second.hasSameObjectId(as: scoreOnServer2))
                    guard let savedCreatedAt = second.createdAt,
                        let savedUpdatedAt = second.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    guard let originalCreatedAt = scoreOnServer2.createdAt,
                        let originalUpdatedAt = scoreOnServer2.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertNil(second.ACL)
                    XCTAssertEqual(second.points, scoreOnServer2.points)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeFetchAllAsync() {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

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

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            self.fetchAllAsync(scores: [score, score2], scoresOnServer: [scoreOnServer, scoreOnServer2],
                              callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testFetchAllAsyncMainQueue() {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

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
        self.fetchAllAsync(scores: [score, score2], scoresOnServer: [scoreOnServer, scoreOnServer2],
                          callbackQueue: .main)
    }

    func testDeleteAll() {
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

        do {
            let deleted = try [GameScore(objectId: "yarr"), GameScore(objectId: "yolo")].deleteAll()

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
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let deleted = try [GameScore(objectId: "yarr"), GameScore(objectId: "yolo")]
                .deleteAll(transaction: true)

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
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDeleteAllTransaction() {
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

        do {
            let deleted = try [GameScore(objectId: "yarr"), GameScore(objectId: "yolo")].deleteAll(transaction: true)

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
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let deleted = try [GameScore(objectId: "yarr"), GameScore(objectId: "yolo")]
                .deleteAll(transaction: true)

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
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDeleteAllTransactionErrorTooMany() {
        do {
            _ = try [GameScore(objectId: "yarr"),
                     GameScore(objectId: "yolo")].deleteAll(batchLimit: 1,
                                                            transaction: true)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Error should have casted to ParseError")
                return
            }
            XCTAssertEqual(parseError.code, .unknownError)
            XCTAssertTrue(parseError.message.contains("exceed"))
        }
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testDeleteAllError() {
        let parseError = ParseError(code: .objectNotFound, message: "Object not found")
        let response = [BatchResponseItem<NoBody>(success: nil, error: parseError),
                        BatchResponseItem<NoBody>(success: nil, error: parseError)]
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

        do {
            let deleted = try [GameScore(objectId: "yarr"), GameScore(objectId: "yolo")].deleteAll()

            XCTAssertEqual(deleted.count, 2)
            guard let firstObject = deleted.first else {
                    XCTFail("Should have thrown ParseError")
                    return
            }

            if case let .failure(error) = firstObject {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }

            guard let lastObject = deleted.last else {
                    XCTFail("Should have thrown ParseError")
                    return
            }

            if case let .failure(error) = lastObject {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    #endif

    func deleteAllAsync(transaction: Bool = false, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Delete object1")
        let expectation2 = XCTestExpectation(description: "Delete object2")

        [GameScore(objectId: "yarr"), GameScore(objectId: "yolo")]
            .deleteAll(transaction: transaction, callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let deleted):
                XCTAssertEqual(deleted.count, 2)
                guard let firstObject = deleted.first else {
                    XCTFail("Should unwrap")
                    expectation1.fulfill()
                    return
                }

                if case let .failure(error) = firstObject {
                    XCTFail(error.localizedDescription)
                }

                guard let lastObject = deleted.last else {
                    XCTFail("Should unwrap")
                    expectation1.fulfill()
                    return
                }

                if case let .failure(error) = lastObject {
                    XCTFail(error.localizedDescription)
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        [GameScore(objectId: "yarr"), GameScore(objectId: "yolo")]
            .deleteAll(transaction: true,
                       callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let deleted):
                XCTAssertEqual(deleted.count, 2)
                guard let firstObject = deleted.first else {
                    XCTFail("Should unwrap")
                    expectation2.fulfill()
                    return
                }

                if case let .failure(error) = firstObject {
                    XCTFail(error.localizedDescription)
                }

                guard let lastObject = deleted.last else {
                    XCTFail("Should unwrap")
                    expectation2.fulfill()
                    return
                }

                if case let .failure(error) = lastObject {
                    XCTFail(error.localizedDescription)
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
                expectation2.fulfill()
        }

        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testDeleteAllAsyncMainQueue() {
        let response = [BatchResponseItem<NoBody>(success: NoBody(), error: nil),
                        BatchResponseItem<NoBody>(success: NoBody(), error: nil)]

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(response)
            MockURLProtocol.mockRequests { _ in
               return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            }
        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }

        self.deleteAllAsync(callbackQueue: .main)
    }

    func testDeleteAllAsyncMainQueueTransaction() {
        let response = [BatchResponseItem<NoBody>(success: NoBody(), error: nil),
                        BatchResponseItem<NoBody>(success: NoBody(), error: nil)]

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(response)
            MockURLProtocol.mockRequests { _ in
               return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            }
        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }

        self.deleteAllAsync(transaction: true, callbackQueue: .main)
    }

    func testDeleteAllAsyncTransactionErrorTooMany() {
        let expectation1 = XCTestExpectation(description: "Save object1")
        [GameScore(objectId: "yarr"),
         GameScore(objectId: "yolo")].deleteAll(batchLimit: 1,
                                                transaction: true) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error.code, .unknownError)
                XCTAssertTrue(error.message.contains("exceed"))
            } else {
                XCTFail("Should have received error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func deleteAllAsyncError(parseError: ParseError, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Delete object1")

        [GameScore(objectId: "yarr"), GameScore(objectId: "yolo")]
            .deleteAll(callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let deleted):
                XCTAssertEqual(deleted.count, 2)
                guard let firstObject = deleted.first else {
                    XCTFail("Should have thrown ParseError")
                    expectation1.fulfill()
                    return
                }

                if case let .failure(error) = firstObject {
                    XCTAssertEqual(error.code, parseError.code)
                } else {
                    XCTFail("Should have thrown ParseError")
                }

                guard let lastObject = deleted.last else {
                    XCTFail("Should have thrown ParseError")
                    expectation1.fulfill()
                    return
                }

                if case let .failure(error) = lastObject {
                    XCTAssertEqual(error.code, parseError.code)
                } else {
                    XCTFail("Should have thrown ParseError")
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteAllAsyncMainQueueError() {

        let parseError = ParseError(code: .objectNotFound, message: "Object not found")
        let response = [BatchResponseItem<NoBody>(success: nil, error: parseError),
                        BatchResponseItem<NoBody>(success: nil, error: parseError)]

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(response)
            MockURLProtocol.mockRequests { _ in
               return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            }
        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }

        self.deleteAllAsyncError(parseError: parseError, callbackQueue: .main)
    }
}// swiftlint:disable:this file_length
