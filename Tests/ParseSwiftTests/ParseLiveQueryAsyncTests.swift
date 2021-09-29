//
//  ParseLiveQueryAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(_Concurrency) && !os(Linux) && !os(Android)
import Foundation
import XCTest
@testable import ParseSwift

@available(macOS 12.0, iOS 15.0, macCatalyst 15.0, watchOS 9.0, tvOS 15.0, *)
class ParseLiveQueryAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length
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
        ParseLiveQuery.setDefault(try ParseLiveQuery(isDefault: true))
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
        URLSession.liveQuery.closeAll()
    }

    @MainActor
    func testOpen() async throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        client.close()

        do {
            _ = try await client.open(isUserWantsToConnect: true)
            XCTFail("Should always fail since WS isn't intercepted.")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    @MainActor
    func testPingSocketNotEstablished() async throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        client.close()

        do {
            _ = try await client.sendPing()
            XCTFail("Should have produced error")
        } catch {
            XCTAssertEqual(client.isSocketEstablished, false)
            guard let urlError = error as? URLError else {
                XCTFail("Should have casted to ParseError.")
                return
            }
            // "Could not connect to the server"
            // because webSocket connections are not intercepted.
            XCTAssertEqual(urlError.errorCode, -1004)
        }
    }

    @MainActor
    func testPing() async throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        client.isSocketEstablished = true // Socket needs to be true
        client.isConnecting = true
        client.isConnected = true
        client.clientId = "yolo"

        do {
            _ = try await client.sendPing()
            XCTFail("Should have produced error")
        } catch {
            XCTAssertEqual(client.isSocketEstablished, true)
            XCTAssertNotNil(error) // Should have error because testcases don't intercept websocket
        }
    }
}
#endif
