//
//  ParseSchemaAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/29/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseSchemaAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length
    struct GameScore: ParseObject, ParseQueryScorable {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var score: Double?
        var originalData: Data?

        //: Your own properties
        var points: Int
        var isCounts: Bool?

        //: a custom initializer
        init() {
            self.points = 5
        }
        init(points: Int) {
            self.points = points
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

    func createDummySchema() -> ParseSchema<GameScore> {
        ParseSchema<GameScore>()
            .addField("a",
                      type: .string,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("b",
                      type: .number,
                      options: ParseFieldOptions<Int>(required: false, defauleValue: 2))
            .deleteField("c")
            .addIndex("hello", field: "world", index: "yolo")
    }

    @MainActor
    func testCreate() async throws {

        let schema = createDummySchema()

        var serverResponse = schema
        serverResponse.indexes = schema.pendingIndexes
        serverResponse.pendingIndexes.removeAll()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let saved = try await schema.create()
        XCTAssertEqual(saved.fields, serverResponse.fields)
        XCTAssertEqual(saved.indexes, serverResponse.indexes)
        XCTAssertEqual(saved.classLevelPermissions, serverResponse.classLevelPermissions)
        XCTAssertEqual(saved.className, serverResponse.className)
        XCTAssertTrue(saved.pendingIndexes.isEmpty)
    }

    @MainActor
    func testCreateError() async throws {

        let schema = createDummySchema()

        let parseError = ParseError(code: .invalidSchemaOperation,
                                    message: "Problem with schema")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        do {
            _ = try await schema.create()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.invalidSchemaOperation))
        }
    }

    @MainActor
    func testUpdate() async throws {

        let schema = createDummySchema()

        var serverResponse = schema
        serverResponse.indexes = schema.pendingIndexes
        serverResponse.pendingIndexes.removeAll()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let saved = try await schema.update()
        XCTAssertEqual(saved.fields, serverResponse.fields)
        XCTAssertEqual(saved.indexes, serverResponse.indexes)
        XCTAssertEqual(saved.classLevelPermissions, serverResponse.classLevelPermissions)
        XCTAssertEqual(saved.className, serverResponse.className)
        XCTAssertTrue(saved.pendingIndexes.isEmpty)
    }

    @MainActor
    func testUpdateOldIndexes() async throws {

        var schema = createDummySchema()
        schema.indexes = [
            "meta": ["world": "peace"],
            "stop": ["being": "greedy"]
        ]
        schema.pendingIndexes.removeAll()

        let serverResponse = schema

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let saved = try await schema.update()
        XCTAssertEqual(saved.fields, serverResponse.fields)
        XCTAssertEqual(saved.indexes, serverResponse.indexes)
        XCTAssertEqual(saved.classLevelPermissions, serverResponse.classLevelPermissions)
        XCTAssertEqual(saved.className, serverResponse.className)
        XCTAssertTrue(saved.pendingIndexes.isEmpty)
    }

    @MainActor
    func testUpdateError() async throws {

        let schema = createDummySchema()

        let parseError = ParseError(code: .invalidSchemaOperation,
                                    message: "Problem with schema")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        do {
            _ = try await schema.update()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.invalidSchemaOperation))
        }
    }

    @MainActor
    func testFetch() async throws {

        let schema = createDummySchema()

        var serverResponse = schema
        serverResponse.indexes = schema.pendingIndexes
        serverResponse.pendingIndexes.removeAll()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let saved = try await schema.fetch()
        XCTAssertEqual(saved.fields, serverResponse.fields)
        XCTAssertEqual(saved.indexes, serverResponse.indexes)
        XCTAssertEqual(saved.classLevelPermissions, serverResponse.classLevelPermissions)
        XCTAssertEqual(saved.className, serverResponse.className)
        XCTAssertTrue(saved.pendingIndexes.isEmpty)
    }

    @MainActor
    func testFetchError() async throws {

        let schema = createDummySchema()

        let parseError = ParseError(code: .invalidSchemaOperation,
                                    message: "Problem with schema")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        do {
            _ = try await schema.fetch()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.invalidSchemaOperation))
        }
    }

    @MainActor
    func testPurge() async throws {

        let schema = createDummySchema()

        let serverResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        try await schema.purge()
    }

    @MainActor
    func testPurgeError() async throws {

        let schema = createDummySchema()

        let parseError = ParseError(code: .invalidSchemaOperation,
                                    message: "Problem with schema")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        do {
            _ = try await schema.purge()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.invalidSchemaOperation))
        }
    }

    @MainActor
    func testDelete() async throws {

        let schema = createDummySchema()

        let serverResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        try await schema.delete()
    }

    @MainActor
    func testDeleteError() async throws {

        let schema = createDummySchema()

        let parseError = ParseError(code: .invalidSchemaOperation,
                                    message: "Problem with schema")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        do {
            _ = try await schema.delete()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.invalidSchemaOperation))
        }
    }
}
#endif
