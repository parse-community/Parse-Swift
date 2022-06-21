//
//  ParseHookFunctionTests.swift
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

class ParseHookFunctionTests: XCTestCase {
    struct TestFunction: ParseHookFunctionable {
        var functionName: String?
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
        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))
        let expected = "{\"functionName\":\"foo\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookFunction.description, expected)
    }

    func testParseHookSuccessResponse() throws {
        let response = ParseHookSuccessResponse(true)
        let expected = "{\"success\":true}"
        XCTAssertEqual(response.description, expected)
    }

    @MainActor
    func testCreate() async throws {

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))

        let server = hookFunction
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let created = try await hookFunction.create()
        XCTAssertEqual(created, server)
    }

    @MainActor
    func testCreateError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookFunction.create()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testUpdate() async throws {

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))

        let server = hookFunction
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let updated = try await hookFunction.update()
        XCTAssertEqual(updated, server)
    }

    @MainActor
    func testUpdateError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookFunction.update()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testFetch() async throws {

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))

        let server = hookFunction
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let fetched = try await hookFunction.fetch()
        XCTAssertEqual(fetched, server)
    }

    @MainActor
    func testFetchError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookFunction.fetch()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testFetchAll() async throws {

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))

        let server = [hookFunction]
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let fetched = try await hookFunction.fetchAll()
        XCTAssertEqual(fetched, server)
    }

    @MainActor
    func testFetchAllError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookFunction.fetchAll()
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

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))
        try await hookFunction.delete()
    }

    @MainActor
    func testDeleteError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))
        do {
            try await hookFunction.delete()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }
}

#endif
