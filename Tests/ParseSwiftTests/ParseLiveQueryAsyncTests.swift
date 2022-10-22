//
//  ParseLiveQueryAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency) && !os(Linux) && !os(Android) && !os(Windows)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseLiveQueryAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length
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
        ParseLiveQuery.defaultClient = try ParseLiveQuery(isDefault: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
        URLSession.liveQuery.closeAll()
    }

    @MainActor
    func testOpen() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        client.close()

        do {
            _ = try await client.open(isUserWantsToConnect: true)
            XCTFail("Should always fail since WS is not intercepted.")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    @MainActor
    func testPingSocketNotEstablished() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
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
            XCTAssertTrue([-1004, -1022].contains(urlError.errorCode))
        }
    }

    @MainActor
    func testPing() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
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
            XCTAssertNotNil(error) // Should have error because testcases do not intercept websocket
        }
    }
}
#endif
