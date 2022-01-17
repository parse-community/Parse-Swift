//
//  ParseAnanlyticsAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency) && !os(Linux) && !os(Android) && !os(Windows)
import Foundation
import XCTest
@testable import ParseSwift

class ParseAnanlyticsAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length
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
                              isTesting: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    #if os(iOS)
    @MainActor
    func testTrackAppOpenedUIKit() async throws {

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
        let options = [UIApplication.LaunchOptionsKey.remoteNotification: ["stop": "drop"]]
        _ = try await ParseAnalytics.trackAppOpened(launchOptions: options)
    }
    #endif

    @MainActor
    func testTrackAppOpened() async throws {
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

        _ = try await ParseAnalytics.trackAppOpened(dimensions: ["stop": "drop"])
    }

    @MainActor
    func testTrackEvent() async throws {
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
        let event = ParseAnalytics(name: "hello")
        _ = try await event.track()
    }

    func testTrackEventMutated() async throws {
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
        let event = ParseAnalytics(name: "hello")
        _ = try await event.track(dimensions: ["stop": "drop"])
    }
}
#endif
