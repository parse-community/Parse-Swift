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
        var level: Level?
        var levels: [Level]?
        var nextLevel: Level?

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

    struct Level: ParseObject {
        var objectId: String?

        var createdAt: Date?

        var updatedAt: Date?

        var ACL: ParseACL?

        var name: String?

        var originalData: Data?
    }

    struct GameScoreDefaultMerge: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int?
        var player: String?
        var level: Level?
        var levels: [Level]?
        var nextLevel: Level?

        //: custom initializers
        init() {}

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

    struct Game: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var gameScore: GameScore
        var gameScores = [GameScore]()
        var name = "Hello"
        var profilePicture: ParseFile?

        //: a custom initializer
        init() {
            self.gameScore = GameScore()
        }

        init(gameScore: GameScore) {
            self.gameScore = gameScore
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

    final class GameScoreClass: ParseObject {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int
        var player = "Jen"
        var level: Level?
        var levels: [Level]?
        var game: GameClass?

        //: a custom initializer
        required init() {
            self.points = 5
        }

        init(points: Int) {
            self.points = points
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

         - returns: Returns a **true** if the other object has the same `objectId` or **false** if unsuccessful.
        */
        public static func == (lhs: ParseObjectAsyncTests.GameScoreClass,
                               rhs: ParseObjectAsyncTests.GameScoreClass) -> Bool {
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
            hasher.combine(self.id)
        }
    }

    final class GameClass: ParseObject {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var gameScore: GameScoreClass
        var gameScores = [GameScore]()
        var name = "Hello"

        //: a custom initializer
        required init() {
            self.gameScore = GameScoreClass()
        }

        init(gameScore: GameScoreClass) {
            self.gameScore = gameScore
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

         - returns: Returns a **true** if the other object has the same `objectId` or **false** if unsuccessful.
        */
        public static func == (lhs: ParseObjectAsyncTests.GameClass,
                               rhs: ParseObjectAsyncTests.GameClass) -> Bool {
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
            hasher.combine(self.id)
        }
    }

    struct User: ParseUser {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // These are required by ParseUser
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?
    }

    struct LoginSignupResponse: ParseUser {

        var objectId: String?
        var createdAt: Date?
        var sessionToken: String?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // These are required by ParseUser
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?

        init() {
            let date = Date()
            self.createdAt = date
            self.updatedAt = date
            self.objectId = "yarr"
            self.ACL = nil
            self.customKey = "blah"
            self.sessionToken = "myToken"
            self.username = "hello10"
            self.email = "hello@parse.com"
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

    func loginNormally() async throws -> User {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        let user = try await User.login(username: "parse", password: "user")
        MockURLProtocol.removeAll()
        return user
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
    func testUpdateDefaultMerge() async throws {
        var score = GameScoreDefaultMerge(points: 10)
        score.objectId = "yarr"
        var level = Level()
        level.name = "next"
        level.objectId = "yolo"
        score.level = level

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil
        scoreOnServer.points = 50
        scoreOnServer.player = "Ali"
        level.objectId = "nolo"
        scoreOnServer.level = level

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScoreDefaultMerge.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        score = score.set(\.player, to: "Ali")
            .set(\.points, to: 50)
            .set(\.level, to: level)
        let saved = try await score.update()
        XCTAssertEqual(saved, scoreOnServer)
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

    // swiftlint:disable:next function_body_length
    @MainActor
    func testDeepSaveOneDeep() async throws {
        let score = GameScore(points: 10)
        var game = Game(gameScore: score)

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil
        scoreOnServer.objectId = "yarr"

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil)]

        let encoded: Data!
        do {
            encoded = try GameScore.getJSONEncoder().encode(response)
            //Get dates in correct format from ParseDecoding strategy
            let encodedScoreOnServer = try scoreOnServer.getEncoder().encode(scoreOnServer)
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encodedScoreOnServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let (savedChildren, savedChildFiles) = try await game.ensureDeepSave()

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

        guard let savedChild = savedChildObject else {
            XCTFail("Should have unwrapped child object")
            return
        }

        // Saved updated info for game
        let encodedScore: Data
        do {
            encodedScore = try ParseCoding.jsonEncoder().encode(savedChild)
            // Decode Pointer as GameScore
            game.gameScore = try game.getDecoder().decode(GameScore.self, from: encodedScore)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        // Setup ParseObject to return from mocker
        MockURLProtocol.removeAll()

        var gameOnServer = game
        gameOnServer.objectId = "nice"
        gameOnServer.createdAt = Date()

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
                         childObjects: savedChildren,
                         childFiles: savedChildFiles) else {
            XCTFail("Should have saved game")
            return
        }
        XCTAssertEqual(savedGame.objectId, gameOnServer.objectId)
        XCTAssertEqual(savedGame.createdAt, gameOnServer.createdAt)
        XCTAssertEqual(savedGame.updatedAt, gameOnServer.createdAt)
        XCTAssertEqual(savedGame.gameScore, gameOnServer.gameScore)
    }

    // swiftlint:disable:next function_body_length
    @MainActor
    func testDeepSaveOneDeepWithDefaultACL() async throws {
        let user = try await loginNormally()
        guard let userObjectId = user.objectId else {
            XCTFail("Should have objectId")
            return
        }
        let defaultACL = try ParseACL.setDefaultACL(ParseACL(),
                                                    withAccessForCurrentUser: true)

        let score = GameScore(points: 10)
        var game = Game(gameScore: score)

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil
        scoreOnServer.objectId = "yarr"

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil)]

        let encoded: Data!
        do {
            encoded = try GameScore.getJSONEncoder().encode(response)
            //Get dates in correct format from ParseDecoding strategy
            let encodedScoreOnServer = try scoreOnServer.getEncoder().encode(scoreOnServer)
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encodedScoreOnServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let (savedChildren, savedChildFiles) = try await game.ensureDeepSave()

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

        guard let savedChild = savedChildObject else {
            XCTFail("Should have unwrapped child object")
            return
        }

        // Saved updated info for game
        let encodedScore: Data
        do {
            encodedScore = try ParseCoding.jsonEncoder().encode(savedChild)
            // Decode Pointer as GameScore
            game.gameScore = try game.getDecoder().decode(GameScore.self, from: encodedScore)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        //Setup ParseObject to return from mocker
        MockURLProtocol.removeAll()

        var gameOnServer = game
        gameOnServer.objectId = "nice"
        gameOnServer.createdAt = Date()

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
                         childObjects: savedChildren,
                         childFiles: savedChildFiles) else {
            XCTFail("Should have saved game")
            return
        }
        XCTAssertEqual(savedGame.objectId, gameOnServer.objectId)
        XCTAssertEqual(savedGame.createdAt, gameOnServer.createdAt)
        XCTAssertEqual(savedGame.updatedAt, gameOnServer.createdAt)
        XCTAssertEqual(savedGame.gameScore, gameOnServer.gameScore)
        XCTAssertNotNil(savedGame.ACL)
        XCTAssertEqual(savedGame.ACL?.publicRead, defaultACL.publicRead)
        XCTAssertEqual(savedGame.ACL?.publicWrite, defaultACL.publicWrite)
        XCTAssertTrue(defaultACL.getReadAccess(objectId: userObjectId))
        XCTAssertTrue(defaultACL.getWriteAccess(objectId: userObjectId))
    }

    @MainActor
    func testDeepSaveDetectCircular() async throws {
        let score = GameScoreClass(points: 10)
        let game = GameClass(gameScore: score)
        game.objectId = "nice"
        score.game = game
        do {
            _ = try await game.ensureDeepSave()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have failed with an error of detecting a circular dependency")
                return
            }
            XCTAssertTrue(parseError.message.contains("circular"))
        }
    }

    @MainActor
    func testAllowFieldsWithSameObject() async throws {
        var score = GameScore(points: 10)
        var level = Level()
        level.objectId = "nice"
        score.level = level
        score.nextLevel = level
        do {
            _ = try await score.ensureDeepSave()
        } catch {
            XCTFail("Should not throw an error: \(error.localizedDescription)")
        }
    }

    @MainActor
    func testDeepSaveTwoDeep() async throws {
        var score = GameScore(points: 10)
        score.level = Level()
        var game = Game(gameScore: score)
        game.objectId = "nice"

        var levelOnServer = score
        levelOnServer.createdAt = Date()
        levelOnServer.ACL = nil
        levelOnServer.objectId = "yarr"
        let pointer = try levelOnServer.toPointer()

        let response = [BatchResponseItem<Pointer<GameScore>>(success: pointer, error: nil)]
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

        let (savedChildren, savedChildFiles) = try await game.ensureDeepSave()
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
        XCTAssertEqual(level.first?.objectId, "yarr") // This is because mocker is only returning 1 response
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    // swiftlint:disable:next function_body_length
    @MainActor
    func testDeepSaveObjectWithFile() async throws {
        var game = Game2()

        guard let cloudPath = URL(string: "https://parseplatform.org/img/logo.svg"),
              // swiftlint:disable:next line_length
              let parseURL = URL(string: "http://localhost:1337/1/files/applicationId/89d74fcfa4faa5561799e5076593f67c_logo.svg") else {
            XCTFail("Should create URL")
            return
        }

        let parseFile = ParseFile(name: "profile.svg", cloudURL: cloudPath)
        game.profilePicture = parseFile

        let fileResponse = FileUploadResponse(name: "89d74fcfa4faa5561799e5076593f67c_\(parseFile.name)",
                                              url: parseURL)

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(fileResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let (savedChildren, savedChildFiles) = try await game.ensureDeepSave()
        XCTAssertEqual(savedChildren.count, 0)
        XCTAssertEqual(savedChildFiles.count, 1)
        var counter = 0
        var savedFile: ParseFile?
        savedChildFiles.forEach { (_, value) in
            XCTAssertEqual(value.url, fileResponse.url)
            XCTAssertEqual(value.name, fileResponse.name)
            if counter == 0 {
                savedFile = value
            }
            counter += 1
        }

        //Saved updated info for game
        game.profilePicture = savedFile

        //Setup ParseObject to return from mocker
        MockURLProtocol.removeAll()

        var gameOnServer = game
        gameOnServer.objectId = "nice"
        gameOnServer.createdAt = Date()
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
                         childObjects: savedChildren,
                         childFiles: savedChildFiles) else {
            XCTFail("Should have saved game")
            return
        }
        XCTAssertEqual(savedGame.objectId, gameOnServer.objectId)
        XCTAssertEqual(savedGame.createdAt, gameOnServer.createdAt)
        XCTAssertEqual(savedGame.updatedAt, gameOnServer.createdAt)
        XCTAssertEqual(savedGame.profilePicture, gameOnServer.profilePicture)
    }
    #endif
}
#endif
