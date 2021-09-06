//
//  ParseObjectCustomObjectIdTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 3/20/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseObjectCustomObjectIdTests: XCTestCase { // swiftlint:disable:this type_body_length
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
        var emailVerified: Bool?
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
        #if !os(Linux) && !os(Android)
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

    #if !os(Linux) && !os(Android)
    func testSaveCommand() throws {
        let objectId = "yarr"
        var score = GameScore(score: 10)
        score.objectId = objectId
        let className = score.className

        let command = try score.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)")
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

        let command = try score.saveCommand()
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
        let commands = try objects.map { try $0.saveCommand() }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"path\":\"\\/classes\\/GameScore\",\"method\":\"POST\",\"body\":{\"score\":10,\"player\":\"Jen\",\"objectId\":\"yarr\"}},{\"path\":\"\\/classes\\/GameScore\",\"method\":\"POST\",\"body\":{\"score\":20,\"player\":\"Jen\",\"objectId\":\"yolo\"}}],\"transaction\":false}"
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
        let commands = try objects.map { try $0.saveCommand() }
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

        let command = try user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
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

        let command = try user.saveCommand()
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
        let commands = try objects.map { try $0.saveCommand() }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"path\":\"\\/users\",\"method\":\"POST\",\"body\":{\"objectId\":\"yarr\"}},{\"path\":\"\\/users\",\"method\":\"POST\",\"body\":{\"objectId\":\"yolo\"}}],\"transaction\":false}"
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
        let commands = try objects.map { try $0.saveCommand() }
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

        let command = try installation.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations")
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

        let command = try installation.saveCommand()
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
        let commands = try objects.map { try $0.saveCommand() }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"path\":\"\\/installations\",\"method\":\"POST\",\"body\":{\"objectId\":\"yarr\"}},{\"path\":\"\\/installations\",\"method\":\"POST\",\"body\":{\"objectId\":\"yolo\"}}],\"transaction\":false}"
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
        let commands = try objects.map { try $0.saveCommand() }
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

    func testSaveCommandNoObjectId() throws {
        let score = GameScore(score: 10)
        XCTAssertThrowsError(try score.saveCommand())
    }

    func testSaveCommandNoObjectIdIgnoreConfig() throws {
        let score = GameScore(score: 10)
        _ = try score.saveCommand(isIgnoreCustomObjectIdConfig: true)
    }
    
    func testSaveCommandNoObjectIdCreateWithCustomId() throws {
        let score = GameScore(score: 10)
        _ = try score.saveCommand(createWithCustomObjectId: true)
    }
    
    func testSaveCommandNoObjectIdIgnoreConfigCreateWithCustomId() throws {
        let score = GameScore(score: 10)
        _ = try score.saveCommand(isIgnoreCustomObjectIdConfig: true, createWithCustomObjectId: true)
    }

    func testUpdateCommandNoObjectId() throws {
        var score = GameScore(score: 10)
        score.createdAt = Date()
        XCTAssertThrowsError(try score.saveCommand())
    }
    
    func testUpdateCommandNoObjectIdCreateWithCustomId() throws {
        var score = GameScore(score: 10)
        score.createdAt = Date()
        _ = try score.saveCommand(createWithCustomObjectId: true)
    }
    
    func testUpdateCommandNoObjectIdIgnoreConfigCreateWithCustomId() throws {
        var score = GameScore(score: 10)
        score.createdAt = Date()
        _ = try score.saveCommand(isIgnoreCustomObjectIdConfig: true, createWithCustomObjectId: true)
    }

    func testUpdateCommandNoObjectIdIgnoreConfig() throws {
        var score = GameScore(score: 10)
        score.createdAt = Date()
        _ = try score.saveCommand(isIgnoreCustomObjectIdConfig: true)
    }

    func testUpdateCommandNoObjectIdIgnoreConfig() throws {
        var score = GameScore(score: 10)
        score.createdAt = Date()
        _ = try score.saveCommand(isIgnoreCustomObjectIdConfig: true)
    }

    func testSaveAllNoObjectIdCommand() throws {
        let score = GameScore(score: 10)
        let score2 = GameScore(score: 20)
        let objects = [score, score2]
        XCTAssertThrowsError(try objects.map { try $0.saveCommand() })
    }

    func testUpdateAllNoObjectIdCommand() throws {
        var score = GameScore(score: 10)
        score.createdAt = Date()
        var score2 = GameScore(score: 20)
        score2.createdAt = Date()
        let objects = [score, score2]
        XCTAssertThrowsError(try objects.map { try $0.saveCommand() })
    }

    func testUserSaveCommandNoObjectId() throws {
        let user = User()
        XCTAssertThrowsError(try user.saveCommand())
    }

    func testUserSaveCommandNoObjectIdIgnoreConfig() throws {
        let user = User()
        _ = try user.saveCommand(isIgnoreCustomObjectIdConfig: true)
    }
    
    func testUserSaveCommandNoObjectIdCreateWithCustomId() throws {
        let user = User()
        _ = try user.saveCommand(createWithCustomObjectId: true)
    }
    
    func testUserSaveCommandNoObjectIdIgnoreConfigCreateWithCustomId() throws {
        let user = User()
        _ = try user.saveCommand(isIgnoreCustomObjectIdConfig: true, createWithCustomObjectId: true)
    }

    func testUserUpdateCommandNoObjectId() throws {
        var user = User()
        user.createdAt = Date()
        XCTAssertThrowsError(try user.saveCommand())
    }

    func testUserUpdateCommandNoObjectIdIgnoreConfig() throws {
        var user = User()
        user.createdAt = Date()
        _ = try user.saveCommand(isIgnoreCustomObjectIdConfig: true)
    }
    
    func testUserUpdateCommandNoObjectIdCreateWithCustomId() throws {
        var user = User()
        user.createdAt = Date()
        _ = try user.saveCommand(createWithCustomObjectId: true)
    }
    
    func testUserUpdateCommandNoObjectIdIgnoreConfigCreateWithCustomId() throws {
        var user = User()
        user.createdAt = Date()
        _ = try user.saveCommand(isIgnoreCustomObjectIdConfig: true, createWithCustomObjectId: true)
    }

    func testUserSaveAllNoObjectIdCommand() throws {
        let user = User()
        let user2 = User()
        let objects = [user, user2]
        XCTAssertThrowsError(try objects.map { try $0.saveCommand() })
    }

    func testUserUpdateAllNoObjectIdCommand() throws {
        var user = GameScore(score: 10)
        user.createdAt = Date()
        var user2 = GameScore(score: 20)
        user2.createdAt = Date()
        let objects = [user, user2]
        XCTAssertThrowsError(try objects.map { try $0.saveCommand() })
    }

    func testInstallationSaveCommandNoObjectId() throws {
        let installation = Installation()
        XCTAssertThrowsError(try installation.saveCommand())
    }

    func testInstallationSaveCommandNoObjectIdIgnoreConfig() throws {
        let installation = Installation()
        _ = try installation.saveCommand(isIgnoreCustomObjectIdConfig: true)
    }
    
    func testInstallationSaveCommandNoObjectIdCreateWithCustomId() throws {
        let installation = Installation()
        _ = try installation.saveCommand(createWithCustomObjectId: true)
    }
    
    func testInstallationSaveCommandNoObjectIdIgnoreConfigCreateWithCustomId() throws {
        let installation = Installation()
        _ = try installation.saveCommand(isIgnoreCustomObjectIdConfig: true, createWithCustomObjectId: true)
    }

    func testInstallationUpdateCommandNoObjectId() throws {
        var installation = Installation()
        installation.createdAt = Date()
        XCTAssertThrowsError(try installation.saveCommand())
    }

    func testInstallationUpdateCommandNoObjectIdIgnoreConfig() throws {
        var installation = Installation()
        installation.createdAt = Date()
        _ = try installation.saveCommand(isIgnoreCustomObjectIdConfig: true)
    }
    
    func testInstallationUpdateCommandNoObjectIdCreateWithCustomId() throws {
        var installation = Installation()
        installation.createdAt = Date()
        _ = try installation.saveCommand(createWithCustomObjectId: true)
    }
    
    func testInstallationUpdateCommandNoObjectIdIgnoreConfigCreateWithCustomId() throws {
        var installation = Installation()
        installation.createdAt = Date()
        _ = try installation.saveCommand(isIgnoreCustomObjectIdConfig: true, createWithCustomObjectId: true)
    }

    func testInstallationSaveAllNoObjectIdCommand() throws {
        let installation = Installation()
        let installation2 = Installation()
        let objects = [installation, installation2]
        XCTAssertThrowsError(try objects.map { try $0.saveCommand() })
    }

    func testInstallationUpdateAllNoObjectIdCommand() throws {
        var score = GameScore(score: 10)
        score.createdAt = Date()
        var score2 = GameScore(score: 20)
        score2.createdAt = Date()
        let objects = [score, score2]
        XCTAssertThrowsError(try objects.map { try $0.saveCommand() })
    }

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

    func testSaveNoObjectIdIgnoreConfig() { // swiftlint:disable:this function_body_length
        let score = GameScore(score: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
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
            let saved = try score.save(isIgnoreCustomObjectIdConfig: true)
            XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testSaveNoObjectIdCreateWithCustomId() { // swiftlint:disable:this function_body_length
        let score = GameScore(score: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
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
            let saved = try score.save(createWithCustomObjectId: true)
            //objectId should be generated by server and new object created
            XCTAssert(!saved.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testSaveNoObjectIdIgnoreConfigCreateWithCustomId() { // swiftlint:disable:this function_body_length
        let score = GameScore(score: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
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
            let saved = try score.save(isIgnoreCustomObjectIdConfig: true, createWithCustomObjectId: true)
            //objectId should be generated by server and new object created
            XCTAssert(!saved.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
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

    func testUpdateNoObjectIdIgnoreConfig() {
        var score = GameScore(score: 10)
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
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
            let saved = try score.save(isIgnoreCustomObjectIdConfig: true)
            XCTAssertTrue(saved.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testUpdateNoObjectIdCreateWithCustomId() {
        var score = GameScore(score: 10)
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
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
            let saved = try score.save(createWithCustomObjectId: true)
            //objectId should be generated by server and new object created
            XCTAssertTrue(!saved.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testUpdateNoObjectIdIgnoreConfigCreateWithCustomId() {
        var score = GameScore(score: 10)
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
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
            let saved = try score.save(isIgnoreCustomObjectIdConfig: true, createWithCustomObjectId: true)
            //objectId should be generated by server and new object created
            XCTAssertTrue(!saved.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length
    func saveAsync(score: GameScore,
                   scoreOnServer: GameScore,
                   callbackQueue: DispatchQueue,
                   isIgnoreCustomObjectIdConfig: Bool = false) {

        let expectation1 = XCTestExpectation(description: "Save object1")

        score.save(isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig,
                   options: [],
                   callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Save object2")
        score.save(isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig,
                   options: [.useMasterKey],
                   callbackQueue: callbackQueue) { result in

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

    func testSaveNoObjectIdAsyncMainQueue() throws {
        let score = GameScore(score: 10)
        XCTAssertThrowsError(try score.save())

        let expectation1 = XCTestExpectation(description: "Save object2")
        score.save { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveNoObjectIdIgnoreConfigAsyncMainQueue() {
        let score = GameScore(score: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
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

        self.saveAsync(score: score,
                       scoreOnServer: scoreOnServer,
                       callbackQueue: .main,
                       isIgnoreCustomObjectIdConfig: true)
    }
    
    func testSaveNoObjectIdCreateWithCustomIdAsyncMainQueue() {
        let score = GameScore(score: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
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

        self.saveAsync(score: score,
                       scoreOnServer: scoreOnServer,
                       callbackQueue: .main,
                       createWithCustomObjectId: true)
    }
    
    func testSaveNoObjectIdIgnoreConfigCreateWithCustomIdAsyncMainQueue() {
        let score = GameScore(score: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
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

        self.saveAsync(score: score,
                       scoreOnServer: scoreOnServer,
                       callbackQueue: .main,
                       isIgnoreCustomObjectIdConfig: true,
                       createWithCustomObjectId: true)
    }

    func updateAsync(score: GameScore,
                     scoreOnServer: GameScore,
                     isIgnoreCustomObjectIdConfig: Bool = false,
                     callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        score.save(isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig,
                   options: [],
                   callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertNil(saved.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Update object2")
        score.save(isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig,
                   options: [.useMasterKey],
                   callbackQueue: callbackQueue) { result in

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

    func testUpdateNoObjectIdAsyncMainQueue() throws {
        var score = GameScore(score: 10)
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        XCTAssertThrowsError(try score.save())

        let expectation1 = XCTestExpectation(description: "Save object2")
        score.save { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUpdateNoObjectIdIgnoreConfigAsyncMainQueue() {
        var score = GameScore(score: 10)
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
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
        self.updateAsync(score: score,
                         scoreOnServer: scoreOnServer,
                         isIgnoreCustomObjectIdConfig: true,
                         callbackQueue: .main)
    }
    
    func testUpdateNoObjectIdCreateWithCustomIdAsyncMainQueue() {
        var score = GameScore(score: 10)
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
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
        self.updateAsync(score: score,
                         scoreOnServer: scoreOnServer,
                         createWithCustomObjectId: true,
                         callbackQueue: .main)
    }
    
    func testUpdateNoObjectIdIgnoreConfigCreateWithCustomIdAsyncMainQueue() {
        var score = GameScore(score: 10)
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
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
        self.updateAsync(score: score,
                         scoreOnServer: scoreOnServer,
                         isIgnoreCustomObjectIdConfig: true,
                         createWithCustomObjectId: true,
                         callbackQueue: .main)
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
    
    func testSaveAllCreateWithCustomId() { // swiftlint:disable:this function_body_length cyclomatic_complexity
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

            let saved = try [score, score2].saveAll(createWithCustomObjectId: true)

            XCTAssertEqual(saved.count, 0)
            switch saved[0] {

            case .success(let first):
                XCTFail("Duplicate error should be thrown")
            case .failure(let error):
                XCTAssert(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTFail("Duplicate error should be thrown")
            case .failure(let error):
                XCTAssert(error.localizedDescription)
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

    func testSaveAllNoObjectIdIgnoreConfig() { // swiftlint:disable:this function_body_length cyclomatic_complexity
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

            let saved = try [score, score2].saveAll(isIgnoreCustomObjectIdConfig: true)

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
    
    func testSaveAllNoObjectIdCreateWithCustomId() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        let score = GameScore(score: 10)
        let score2 = GameScore(score: 20)

        do {

            let saved = try [score, score2].saveAll(createWithCustomObjectId: true)

            XCTAssertEqual(saved.count, 0)
            switch saved[0] {

            case .success(let first):
                XCTFail("ObjectId should not be nil before save")
            case .failure(let error):
                XCTAssert(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTFail("ObjectId should not be nil before save")
            case .failure(let error):
                XCTAssert(error.localizedDescription)
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

    func testSaveAllNoObjectIdIgnoreConfig() { // swiftlint:disable:this function_body_length cyclomatic_complexity
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

            let saved = try [score, score2].saveAll(isIgnoreCustomObjectIdConfig: true)

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

    func testSaveAllNoObjectIdAsync() throws {
        let score = GameScore(score: 10)
        let score2 = GameScore(score: 20)

        let expectation1 = XCTestExpectation(description: "Save object2")
        [score, score2].saveAll { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
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

    func testUpdateAllNoObjectIdAsync() throws {
        var score = GameScore(score: 10)
        score.createdAt = Date()
        var score2 = GameScore(score: 20)
        score2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        let expectation1 = XCTestExpectation(description: "Save object2")
        [score, score2].saveAll { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
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

    func testUserSaveNoObjectIdIgnoreConfig() { // swiftlint:disable:this function_body_length
        var user = User()
        user.ACL = nil

        var userOnServer = user
        userOnServer.objectId = "yarr"
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
            let saved = try user.save(isIgnoreCustomObjectIdConfig: true)
            XCTAssert(saved.hasSameObjectId(as: userOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
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
    
    func testUserUpdateNoObjectIdCreateWithCustomId() throws {
        var user = User()
        user.createdAt = Date()
        XCTAssertThrowsError(try user.save(createWithCustomObjectId: true))
    }

    func testUserUpdateNoObjectIdIgnoreConfig() {
        var user = User()
        user.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.objectId = "yarr"
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
            let saved = try user.save(isIgnoreCustomObjectIdConfig: true)
            XCTAssertTrue(saved.hasSameObjectId(as: userOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUserUpdateNoObjectIdIgnoreConfig() {
        var user = User()
        user.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.objectId = "yarr"
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
            let saved = try user.save(isIgnoreCustomObjectIdConfig: true)
            XCTAssertTrue(saved.hasSameObjectId(as: userOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length
    func saveUserAsync(user: User, userOnServer: User,
                       isIgnoreCustomObjectIdConfig: Bool = false,
                       callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        user.save(isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig,
                  options: [],
                  callbackQueue: callbackQueue) { result in

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

    func testUserSaveNoObjectIdAsyncMainQueue() throws {
        let user = User()
        XCTAssertThrowsError(try user.save())

        let expectation1 = XCTestExpectation(description: "Save object2")
        user.save { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUserSaveNoObjectIdIgnoreConfigAsyncMainQueue() {
        var user = User()
        user.ACL = nil

        var userOnServer = user
        userOnServer.objectId = "yarr"
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
        self.saveUserAsync(user: user,
                           userOnServer: userOnServer,
                           isIgnoreCustomObjectIdConfig: true,
                           callbackQueue: .main)
    }
    
    func testUserSaveNoObjectIdCreateWithCustomIdAsyncMainQueue() {
        var user = User()
        user.ACL = nil

        var userOnServer = user
        userOnServer.objectId = "yarr"
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
        XCTAssertThrowsError(self.saveUserAsync(user: user,
                                                userOnServer: userOnServer,
                                                createWithCustomObjectId: true,
                                                callbackQueue: .main))
    }

    func updateUserAsync(user: User, userOnServer: User,
                         isIgnoreCustomObjectIdConfig: Bool = false,
                         callbackQueue: DispatchQueue) {

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

    func testUserUpdateNoObjectIdAsyncMainQueue() throws {
        var user = User()
        user.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        XCTAssertThrowsError(try user.save())

        let expectation1 = XCTestExpectation(description: "Save object2")
        user.save { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
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

    func testUserSaveAllNoObjectIdAsync() throws {
        let user = User()
        let user2 = User()

        let expectation1 = XCTestExpectation(description: "SaveAll user")
        [user, user2].saveAll { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
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

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func testUserUpdateAllNoObjectIdIgnoreConfig() {
        var user = User()
        user.createdAt = Date()
        var user2 = User()
        user2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        var userOnServer = user
        userOnServer.objectId = "yarr"
        userOnServer.updatedAt = userOnServer.createdAt
        userOnServer.ACL = nil

        var userOnServer2 = user2
        userOnServer2.objectId = "yolo"
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

            let saved = try [user, user2].saveAll(isIgnoreCustomObjectIdConfig: true)

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
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func testUserUpdateAllNoObjectIdCreateWithCustomId() {
        var user = User()
        user.createdAt = Date()
        var user2 = User()
        user2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        do {

            let saved = try [user, user2].saveAll(createWithCustomObjectId: true)

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTFail("ObjectId should not be nil before save")
            case .failure(let error):
                XCTAssert(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTFail("ObjectId should not be nil before save")
            case .failure(let error):
                XCTAssert(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUserUpdateAllNoObjectIdAsync() throws {
        var user = User()
        user.createdAt = Date()
        var user2 = User()
        user2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        let expectation1 = XCTestExpectation(description: "UpdateAll user")
        [user, user2].saveAll { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
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
    
    func testInstallationSaveNoObjectIdCreateWithCustomId() throws {
        let score = GameScore(score: 10)
        XCTAssertThrowsError(try score.save(createWithCustomObjectId: true))
    }

    func testInstallationSaveNoObjectIdIgnoreConfig() { // swiftlint:disable:this function_body_length
        var installation = Installation()
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.objectId = "yarr"
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
            let saved = try installation.save(isIgnoreCustomObjectIdConfig: true)
            XCTAssert(saved.hasSameObjectId(as: installationOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testInstallationSaveNoObjectIdIgnoreConfig() { // swiftlint:disable:this function_body_length
        var installation = Installation()
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.objectId = "yarr"
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
            let saved = try installation.save(isIgnoreCustomObjectIdConfig: true)
            XCTAssert(saved.hasSameObjectId(as: installationOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
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

    func testInstallationUpdateNoObjectIdIgnoreConfig() {
        var installation = Installation()
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.objectId = "yarr"
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
            let saved = try installation.save(isIgnoreCustomObjectIdConfig: true)
            XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testInstallationUpdateNoObjectIdCreateWithCustomId() {
        var installation = Installation()
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        do {
            XCTAssertThrowsError(try installation.save(createWithCustomObjectId: true))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length
    func saveInstallationAsync(installation: Installation,
                               installationOnServer: Installation,
                               isIgnoreCustomObjectIdConfig: Bool = false,
                               callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        installation.save(isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig,
                          options: [],
                          callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Update object2")
        installation.save(isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig,
                          options: [.useMasterKey],
                          callbackQueue: callbackQueue) { result in

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
                                   isIgnoreCustomObjectIdConfig: false,
                                   callbackQueue: .main)
    }

    func testInstallationSaveNoObjectIdAsyncMainQueue() throws {
        let installation = Installation()
        XCTAssertThrowsError(try installation.save())

        let expectation1 = XCTestExpectation(description: "Save object2")
        installation.save { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testInstallationSaveNoObjectIdIgnoreConfigAsyncMainQueue() {
        var installation = Installation()
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.objectId = "yarr"
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
                                   isIgnoreCustomObjectIdConfig: true,
                                   callbackQueue: .main)
    }

    func updateInstallationAsync(installation: Installation,
                                 installationOnServer: Installation,
                                 isIgnoreCustomObjectIdConfig: Bool = false,
                                 callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        installation.save(isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig,
                          options: [],
                          callbackQueue: callbackQueue) { result in

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

    func testInstallationUpdateNoObjectIdAsyncMainQueue() throws {
        var installation = Installation()
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        XCTAssertThrowsError(try installation.save())

        let expectation1 = XCTestExpectation(description: "Save object2")
        installation.save { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testInstallationUpdateNoObjectIdIgnoreConfigAsyncMainQueue() {
        var installation = Installation()
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.objectId = "yarr"
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
                                     isIgnoreCustomObjectIdConfig: true,
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
    
    func testInstallationSaveAllCreateWithCustomId() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        var installation = Installation()
        installation.objectId = "yarr"

        var installation2 = Installation()
        installation2.objectId = "yolo"
        
        do {

            let saved = try [installation, installation2].saveAll(createWithCustomObjectId: true)

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: installation))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: installation2))
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

    func testInstallationSaveAllIgnoreConfig() { // swiftlint:disable:this function_body_length cyclomatic_complexity
        let installation = Installation()

        let installation2 = Installation()

        var installationOnServer = installation
        installationOnServer.objectId = "yarr"
        installationOnServer.createdAt = Date()
        installationOnServer.updatedAt = installationOnServer.createdAt
        installationOnServer.ACL = nil

        var installationOnServer2 = installation2
        installationOnServer2.objectId = "yolo"
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

            let saved = try [installation, installation2].saveAll(isIgnoreCustomObjectIdConfig: true)

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

    func testInstallationSaveAllNoObjectIdAsync() throws {
        let installation = Installation()
        let installation2 = Installation()

        let expectation1 = XCTestExpectation(description: "SaveAll installation")
        [installation, installation2].saveAll { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
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
    
    func testInstallationUpdateAllCreateWithCustomId() { // swiftlint:disable:this function_body_length cyclomatic_complexity
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

            let saved = try [installation, installation2].saveAll(createWithCustomObjectId: true)

            XCTAssertEqual(saved.count, 0)
            switch saved[0] {

            case .success(let first):
                XCTFail("Duplicate error should be thrown")
            case .failure(let error):
                XCTAssert(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTFail("Duplicate error should be thrown")
            case .failure(let error):
                XCTAssert(error.localizedDescription)
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

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func testInstallationUpdateAllNoObjectIdIgnoreConfig() {
        var installation = Installation()
        installation.createdAt = Date()
        var installation2 = Installation()
        installation2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        var installationOnServer = installation
        installationOnServer.objectId = "yarr"
        installationOnServer.updatedAt = installationOnServer.createdAt
        installationOnServer.ACL = nil

        var installationOnServer2 = installation2
        installationOnServer2.objectId = "yolo"
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

            let saved = try [installation, installation2].saveAll(isIgnoreCustomObjectIdConfig: true)

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

    func testInstallationUpdateAllNoObjectIdAsync() throws {
        var installation = Installation()
        installation.createdAt = Date()
        var installation2 = Installation()
        installation2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        let expectation1 = XCTestExpectation(description: "UpdateAll installation")
        [installation, installation2].saveAll { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    // swiftlint:disable:next function_body_length
    func testFetch() {
        var score = GameScore(score: 10)
        let objectId = "yarr"
        score.objectId = objectId

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
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        do {
            let fetched = try score.fetch(options: [])
            XCTAssert(fetched.hasSameObjectId(as: scoreOnServer))
            guard let fetchedCreatedAt = fetched.createdAt,
                let fetchedUpdatedAt = fetched.updatedAt else {
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
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetchUser() { // swiftlint:disable:this function_body_length
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        var userOnServer = user
        userOnServer.createdAt = Date()
        userOnServer.updatedAt = userOnServer.createdAt
        userOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
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
            let fetched = try user.fetch()
            XCTAssert(fetched.hasSameObjectId(as: userOnServer))
            guard let fetchedCreatedAt = fetched.createdAt,
                let fetchedUpdatedAt = fetched.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = userOnServer.createdAt,
                let originalUpdatedAt = userOnServer.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
