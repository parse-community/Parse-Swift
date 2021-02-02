//
//  ParseObjectCommandTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/19/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseObjectTests: XCTestCase { // swiftlint:disable:this type_body_length
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

    struct Game2: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var name = "Hello"
        var profilePicture: ParseFile?
    }

    class GameScoreClass: ParseObject {

        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: Int
        var player = "Jen"
        var level: Level?
        var levels: [Level]?
        var game: GameClass?

        //: a custom initializer
        init(score: Int) {
            self.score = score
        }

        /**
         Conforms to Equatable by determining if an object has the same objectId.
         - note: You can specify a custom way of `Equatable` if a more  detailed way is needed.
         - warning: If you use the default implementation, equatable will only work if the ParseObject
         has been previously synced to the parse-server (has an objectId). In addition, if two
         `ParseObject`'s have the same objectId, but were modified at different times, the
         default implementation will still return true. In these cases you either want to use a
         "struct" (value types) to make your `ParseObject`s instead of a class (reference type) or
         provide your own implementation of `==`.
         - parameter lhs: first object to compare
         - parameter rhs: second object to compare

         - returns: Returns a `true` if the other object has the same `objectId` or `false` if unsuccessful.
        */
        public static func == (lhs: ParseObjectTests.GameScoreClass,
                               rhs: ParseObjectTests.GameScoreClass) -> Bool {
            lhs.hasSameObjectId(as: rhs)
        }

        /**
         Conforms to `Hashable` using objectId.
         - note: You can specify a custom way of `Hashable` if a more  detailed way is needed.
         - warning: If you use the default implementation, hash will only work if the ParseObject has been previously
         synced to the parse-server (has an objectId). In addition, if two `ParseObject`'s have the same objectId,
         but were modified at different times, the default implementation will hash to the same value. In these
         cases you either want to use a "struct" (value types) to make your `ParseObject`s instead of a
         class (reference type) or provide your own implementation of `hash`.

        */
        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.objectId)
        }
    }

    class GameClass: ParseObject {

        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: GameScoreClass
        var scores = [GameScore]()
        var name = "Hello"

        //: a custom initializer
        init(score: GameScoreClass) {
            self.score = score
        }

        /**
         Conforms to Equatable by determining if an object has the same objectId.
         - note: You can specify a custom way of `Equatable` if a more  detailed way is needed.
         - warning: If you use the default implementation, equatable will only work if the ParseObject
         has been previously synced to the parse-server (has an objectId). In addition, if two
         `ParseObject`'s have the same objectId, but were modified at different times, the
         default implementation will still return true. In these cases you either want to use a
         "struct" (value types) to make your `ParseObject`s instead of a class (reference type) or
         provide your own implementation of `==`.
         - parameter lhs: first object to compare
         - parameter rhs: second object to compare

         - returns: Returns a `true` if the other object has the same `objectId` or `false` if unsuccessful.
        */
        public static func == (lhs: ParseObjectTests.GameClass, rhs: ParseObjectTests.GameClass) -> Bool {
            lhs.hasSameObjectId(as: rhs)
        }

        /**
         Conforms to `Hashable` using objectId.
         - note: You can specify a custom way of `Hashable` if a more  detailed way is needed.
         - warning: If you use the default implementation, hash will only work if the ParseObject has been previously
         synced to the parse-server (has an objectId). In addition, if two `ParseObject`'s have the same objectId,
         but were modified at different times, the default implementation will hash to the same value. In these
         cases you either want to use a "struct" (value types) to make your `ParseObject`s instead of a
         class (reference type) or provide your own implementation of `hash`.

        */
        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.objectId)
        }
    }

    override func setUp() {
        super.setUp()
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
        super.tearDown()
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

    func testFetchCommand() {
        var score = GameScore(score: 10)
        let className = score.className
        let objectId = "yarr"
        score.objectId = objectId
        do {
            let command = try score.fetchCommand(include: nil)
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
            XCTAssertNil(command.data)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetchIncludeCommand() {
        var score = GameScore(score: 10)
        let className = score.className
        let objectId = "yarr"
        score.objectId = objectId
        let includeExpected = ["include": "yolo,test"]
        do {
            let command = try score.fetchCommand(include: ["yolo", "test"])
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertEqual(command.params, includeExpected)
            XCTAssertNil(command.body)
            XCTAssertNil(command.data)

            // swiftlint:disable:next line_length
            guard let urlExpected = URL(string: "http://localhost:1337/1/classes/GameScore/yarr?include=yolo,test") else {
                XCTFail("Should have unwrapped")
                return
            }
            let request = command.prepareURLRequest(options: [])
            switch request {
            case .success(let url):
                XCTAssertEqual(url.url, urlExpected)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
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

        do {
            let fetched = try score.fetch(options: [.useMasterKey])
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

    func testFetchBasedOnObjectId() {
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
            var fetched = GameScore(objectId: score.objectId)
            fetched = try fetched.fetch(options: [])
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
            XCTAssertEqual(fetched.score, score.score)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length
    func fetchAsync(score: GameScore, scoreOnServer: GameScore, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Fetch object1")
        score.fetch(options: [], callbackQueue: callbackQueue) { result in

            switch result {
            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: scoreOnServer))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
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
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(fetched.ACL)
                XCTAssertEqual(fetched.score, scoreOnServer.score)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Fetch object2")
        score.fetch(options: [.useMasterKey], callbackQueue: callbackQueue) { result in

            switch result {
            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: scoreOnServer))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                guard let originalCreatedAt = scoreOnServer.createdAt,
                    let originalUpdatedAt = scoreOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(fetched.ACL)
                XCTAssertEqual(fetched.score, scoreOnServer.score)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testThreadSafeFetchAsync() {
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
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            self.fetchAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }

    func testFetchAsyncMainQueue() {
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
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        self.fetchAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testSaveCommand() throws {
        let score = GameScore(score: 10)
        let className = score.className

        let command = score.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.data)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"score\":10,\"player\":\"Jen\"}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
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

        let expected = "{\"score\":10,\"player\":\"Jen\"}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testSave() { // swiftlint:disable:this function_body_length
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
            let saved = try score.save()
            XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
            guard let savedCreatedAt = saved.createdAt,
                let savedUpdatedAt = saved.updatedAt else {
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
            XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try score.save(options: [.useMasterKey])
            XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
            guard let savedCreatedAt = saved.createdAt,
                let savedUpdatedAt = saved.updatedAt else {
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
            XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
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
            guard let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            guard let originalUpdatedAt = score.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try score.save(options: [.useMasterKey])
            guard let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            guard let originalUpdatedAt = score.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length
    func saveAsync(score: GameScore, scoreOnServer: GameScore, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Save object1")

        score.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
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
                XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
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
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                guard let originalCreatedAt = scoreOnServer.createdAt,
                    let originalUpdatedAt = scoreOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testThreadSafeSaveAsync() {
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
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            self.saveAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }

    func testSaveAsyncMainQueue() {
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
                guard let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation2.fulfill()
                    return
                }
                guard let originalUpdatedAt = score.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation2.fulfill()
                    return
                }
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testThreadSafeUpdateAsync() {
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

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            self.updateAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
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

    func testDeleteCommand() {
        var score = GameScore(score: 10)
        let className = score.className
        let objectId = "yarr"
        score.objectId = objectId
        do {
            let command = try score.deleteCommand()
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
            XCTAssertEqual(command.method, API.Method.DELETE)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDelete() {
        var score = GameScore(score: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder().encode(scoreOnServer, skipKeys: .none)
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
            try score.delete(options: [])
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            try score.delete(options: [.useMasterKey])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDeleteError() {
        var score = GameScore(score: 10)
        let objectId = "yarr"
        score.objectId = objectId

        let parseError = ParseError(code: .objectNotFound, message: "Object not found")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(parseError)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        do {
            try score.delete(options: [])
            XCTFail("Should have thrown ParseError")
        } catch {
            if let error = error as? ParseError {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
        }

        do {
            try score.delete(options: [.useMasterKey])
            XCTFail("Should have thrown ParseError")
        } catch {
            if let error = error as? ParseError {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
        }
    }

    func deleteAsync(score: GameScore, scoreOnServer: GameScore, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Delete object1")
        score.delete(options: [], callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Delete object2")
        score.delete(options: [.useMasterKey], callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testThreadSafeDeleteAsync() {
        var score = GameScore(score: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder().encode(scoreOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            self.deleteAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }

    func testDeleteAsyncMainQueue() {
        var score = GameScore(score: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder().encode(scoreOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        self.deleteAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func deleteAsyncError(score: GameScore, parseError: ParseError, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Delete object1")
        score.delete(options: [], callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Delete object2")
        score.delete(options: [.useMasterKey], callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testDeleteAsyncMainQueueError() {
        var score = GameScore(score: 10)
        let objectId = "yarr"
        score.objectId = objectId

        let parseError = ParseError(code: .objectNotFound, message: "Object not found")
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(parseError)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        self.deleteAsyncError(score: score, parseError: parseError, callbackQueue: .main)
    }

    // swiftlint:disable:next function_body_length
    func testDeepSaveOneDeep() throws {
        let score = GameScore(score: 10)
        var game = Game(score: score)

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        scoreOnServer.objectId = "yarr"
        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder().encode(scoreOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        game.ensureDeepSave { (savedChildren, savedChildFiles, parseError) in

            XCTAssertEqual(savedChildren.count, 1)
            XCTAssertEqual(savedChildFiles.count, 0)
            var counter = 0
            var savedChildObject: PointerType?
            savedChildren.forEach { (_, value) in
                XCTAssertEqual(value.className, "GameScore")
                XCTAssertEqual(value.objectId, "yarr")
                if counter == 0 {
                    savedChildObject = value
                }
                counter += 1
            }
            XCTAssertNil(parseError)

            guard let savedChild = savedChildObject else {
                XCTFail("Should have unwrapped child object")
                return
            }

            //Saved updated info for game
            let encodedScore: Data
            do {
                encodedScore = try ParseCoding.jsonEncoder().encode(savedChild)
                //Decode Pointer as GameScore
                game.score = try game.getDecoder().decode(GameScore.self, from: encodedScore)
            } catch {
                XCTFail("Should encode/decode. Error \(error)")
                return
            }

            //Setup ParseObject to return from mocker
            MockURLProtocol.removeAll()

            var gameOnServer = game
            gameOnServer.objectId = "nice"
            gameOnServer.createdAt = Date()
            gameOnServer.updatedAt = gameOnServer.createdAt

            let encodedGamed: Data
            do {
                encodedGamed = try game.getEncoder().encode(gameOnServer, skipKeys: .none)
                //Get dates in correct format from ParseDecoding strategy
                gameOnServer = try game.getDecoder().decode(Game.self, from: encodedGamed)
            } catch {
                XCTFail("Should encode/decode. Error \(error)")
                return
            }

            MockURLProtocol.mockRequests { _ in
                return MockURLResponse(data: encodedGamed, statusCode: 200, delay: 0.0)
            }

            guard let savedGame = try? game
                    .saveCommand()
                    .execute(options: [],
                             callbackQueue: .main,
                             childObjects: savedChildren,
                             childFiles: savedChildFiles) else {
                XCTFail("Should have saved game")
                return
            }
            XCTAssertEqual(savedGame.objectId, gameOnServer.objectId)
            XCTAssertEqual(savedGame.createdAt, gameOnServer.createdAt)
            XCTAssertEqual(savedGame.updatedAt, gameOnServer.updatedAt)
            XCTAssertEqual(savedGame.score, gameOnServer.score)

        }
    }

    func testDeepSaveDetectCircular() throws {
        let score = GameScoreClass(score: 10)
        let game = GameClass(score: score)
        game.objectId = "nice"
        score.game = game

        game.ensureDeepSave { (_, _, parseError) in

            guard let error = parseError else {
                XCTFail("Should have failed with an error of detecting a circular dependency")
                return
            }
            XCTAssertTrue(error.message.contains("circular"))
        }
    }

    func testDeepSaveTwoDeep() throws {
        var score = GameScore(score: 10)
        score.level = Level()
        var game = Game(score: score)
        game.objectId = "nice"

        var levelOnServer = score
        levelOnServer.createdAt = Date()
        levelOnServer.updatedAt = levelOnServer.updatedAt
        levelOnServer.ACL = nil
        levelOnServer.objectId = "yarr"
        let pointer = try levelOnServer.toPointer()
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(pointer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        game.ensureDeepSave { (savedChildren, savedChildFiles, parseError) in

            XCTAssertEqual(savedChildFiles.count, 0)
            XCTAssertEqual(savedChildren.count, 2)
            let gameScore = savedChildren.compactMap { (_, value) -> PointerType? in
                if value.className == "GameScore" {
                    return value
                } else {
                    return nil
                }
            }
            XCTAssertEqual(gameScore.count, 1)
            XCTAssertEqual(gameScore.first?.className, "GameScore")
            XCTAssertEqual(gameScore.first?.objectId, "yarr")

            let level = savedChildren.compactMap { (_, value) -> PointerType? in
                if value.className == "Level" {
                    return value
                } else {
                    return nil
                }
            }
            XCTAssertEqual(level.count, 1)
            XCTAssertEqual(level.first?.className, "Level")
            XCTAssertEqual(level.first?.objectId, "yarr") //This is because mocker is only returning 1 response
            XCTAssertNil(parseError)
        }
    }

    func testDeepSaveOfUnsavedPointerArrayFails() throws {
        var score = GameScore(score: 10)
        var newLevel = Level()
        newLevel.objectId = "sameId"
        score.levels = [newLevel, newLevel]

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        scoreOnServer.objectId = "yarr"
        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder().encode(scoreOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
            XCTFail("Should have thrown encode/decode error because child objects can't have the same objectId")
        } catch {
            XCTAssertNotEqual(error.localizedDescription, "")
            return
        }
    }

    func testDeepSavePointerArray() throws {
        var score = GameScore(score: 10)
        var level1 = Level()
        level1.objectId = "level1"
        var level2 = Level()
        level2.objectId = "level2"
        score.levels = [level1, level2]

        do {
            let encoded = try score.getEncoder().encode(score, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            guard let scoreOnServer = try (score.getDecoder()
                                            .decode([String: AnyCodable].self,
                                                    from: encoded))["levels"]?.value as? [[String: String]],
                  let first = scoreOnServer.first,
                  let second = scoreOnServer.last else {
                XCTFail("Should unwrapped decoded")
                return
            }
            XCTAssertEqual(first["__type"], "Pointer")
            XCTAssertEqual(first["objectId"], level1.objectId)
            XCTAssertEqual(first["className"], level1.className)
            XCTAssertEqual(second["__type"], "Pointer")
            XCTAssertEqual(second["objectId"], level2.objectId)
            XCTAssertEqual(second["className"], level2.className)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
    }

    // swiftlint:disable:next function_body_length
    func testDeepSaveObjectWithFile() throws {
        var game = Game2()

        guard let cloudPath = URL(string: "https://parseplatform.org/img/logo.svg"),
              // swiftlint:disable:next line_length
              let parseURL = URL(string: "http://localhost:1337/1/files/applicationId/89d74fcfa4faa5561799e5076593f67c_logo.svg") else {
            XCTFail("Should create URL")
            return
        }

        let parseFile = ParseFile(name: "profile.svg", cloudURL: cloudPath)
        game.profilePicture = parseFile

        let response = FileUploadResponse(name: "89d74fcfa4faa5561799e5076593f67c_\(parseFile.name)", url: parseURL)

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        game.ensureDeepSave { (savedChildren, savedChildFiles, parseError) in

            XCTAssertEqual(savedChildren.count, 0)
            XCTAssertEqual(savedChildFiles.count, 1)
            var counter = 0
            var savedFile: ParseFile?
            savedChildFiles.forEach { (_, value) in
                XCTAssertEqual(value.url, response.url)
                XCTAssertEqual(value.name, response.name)
                if counter == 0 {
                    savedFile = value
                }
                counter += 1
            }
            XCTAssertNil(parseError)

            //Saved updated info for game
            game.profilePicture = savedFile

            //Setup ParseObject to return from mocker
            MockURLProtocol.removeAll()

            var gameOnServer = game
            gameOnServer.objectId = "nice"
            gameOnServer.createdAt = Date()
            gameOnServer.updatedAt = gameOnServer.updatedAt
            gameOnServer.profilePicture = savedFile

            let encodedGamed: Data
            do {
                encodedGamed = try game.getEncoder().encode(gameOnServer, skipKeys: .none)
                //Get dates in correct format from ParseDecoding strategy
                gameOnServer = try game.getDecoder().decode(Game2.self, from: encodedGamed)
            } catch {
                XCTFail("Should encode/decode. Error \(error)")
                return
            }

            MockURLProtocol.mockRequests { _ in
                return MockURLResponse(data: encodedGamed, statusCode: 200, delay: 0.0)
            }

            guard let savedGame = try? game
                    .saveCommand()
                    .execute(options: [],
                             callbackQueue: .main,
                             childObjects: savedChildren,
                             childFiles: savedChildFiles) else {
                XCTFail("Should have saved game")
                return
            }
            XCTAssertEqual(savedGame.objectId, gameOnServer.objectId)
            XCTAssertEqual(savedGame.createdAt, gameOnServer.createdAt)
            XCTAssertEqual(savedGame.updatedAt, gameOnServer.updatedAt)
            XCTAssertEqual(savedGame.profilePicture, gameOnServer.profilePicture)
        }
    }
}

// swiftlint:disable:this file_length
