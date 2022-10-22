//
//  ParseHealthTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseHealthTests: XCTestCase {

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

    func testCheckCommand() throws {
        let command = ParseHealth.healthCommand()
        XCTAssertEqual(command.path.urlComponent, "/health")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.body)
    }

    func testCheck() {

        let healthOfServer = "ok"
        let serverResponse = HealthResponse(status: healthOfServer)
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
            let health = try ParseHealth.check()
            XCTAssertEqual(health, healthOfServer)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testCheckAsync() {
        let healthOfServer = "ok"
        let serverResponse = HealthResponse(status: healthOfServer)
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

        let expectation = XCTestExpectation(description: "Health check")
        ParseHealth.check { result in
            switch result {

            case .success(let health):
                XCTAssertEqual(health, healthOfServer)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testCheckErrorAsync() {
        let healthOfServer = "Should throw error"
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(healthOfServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation = XCTestExpectation(description: "Health check")
        ParseHealth.check { result in
            if case .success = result {
                XCTFail("Should have thrown error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
