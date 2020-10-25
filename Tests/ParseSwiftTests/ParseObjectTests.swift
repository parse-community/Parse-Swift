//
//  ParseObjectCommandTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/19/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//
#if canImport(XCTest)
import Foundation
import XCTest
@testable import ParseSwift

class ParseObjectTests: XCTestCase { // swiftlint:disable:this type_body_length
    struct Level: ParseObject {
        var objectId: String?

        var createdAt: Date?

        var updatedAt: Date?

        var ACL: ACL?

        var name = "First"

        init() {
        }
    }

    struct GameScore: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ACL?

        //: Your own properties
        var score: Int
        var player = "Jen"
        var level: Level?
        var levels: [Level]?

        //: a custom initializer
        init(score: Int) {
            self.score = score
        }
    }

    struct Game: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ACL?

        //: Your own properties
        var score: GameScore
        var scores = [GameScore]()
        var name = "Hello"

        //: a custom initializer
        init(score: GameScore) {
            self.score = score
        }
    }

    class GameScoreClass: ParseObject {

        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ACL?

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
         "struct" (value types) to make your `ParseObjects` instead of a class (reference type) or
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
         cases you either want to use a "struct" (value types) to make your `ParseObjects` instead of a
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
        var ACL: ACL?

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
         "struct" (value types) to make your `ParseObjects` instead of a class (reference type) or
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
         cases you either want to use a "struct" (value types) to make your `ParseObjects` instead of a
         class (reference type) or provide your own implementation of `hash`.

        */
        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.objectId)
        }
    }

    override func setUp() {
        super.setUp()
        guard let url = URL(string: "https://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url)
    }

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.removeAll()
        try? KeychainStore.shared.deleteAll()
        try? ParseStorage.shared.deleteAll()
    }

    func testFetchCommand() {
        var score = GameScore(score: 10)
        let className = score.className
        let objectId = "yarr"
        score.objectId = objectId
        do {
            let command = try score.fetchCommand()
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

    // swiftlint:disable:next function_body_length
    func testFetch() {
        var score = GameScore(score: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
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
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 10.0)
    }

    func testThreadSafeFetchAsync() {
        var score = GameScore(score: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
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
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
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

    func testSaveCommand() {
        let score = GameScore(score: 10)
        let className = score.className

        let command = score.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertNotNil(command.data)
    }

    func testUpdateCommand() {
        var score = GameScore(score: 10)
        let className = score.className
        let objectId = "yarr"
        score.objectId = objectId

        let command = score.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertNotNil(command.data)
    }

    func testSave() { // swiftlint:disable:this function_body_length
        let score = GameScore(score: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
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
            XCTAssertNil(saved.ACL)
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
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdate() { // swiftlint:disable:this function_body_length
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
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
            guard let savedCreatedAt = saved.createdAt,
                let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = score.createdAt,
                let originalUpdatedAt = score.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, originalCreatedAt)
            XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try score.save(options: [.useMasterKey])
            guard let savedCreatedAt = saved.createdAt,
                let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = score.createdAt,
                let originalUpdatedAt = score.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, originalCreatedAt)
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
                XCTAssertNil(saved.ACL)
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
                XCTAssertNil(saved.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 10.0)
    }

    func testThreadSafeSaveAsync() {
        let score = GameScore(score: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
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
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
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

    // swiftlint:disable:next function_body_length
    func updateAsync(score: GameScore, scoreOnServer: GameScore, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        score.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                guard let originalCreatedAt = score.createdAt,
                    let originalUpdatedAt = score.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
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
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                guard let originalCreatedAt = score.createdAt,
                    let originalUpdatedAt = score.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 10.0)
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
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
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
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
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
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
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

    func deleteAsync(score: GameScore, scoreOnServer: GameScore, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Fetch object1")
        score.delete(options: [], callbackQueue: callbackQueue) { error in

            guard let error = error else {
                expectation1.fulfill()
                return
            }
            XCTFail(error.localizedDescription)
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Fetch object2")
        score.delete(options: [.useMasterKey], callbackQueue: callbackQueue) { error in

            guard let error = error else {
                expectation2.fulfill()
                return
            }
            XCTFail(error.localizedDescription)
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 10.0)
    }

    func testThreadSafeDeleteAsync() {
        var score = GameScore(score: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
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
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
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

    func testDeepSaveOneDeep() throws {
        let score = GameScore(score: 10)
        var game = Game(score: score)
        game.objectId = "nice"

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil
        scoreOnServer.objectId = "yarr"
        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
            //Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        game.ensureDeepSave { results in
            switch results {

            case .success(let savedChildren):
                XCTAssertEqual(savedChildren.count, 1)
                savedChildren.forEach { (_, value) in
                    XCTAssertEqual(value.className, "GameScore")
                    XCTAssertEqual(value.objectId, "yarr")
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testDeepSaveDetectCircular() throws {
        let score = GameScoreClass(score: 10)
        let game = GameClass(score: score)
        game.objectId = "nice"
        score.game = game

        game.ensureDeepSave { results in
            switch results {

            case .success:
                XCTFail("Should have failed with an error of detecting a circular dependency")
            case .failure(let error):
                XCTAssertTrue(error.message.contains("circular"))
            }
        }
    }

    func testDeepSaveTwoDeep() throws {
        var score = GameScore(score: 10)
        score.level = Level()
        var game = Game(score: score)
        game.objectId = "nice"

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil
        scoreOnServer.objectId = "yarr"
        let pointer = scoreOnServer.toPointer()
        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(pointer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        game.ensureDeepSave { results in
            switch results {

            case .success(let savedChildren):
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
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testDeepSavePointerArray() throws {
        var score = GameScore(score: 10)
        score.levels = [Level(), Level()]

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil
        scoreOnServer.objectId = "yarr"
        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder(skipKeys: false).encode(scoreOnServer)
            //Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        score.ensureDeepSave { results in
            switch results {

            case .success(let savedChildren):
                //This should be 2, but the URLMocker is limited to 1 response whic hashes to the same value
                XCTAssertEqual(savedChildren.count, 1)
                savedChildren.forEach { (_, value) in
                    XCTAssertEqual(value.className, "Level")
                    XCTAssertEqual(value.objectId, "yarr")
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
    }
}
#endif
// swiftlint:disable:this file_length
