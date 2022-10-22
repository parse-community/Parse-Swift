//
//  ParseAnalyticsTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/20/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseAnalyticsTests: XCTestCase {

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

    func testSaveCommand() throws {
        let name = "hello"
        let event = ParseAnalytics(name: name)
        let command = event.saveCommand()
        XCTAssertEqual(command.path.urlComponent, "/events/\(name)")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNotNil(command.body)
        XCTAssertNil(command.body?.at)
        XCTAssertNil(command.body?.dimensions)

        let date = Date()
        let dimensions = ["stop": "drop"]
        var event2 = ParseAnalytics(name: name, dimensions: dimensions, at: date)
        let command2 = event2.saveCommand()
        XCTAssertEqual(command2.path.urlComponent, "/events/\(name)")
        XCTAssertEqual(command2.method, API.Method.POST)
        XCTAssertNotNil(command2.body)
        XCTAssertEqual(command2.body?.at, date)
        XCTAssertNotNil(command2.body?.dimensions)

        event2.date = nil //Clear date for comparison
        let decoded = event2.debugDescription
        let expected = "{\"dimensions\":{\"stop\":\"drop\"},\"name\":\"hello\"}"
        XCTAssertEqual(decoded, expected)
        let decoded2 = event2.description
        let expected2 = "{\"dimensions\":{\"stop\":\"drop\"},\"name\":\"hello\"}"
        XCTAssertEqual(decoded2, expected2)
        let encoded3 = try ParseCoding.parseEncoder().encode(event2)
        let decoded3 = String(data: encoded3, encoding: .utf8)
        let expected3 = "{\"dimensions\":{\"stop\":\"drop\"}}"
        XCTAssertEqual(decoded3, expected3)
    }

    func testEquatable() throws {
        let name = "hello"
        let event = ParseAnalytics(name: name)
        let event2 = ParseAnalytics(name: name,
                                    dimensions: ["stop": "drop"],
                                    at: Date())
        XCTAssertEqual(event, event)
        XCTAssertNotEqual(event, event2)
        XCTAssertEqual(event2, event2)
    }

    func testHashable() throws {
        let name = "hello"
        let event = ParseAnalytics(name: name)
        let event2 = ParseAnalytics(name: name,
                                    dimensions: ["stop": "drop"],
                                    at: Date())
        let event3 = ParseAnalytics(name: "world")
        let events = [event: 1, event2: 2]
        XCTAssertEqual(events[event], 1)
        XCTAssertEqual(events[event2], 2)
        XCTAssertNil(events[event3])
    }

    func testSetDimensions() throws {
        let name = "hello"
        let dimensions = ["stop": "drop"]
        let dimensions2 = ["open": "up shop"]
        var event = ParseAnalytics(name: name, dimensions: dimensions)
        let encodedDimensions = try ParseCoding.jsonEncoder().encode(AnyCodable(event.dimensions))
        let decodedDictionary = try ParseCoding.jsonDecoder().decode([String: String].self,
                                                                     from: encodedDimensions)
        XCTAssertEqual(decodedDictionary, dimensions)
        event.dimensions = dimensions2
        let encoded = try ParseCoding.jsonEncoder().encode(AnyCodable(event.dimensions))
        let encodedExpected = try ParseCoding.jsonEncoder().encode(dimensions2)
        XCTAssertEqual(encoded, encodedExpected)
        let encoded2 = try ParseCoding.jsonEncoder().encode(event.dimensionsAnyCodable)
        XCTAssertEqual(encoded2, encodedExpected)
    }

    func testUpdateDimensions() throws {
        let name = "hello"
        let dimensions = ["stop": "drop"]
        let dimensions2 = ["open": "up shop"]
        var dimensions3 = dimensions
        for (key, value) in dimensions2 {
            dimensions3[key] = value
        }
        var event = ParseAnalytics(name: name, dimensions: dimensions)
        event.dimensions = dimensions2
        let encoded = try ParseCoding.jsonEncoder().encode(AnyCodable(event.dimensions))
        let encodedExpected = try ParseCoding.jsonEncoder().encode(dimensions2)
        XCTAssertEqual(encoded, encodedExpected)
    }

    func testUpdateDimensionsNonInitially() throws {
        let name = "hello"
        let dimensions = ["stop": "drop"]
        var event = ParseAnalytics(name: name)
        XCTAssertNil(event.dimensions)
        event.dimensions = dimensions
        let encoded = try ParseCoding.jsonEncoder().encode(AnyCodable(event.dimensions))
        let encodedExpected = try ParseCoding.jsonEncoder().encode(dimensions)
        XCTAssertEqual(encoded, encodedExpected)
    }

    #if os(iOS)
    func testTrackAppOpenedUIKit() {
        let serverResponse = NoBody()
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

        let expectation = XCTestExpectation(description: "Analytics save")
        let options = [UIApplication.LaunchOptionsKey.remoteNotification: ["stop": "drop"]]
        ParseAnalytics.trackAppOpened(launchOptions: options) { result in

            if case .failure(let error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testTrackAppOpenedUIKitError() {
        let serverResponse = ParseError(code: .missingObjectId, message: "Object missing objectId")
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

        let expectation = XCTestExpectation(description: "Analytics save")
        let options = [UIApplication.LaunchOptionsKey.remoteNotification: ["stop": "drop"]]
        ParseAnalytics.trackAppOpened(launchOptions: options) { result in

            if case .success = result {
                XCTFail("Should have failed with error.")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    #endif

    func testTrackAppOpened() {
        let serverResponse = NoBody()
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

        let expectation = XCTestExpectation(description: "Analytics save")
        ParseAnalytics.trackAppOpened(dimensions: ["stop": "drop"]) { result in

            if case .failure(let error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testTrackAppOpenedError() {
        let serverResponse = ParseError(code: .missingObjectId, message: "Object missing objectId")
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

        let expectation = XCTestExpectation(description: "Analytics save")
        ParseAnalytics.trackAppOpened(dimensions: ["stop": "drop"]) { result in

            if case .success = result {
                XCTFail("Should have failed with error.")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testTrackEvent() {
        let serverResponse = NoBody()
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

        let expectation = XCTestExpectation(description: "Analytics save")
        let event = ParseAnalytics(name: "hello")
        event.track { result in

            if case .failure(let error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testTrackEventMutated() {
        let serverResponse = NoBody()
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

        let expectation = XCTestExpectation(description: "Analytics save")
        var event = ParseAnalytics(name: "hello")
        event.track(dimensions: nil) { result in

            if case .failure(let error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testTrackEventError() {
        let serverResponse = ParseError(code: .missingObjectId, message: "Object missing objectId")
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

        let expectation = XCTestExpectation(description: "Analytics save")
        let event = ParseAnalytics(name: "hello")
        event.track { result in

            if case .success = result {
                XCTFail("Should have failed with error.")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testTrackEventErrorMutated() {
        let serverResponse = ParseError(code: .missingObjectId, message: "Object missing objectId")
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

        let expectation = XCTestExpectation(description: "Analytics save")
        var event = ParseAnalytics(name: "hello")
        event.track(dimensions: nil) { result in

            if case .success = result {
                XCTFail("Should have failed with error.")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
