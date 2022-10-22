//
//  ParseLiveQueryCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/25/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows)
import Foundation
import XCTest
@testable import ParseSwift
#if canImport(Combine)
import Combine
#endif

class ParseLiveQueryCombineTests: XCTestCase {

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

    func testOpen() throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        client.close()

        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Send Ping")
        let publisher = client.openPublisher(isUserWantsToConnect: true)
            .sink(receiveCompletion: { result in

                switch result {

                case .finished:
                    XCTFail("Should have produced failure")
                case .failure(let error):
                    XCTAssertNotNil(error) //Should always fail since WS is not intercepted.
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have produced error")
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testPingSocketNotEstablished() throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        client.close()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Send Ping")
        let publisher = client.sendPingPublisher()
            .sink(receiveCompletion: { result in

                switch result {

                case .finished:
                    XCTFail("Should have produced failure")
                case .failure(let error):
                    XCTAssertEqual(client.isSocketEstablished, false)
                    guard let urlError = error as? URLError else {
                        XCTFail("Should have casted to ParseError.")
                        expectation1.fulfill()
                        return
                    }
                    // "Could not connect to the server"
                    // because webSocket connections are not intercepted.
                    XCTAssertTrue([-1004, -1022].contains(urlError.errorCode))
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have produced error")
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testPing() throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        client.isSocketEstablished = true // Socket needs to be true
        client.isConnecting = true
        client.isConnected = true
        client.clientId = "yolo"

        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Send Ping")
        let publisher = client.sendPingPublisher()
            .sink(receiveCompletion: { result in

                switch result {

                case .finished:
                    XCTFail("Should have produced failure")
                case .failure(let error):
                    XCTAssertEqual(client.isSocketEstablished, true)
                    XCTAssertNotNil(error) // Should have error because testcases do not intercept websocket
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have produced error")
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }
}
#endif
