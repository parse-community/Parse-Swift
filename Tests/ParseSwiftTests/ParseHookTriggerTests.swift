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

    func testCoding() throws {
        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))
        // swiftlint:disable:next line_length
        let expected = "{\"className\":\"foo\",\"triggerName\":\"afterSave\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger.description, expected)
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
}

#endif
