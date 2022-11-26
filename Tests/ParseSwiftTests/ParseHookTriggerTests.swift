//
//  ParseHookTriggerTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/20/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseHookTriggerTests: XCTestCase {
    struct TestTrigger: ParseHookTriggerable {
        var className: String?
        var triggerName: ParseHookTriggerType?
        var url: URL?
    }

    struct GameScore: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int?

        //: custom initializers
        init() {}

        init(points: Int) {
            self.points = points
        }

        //: Implement your own version of merge
        func merge(with object: Self) throws -> Self {
            var updated = try mergeParse(with: object)
            if updated.shouldRestoreKey(\.points,
                                         original: object) {
                updated.points = object.points
            }
            return updated
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

    func testCoding() throws {
        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))
        // swiftlint:disable:next line_length
        let expected = "{\"className\":\"foo\",\"triggerName\":\"afterSave\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger.description, expected)
        let object = GameScore()
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        let hookTrigger2 = TestTrigger(object: object,
                                       triggerName: .afterSave,
                                       url: url)
        // swiftlint:disable:next line_length
        let expected2 = "{\"className\":\"GameScore\",\"triggerName\":\"afterSave\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger2.description, expected2)
        let hookTrigger3 = try TestTrigger(triggerName: .afterSave,
                                           url: url)
        // swiftlint:disable:next line_length
        let expected3 = "{\"className\":\"@File\",\"triggerName\":\"afterSave\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger3.description, expected3)
        let hookTrigger4 = try TestTrigger(triggerName: .beforeConnect,
                                           url: url)
        // swiftlint:disable:next line_length
        let expected4 = "{\"className\":\"@Connect\",\"triggerName\":\"beforeConnect\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger4.description, expected4)
    }

    func testInitializerError() throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertThrowsError(try TestTrigger(triggerName: .afterFind,
                                             url: url))
    }

    @MainActor
    func testCreate() async throws {

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))

        let server = hookTrigger
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let created = try await hookTrigger.create()
        XCTAssertEqual(created, server)
    }

    @MainActor
    func testCreateError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookTrigger.create()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testCreateError2() async throws {

        let hookTrigger = TestTrigger(triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookTrigger.create()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }

    @MainActor
    func testUpdate() async throws {

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))

        let server = hookTrigger
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let updated = try await hookTrigger.update()
        XCTAssertEqual(updated, server)
    }

    @MainActor
    func testUpdateError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookTrigger.update()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testUpdateError2() async throws {

        let hookTrigger = TestTrigger(triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookTrigger.update()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }

    @MainActor
    func testUpdateError3() async throws {

        let hookTrigger = TestTrigger(className: "foo",
                                      url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookTrigger.update()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }

    @MainActor
    func testFetch() async throws {

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))

        let server = hookTrigger
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let fetched = try await hookTrigger.fetch()
        XCTAssertEqual(fetched, server)
    }

    @MainActor
    func testFetchError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookTrigger.fetch()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testFetchError2() async throws {

        let hookTrigger = TestTrigger(triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookTrigger.fetch()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }

    @MainActor
    func testFetchAll() async throws {

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))

        let server = [hookTrigger]
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let fetched = try await hookTrigger.fetchAll()
        XCTAssertEqual(fetched, server)
    }

    @MainActor
    func testFetchAllError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookTrigger.fetchAll()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testDelete() async throws {
        let server = NoBody()
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))
        try await hookTrigger.delete()
    }

    @MainActor
    func testDeleteError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))
        do {
            try await hookTrigger.delete()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testDeleteError2() async throws {

        let hookTrigger = TestTrigger(triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookTrigger.delete()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }
}

#endif
