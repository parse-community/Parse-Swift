//
//  ParseObjectCustomObjectId.swift
//  ParseSwift
//
//  Created by Corey Baker on 3/20/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseObjectCustomObjectId: XCTestCase { // swiftlint:disable:this type_body_length
    struct Level: ParseObject {
        var objectId: String?

        var createdAt: Date?

        var updatedAt: Date?

        var ACL: ParseACL?

        var name = "First"
    }

    struct GameScore: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: Int?
        var player: String?
        var level: Level?
        var levels: [Level]?

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

    struct Game: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: GameScore
        var scores = [GameScore]()
        var name = "Hello"
        var profilePicture: ParseFile?

        //: a custom initializer
        init(score: GameScore) {
            self.score = score
        }
    }

    struct User: ParseUser {

        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        // provided by User
        var username: String?
        var email: String?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?
    }

    struct Installation: ParseInstallation {
        var installationId: String?
        var deviceType: String?
        var deviceToken: String?
        var badge: Int?
        var timeZone: String?
        var channels: [String]?
        var appName: String?
        var appIdentifier: String?
        var appVersion: String?
        var parseVersion: String?
        var localeIdentifier: String?
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var customKey: String?
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
                              allowCustomObjectId: true,
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()

        guard let fileManager = ParseFileManager(),
              let defaultDirectoryPath = fileManager.defaultDataDirectoryPath else {
            throw ParseError(code: .unknownError, message: "Should have initialized file manage")
        }

        let directory2 = defaultDirectoryPath
            .appendingPathComponent(ParseConstants.fileDownloadsDirectory, isDirectory: true)
        let expectation2 = XCTestExpectation(description: "Delete files2")
        fileManager.removeDirectoryContents(directory2) { _ in
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 20.0)
    }

    #if !os(Linux)
    func testSaveCommand() throws {
        let objectId = "yarr"
        var score = GameScore(score: 10)
        score.objectId = objectId
        let className = score.className

        let command = score.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.data)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"score\":10,\"player\":\"Jen\",\"objectId\":\"yarr\"}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testUpdateCommand() throws {
        var score = GameScore(score: 10)
        let className = score.className
        let objectId = "yarr"
        score.objectId = objectId
        score.createdAt = Date()
        score.updatedAt = score.createdAt

        let command = score.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.data)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"score\":10,\"player\":\"Jen\",\"objectId\":\"yarr\"}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testSaveAllCommand() throws {
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        var score2 = GameScore(score: 20)
        score2.objectId = "yolo"

        let objects = [score, score2]
        let commands = objects.map { $0.saveCommand() }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"path\":\"\\/classes\\/GameScore\\/yarr\",\"method\":\"POST\",\"body\":{\"score\":10,\"player\":\"Jen\",\"objectId\":\"yarr\"}},{\"path\":\"\\/classes\\/GameScore\\/yolo\",\"method\":\"POST\",\"body\":{\"score\":20,\"player\":\"Jen\",\"objectId\":\"yolo\"}}],\"transaction\":false}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testUpdateAllCommand() throws {
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        score.createdAt = Date()
        var score2 = GameScore(score: 20)
        score2.objectId = "yolo"
        score2.createdAt = Date()

        let objects = [score, score2]
        let commands = objects.map { $0.saveCommand() }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"path\":\"\\/classes\\/GameScore\\/yarr\",\"method\":\"PUT\",\"body\":{\"score\":10,\"player\":\"Jen\",\"objectId\":\"yarr\"}},{\"path\":\"\\/classes\\/GameScore\\/yolo\",\"method\":\"PUT\",\"body\":{\"score\":20,\"player\":\"Jen\",\"objectId\":\"yolo\"}}],\"transaction\":false}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testUserSaveCommand() throws {
        let objectId = "yarr"
        var user = User()
        user.objectId = objectId

        let command = user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.data)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"objectId\":\"yarr\"}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testUserUpdateCommand() throws {
        let objectId = "yarr"
        var user = User()
        user.objectId = objectId
        user.createdAt = Date()

        let command = user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.data)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"objectId\":\"yarr\"}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testUserSaveAllCommand() throws {
        var user = User()
        user.objectId = "yarr"
        var user2 = User()
        user2.objectId = "yolo"

        let objects = [user, user2]
        let commands = objects.map { $0.saveCommand() }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"path\":\"\\/users\\/yarr\",\"method\":\"POST\",\"body\":{\"objectId\":\"yarr\"}},{\"path\":\"\\/users\\/yolo\",\"method\":\"POST\",\"body\":{\"objectId\":\"yolo\"}}],\"transaction\":false}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testUserUpdateAllCommand() throws {
        var user = User()
        user.objectId = "yarr"
        user.createdAt = Date()
        var user2 = User()
        user2.objectId = "yolo"
        user2.createdAt = Date()

        let objects = [user, user2]
        let commands = objects.map { $0.saveCommand() }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"path\":\"\\/users\\/yarr\",\"method\":\"PUT\",\"body\":{\"objectId\":\"yarr\"}},{\"path\":\"\\/users\\/yolo\",\"method\":\"PUT\",\"body\":{\"objectId\":\"yolo\"}}],\"transaction\":false}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testInstallationSaveCommand() throws {
        let objectId = "yarr"
        var installation = Installation()
        installation.objectId = objectId

        let command = installation.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.data)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"objectId\":\"yarr\"}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testInstallationUpdateCommand() throws {
        let objectId = "yarr"
        var installation = Installation()
        installation.objectId = objectId
        installation.createdAt = Date()

        let command = installation.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.data)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"objectId\":\"yarr\"}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testInstallationSaveAllCommand() throws {
        var installation = Installation()
        installation.objectId = "yarr"
        var installation2 = Installation()
        installation2.objectId = "yolo"

        let objects = [installation, installation2]
        let commands = objects.map { $0.saveCommand() }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"path\":\"\\/installations\\/yarr\",\"method\":\"POST\",\"body\":{\"objectId\":\"yarr\"}},{\"path\":\"\\/installations\\/yolo\",\"method\":\"POST\",\"body\":{\"objectId\":\"yolo\"}}],\"transaction\":false}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testInstallationUpdateAllCommand() throws {
        var installation = Installation()
        installation.objectId = "yarr"
        installation.createdAt = Date()
        var installation2 = Installation()
        installation2.objectId = "yolo"
        installation2.createdAt = Date()

        let objects = [installation, installation2]
        let commands = objects.map { $0.saveCommand() }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"path\":\"\\/installations\\/yarr\",\"method\":\"PUT\",\"body\":{\"objectId\":\"yarr\"}},{\"path\":\"\\/installations\\/yolo\",\"method\":\"PUT\",\"body\":{\"objectId\":\"yolo\"}}],\"transaction\":false}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }
    #endif

    func testSave() { // swiftlint:disable:this function_body_length
        var score = GameScore(score: 10)
        score.objectId = "yarr"

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt

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
            let saved = try score.save()
            XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveNoObjectId() throws {
        let score = GameScore(score: 10)
        XCTAssertThrowsError(try score.save())
    }

    func testUpdate() {
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
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
            let saved = try score.save()
            XCTAssertTrue(saved.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdateNoObjectId() throws {
        var score = GameScore(score: 10)
        score.createdAt = Date()
        XCTAssertThrowsError(try score.save())
    }

    // swiftlint:disable:next function_body_length
    func saveAsync(score: GameScore, scoreOnServer: GameScore, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Save object1")

        score.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Save object2")
        score.save(options: [.useMasterKey], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testSaveAsyncMainQueue() {
        var score = GameScore(score: 10)
        score.objectId = "yarr"

        var scoreOnServer = score
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

        self.saveAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func updateAsync(score: GameScore, scoreOnServer: GameScore, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        score.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                guard let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                guard let originalUpdatedAt = score.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Update object2")
        score.save(options: [.useMasterKey], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertTrue(saved.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testUpdateAsyncMainQueue() {
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
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
        self.updateAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testSaveAll() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        var score2 = GameScore(score: 20)
        score2.objectId = "yolo"

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        scoreOnServer2.updatedAt = scoreOnServer2.createdAt
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

            let saved = try [score, score2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: scoreOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAllNoObjectId() throws {
        let score = GameScore(score: 10)
        let score2 = GameScore(score: 20)
        XCTAssertThrowsError(try [score, score2].saveAll())
    }

    func testUpdateAll() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        score.createdAt = Date()
        var score2 = GameScore(score: 20)
        score2.objectId = "yolo"
        score2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        var scoreOnServer = score
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.updatedAt = scoreOnServer2.createdAt
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

            let saved = try [score, score2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: scoreOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdateAllNoObjectId() throws {
        var score = GameScore(score: 10)
        score.createdAt = Date()
        var score2 = GameScore(score: 20)
        score2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        XCTAssertThrowsError(try [score, score2].saveAll())
    }

    func testUserSave() { // swiftlint:disable:this function_body_length
        var user = User()
        user.objectId = "yarr"
        user.ACL = nil

        var userOnServer = user
        userOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        userOnServer.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        do {
            let saved = try user.save()
            XCTAssert(saved.hasSameObjectId(as: userOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUserSaveNoObjectId() throws {
        let score = GameScore(score: 10)
        XCTAssertThrowsError(try score.save())
    }

    func testUserUpdate() {
        var user = User()
        user.objectId = "yarr"
        user.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        do {
            let saved = try user.save()
            XCTAssertTrue(saved.hasSameObjectId(as: userOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUserUpdateNoObjectId() throws {
        var user = User()
        user.createdAt = Date()
        XCTAssertThrowsError(try user.save())
    }

    // swiftlint:disable:next function_body_length
    func saveUserAsync(user: User, userOnServer: User, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        user.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertTrue(saved.hasSameObjectId(as: userOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUserSaveAsyncMainQueue() {
        var user = User()
        user.objectId = "yarr"
        user.ACL = nil

        var userOnServer = user
        userOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        userOnServer.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        self.saveUserAsync(user: user, userOnServer: userOnServer, callbackQueue: .main)
    }

    func updateUserAsync(user: User, userOnServer: User, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        user.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertTrue(saved.hasSameObjectId(as: userOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUserUpdateAsyncMainQueue() {
        var user = User()
        user.objectId = "yarr"
        user.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.updatedAt = Date()
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        self.updateUserAsync(user: user, userOnServer: userOnServer, callbackQueue: .main)
    }

    func testUserSaveAll() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        var user = User()
        user.objectId = "yarr"

        var user2 = User()
        user2.objectId = "yolo"

        var userOnServer = user
        userOnServer.createdAt = Date()
        userOnServer.updatedAt = userOnServer.createdAt
        userOnServer.ACL = nil

        var userOnServer2 = user2
        userOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        userOnServer2.updatedAt = userOnServer2.createdAt
        userOnServer2.ACL = nil

        let response = [BatchResponseItem<User>(success: userOnServer, error: nil),
        BatchResponseItem<User>(success: userOnServer2, error: nil)]
        let encoded: Data!
        do {
            encoded = try userOnServer.getJSONEncoder().encode(response)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(userOnServer)
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded1)
            let encoded2 = try ParseCoding.jsonEncoder().encode(userOnServer2)
            userOnServer2 = try userOnServer.getDecoder().decode(User.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {

            let saved = try [user, user2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: userOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: userOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUserSaveAllNoObjectId() throws {
        let user = User()
        let user2 = User()
        XCTAssertThrowsError(try [user, user2].saveAll())
    }

    func testUserUpdateAll() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        var user = User()
        user.objectId = "yarr"
        user.createdAt = Date()
        var user2 = User()
        user2.objectId = "yolo"
        user2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        var userOnServer = user
        userOnServer.updatedAt = userOnServer.createdAt
        userOnServer.ACL = nil

        var userOnServer2 = user2
        userOnServer2.updatedAt = userOnServer2.createdAt
        userOnServer2.ACL = nil

        let response = [BatchResponseItem<User>(success: userOnServer, error: nil),
        BatchResponseItem<User>(success: userOnServer2, error: nil)]
        let encoded: Data!
        do {
            encoded = try userOnServer.getJSONEncoder().encode(response)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(userOnServer)
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded1)
            let encoded2 = try ParseCoding.jsonEncoder().encode(userOnServer2)
            userOnServer2 = try userOnServer.getDecoder().decode(User.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {

            let saved = try [user, user2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: userOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: userOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUserUpdateAllNoObjectId() throws {
        var user = User()
        user.createdAt = Date()
        var user2 = User()
        user2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        XCTAssertThrowsError(try [user, user2].saveAll())
    }

    func testInstallationSave() { // swiftlint:disable:this function_body_length
        var installation = Installation()
        installation.objectId = "yarr"
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installationOnServer.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            //Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        do {
            let saved = try installation.save()
            XCTAssert(saved.hasSameObjectId(as: installationOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testInstallationSaveNoObjectId() throws {
        let score = GameScore(score: 10)
        XCTAssertThrowsError(try score.save())
    }

    func testInstallationUpdate() {
        var installation = Installation()
        installation.objectId = "yarr"
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            //Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        do {
            let saved = try installation.save()
            XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testInstallationUpdateNoObjectId() throws {
        var installation = Installation()
        installation.createdAt = Date()
        XCTAssertThrowsError(try installation.save())
    }

    // swiftlint:disable:next function_body_length
    func saveInstallationAsync(installation: Installation,
                               installationOnServer: Installation,
                               callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        installation.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Update object2")
        installation.save(options: [.useMasterKey], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testInstallationSaveAsyncMainQueue() {
        var installation = Installation()
        installation.objectId = "yarr"
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installationOnServer.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            //Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        self.saveInstallationAsync(installation: installation,
                                   installationOnServer: installationOnServer,
                                   callbackQueue: .main)
    }

    func updateInstallationAsync(installation: Installation,
                                 installationOnServer: Installation,
                                 callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        installation.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testInstallationUpdateAsyncMainQueue() {
        var installation = Installation()
        installation.objectId = "yarr"
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.updatedAt = Date()
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            //Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        self.updateInstallationAsync(installation: installation,
                                     installationOnServer: installationOnServer,
                                     callbackQueue: .main)
    }

    func testInstallationSaveAll() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        var installation = Installation()
        installation.objectId = "yarr"

        var installation2 = Installation()
        installation2.objectId = "yolo"

        var installationOnServer = installation
        installationOnServer.createdAt = Date()
        installationOnServer.updatedAt = installationOnServer.createdAt
        installationOnServer.ACL = nil

        var installationOnServer2 = installation2
        installationOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installationOnServer2.updatedAt = installationOnServer2.createdAt
        installationOnServer2.ACL = nil

        let response = [BatchResponseItem<Installation>(success: installationOnServer, error: nil),
        BatchResponseItem<Installation>(success: installationOnServer2, error: nil)]
        let encoded: Data!
        do {
            encoded = try installationOnServer.getJSONEncoder().encode(response)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(installationOnServer)
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded1)
            let encoded2 = try ParseCoding.jsonEncoder().encode(installationOnServer2)
            installationOnServer2 = try installationOnServer.getDecoder().decode(Installation.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {

            let saved = try [installation, installation2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: installationOnServer))
                guard let savedCreatedAt = first.createdAt,
                    let savedUpdatedAt = first.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = installationOnServer.createdAt,
                    let originalUpdatedAt = installationOnServer.updatedAt else {
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
                XCTAssert(second.hasSameObjectId(as: installationOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testInstallationSaveAllNoObjectId() throws {
        let installation = Installation()
        let installation2 = Installation()
        XCTAssertThrowsError(try [installation, installation2].saveAll())
    }

    func testInstallationUpdateAll() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        var installation = Installation()
        installation.objectId = "yarr"
        installation.createdAt = Date()
        var installation2 = Installation()
        installation2.objectId = "yolo"
        installation2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        var installationOnServer = installation
        installationOnServer.updatedAt = installationOnServer.createdAt
        installationOnServer.ACL = nil

        var installationOnServer2 = installation2
        installationOnServer2.updatedAt = installationOnServer2.createdAt
        installationOnServer2.ACL = nil

        let response = [BatchResponseItem<Installation>(success: installationOnServer, error: nil),
        BatchResponseItem<Installation>(success: installationOnServer2, error: nil)]
        let encoded: Data!
        do {
            encoded = try installationOnServer.getJSONEncoder().encode(response)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(installationOnServer)
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded1)
            let encoded2 = try ParseCoding.jsonEncoder().encode(installationOnServer2)
            installationOnServer2 = try installationOnServer.getDecoder().decode(Installation.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {

            let saved = try [installation, installation2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: installationOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: installationOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testInstallationUpdateAllNoObjectId() throws {
        var installation = Installation()
        installation.createdAt = Date()
        var installation2 = Installation()
        installation2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        XCTAssertThrowsError(try [installation, installation2].saveAll())
    }
}
