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
                              masterKey: "masterKey",
                              serverURL: url,
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android)
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
        XCTAssertEqual(command2.body?.dimensions, dimensions)

        event2.at = nil //Clear date for comparison
        let decoded = event2.debugDescription
        let expected = "{\"dimensions\":{\"stop\":\"drop\"}}"
        XCTAssertEqual(decoded, expected)
        let decoded2 = event2.description
        let expected2 = "{\"dimensions\":{\"stop\":\"drop\"}}"
        XCTAssertEqual(decoded2, expected2)
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

    #if canImport(AppTrackingTransparency)
    func testTrackAppOpenedUIKitNotAuthorized() {
        if #available(macOS 11.0, iOS 14.0, macCatalyst 14.0, tvOS 14.0, *) {
            ParseSwift.configuration.isTestingSDK = false //Allow authorization check
            let expectation = XCTestExpectation(description: "Analytics save")
            let options = [UIApplication.LaunchOptionsKey.remoteNotification: ["stop": "drop"]]
            ParseAnalytics.trackAppOpened(launchOptions: options) { result in

                switch result {

                case .success:
                    XCTFail("Should have failed with not authorized.")
                case .failure(let error):
                    XCTAssertTrue(error.message.contains("request permission"))
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }
    #endif
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

    #if canImport(AppTrackingTransparency)
    func testTrackAppOpenedNotAuthorized() {
        if #available(macOS 11.0, iOS 14.0, macCatalyst 14.0, tvOS 14.0, *) {
            ParseSwift.configuration.isTestingSDK = false //Allow authorization check

            let expectation = XCTestExpectation(description: "Analytics save")
            ParseAnalytics.trackAppOpened(dimensions: ["stop": "drop"]) { result in

                switch result {

                case .success:
                    XCTFail("Should have failed with not authorized.")
                case .failure(let error):
                    XCTAssertTrue(error.message.contains("request permission"))
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }
    #endif

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

    #if canImport(AppTrackingTransparency)
    func testTrackEventNotAuthorized() {
        if #available(macOS 11.0, iOS 14.0, macCatalyst 14.0, tvOS 14.0, *) {
            ParseSwift.configuration.isTestingSDK = false //Allow authorization check

            let expectation = XCTestExpectation(description: "Analytics save")
            let event = ParseAnalytics(name: "hello")
            event.track { result in

                switch result {

                case .success:
                    XCTFail("Should have failed with not authorized.")
                case .failure(let error):
                    XCTAssertTrue(error.message.contains("request permission"))
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }

    func testTrackEventNotAuthorizedMutated() {
        if #available(macOS 11.0, iOS 14.0, macCatalyst 14.0, tvOS 14.0, *) {
            ParseSwift.configuration.isTestingSDK = false //Allow authorization check

            let expectation = XCTestExpectation(description: "Analytics save")
            var event = ParseAnalytics(name: "hello")
            event.track(dimensions: nil) { result in

                switch result {

                case .success:
                    XCTFail("Should have failed with not authorized.")
                case .failure(let error):
                    XCTAssertTrue(error.message.contains("request permission"))
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }
    #endif
}
