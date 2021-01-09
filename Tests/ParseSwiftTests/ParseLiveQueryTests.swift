//
//  ParseLiveQueryTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/3/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class ParseLiveQueryTests: XCTestCase {
    struct GameScore: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: Int = 0

        //custom initializer
        init(score: Int) {
            self.score = score
        }

        init(objectId: String?) {
            self.objectId = objectId
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
                              masterKey: "masterKey",
                              serverURL: url,
                              testing: true)
        ParseLiveQuery.client = ParseLiveQuery()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        try? KeychainStore.shared.deleteAll()
        try? ParseStorage.shared.deleteAll()
        ParseLiveQuery.client = nil
    }

    func testWebsocketURL() throws {
        guard let originalURL = URL(string: "http://localhost:1337/1"),
            var components = URLComponents(url: originalURL,
                                             resolvingAgainstBaseURL: false) else {
            return
        }
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"
        let webSocketURL = components.url

        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }

        XCTAssertEqual(client.url, webSocketURL)
        XCTAssertTrue(client.url.absoluteString.contains("ws"))
    }

    func testInitializeWithNewURL() throws {
        guard let originalURL = URL(string: "http://parse:1337/1"),
            var components = URLComponents(url: originalURL,
                                             resolvingAgainstBaseURL: false) else {
            return
        }
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"
        let webSocketURL = components.url

        guard let client = ParseLiveQuery(serverURL: originalURL),
              let defaultClient = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to initialize a new client")
            return
        }

        XCTAssertEqual(client.url, webSocketURL)
        XCTAssertTrue(client.url.absoluteString.contains("ws"))
        XCTAssertNotEqual(client, defaultClient)
    }

    func testInitializeNewDefault() throws {

        guard let client = ParseLiveQuery(isDefault: true),
              let defaultClient = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to initialize a new client")
            return
        }

        XCTAssertTrue(client.url.absoluteString.contains("ws"))
        XCTAssertEqual(client, defaultClient)
    }

    func testDeinitializingNewShouldEffectDefault() throws {
        guard let defaultClient = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to initialize a new client")
            return
        }
        var client = ParseLiveQuery()
        if let client = client {
            XCTAssertTrue(client.url.absoluteString.contains("ws"))
        } else {
            XCTFail("Should have initialized client and contained ws")
        }
        XCTAssertNotEqual(client, defaultClient)
        client = nil
        XCTAssertNotNil(ParseLiveQuery.getDefault())
    }

    func testSocketNotOpenState() throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        client.isConnecting = true
        let expectation1 = XCTestExpectation(description: "Socket change")
        client.synchronizationQueue.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(client.isConnecting, false)
            client.isConnected = true
            client.synchronizationQueue.asyncAfter(deadline: .now() + 2) {
                XCTAssertEqual(client.isConnecting, false)
                XCTAssertEqual(client.isConnected, false)
                expectation1.fulfill()
            }
        }

        wait(for: [expectation1], timeout: 20.0)
    }

    func testConnectedState() throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        client.isSocketEstablished = true // Socket neets to be true
        client.isConnecting = true
        client.attempts = 50
        client.isConnected = true
        client.clientId = "yolo"

        XCTAssertEqual(client.isSocketEstablished, true)
        XCTAssertEqual(client.isConnecting, false)
        XCTAssertEqual(client.clientId, "yolo")
        XCTAssertEqual(client.attempts, 1)
    }

    func testDisconnectedState() throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        client.isSocketEstablished = true // Socket neets to be true
        client.isConnecting = true
        client.isConnected = true
        client.clientId = "yolo"

        XCTAssertEqual(client.isConnected, true)
        XCTAssertEqual(client.isConnecting, false)
        XCTAssertEqual(client.clientId, "yolo")
        client.isConnected = false

        XCTAssertEqual(client.isSocketEstablished, true)
        XCTAssertEqual(client.isConnected, false)
        XCTAssertEqual(client.isConnecting, false)
        XCTAssertNil(client.clientId)
    }

    func testSocketDisconnectedState() throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        client.isSocketEstablished = true // Socket neets to be true
        client.isConnecting = true
        client.isConnected = true
        client.clientId = "yolo"

        XCTAssertEqual(client.isConnected, true)
        XCTAssertEqual(client.isConnecting, false)
        XCTAssertEqual(client.clientId, "yolo")
        client.isSocketEstablished = false

        XCTAssertEqual(client.isConnected, false)
        XCTAssertEqual(client.isConnecting, false)
        XCTAssertNil(client.clientId)
    }

    func testUserClosedConnectionState() throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        client.isSocketEstablished = true // Socket needs to be true
        client.isConnecting = true
        client.isConnected = true
        client.clientId = "yolo"
        client.isDisconnectedByUser = false

        XCTAssertEqual(client.isConnected, true)
        XCTAssertEqual(client.isConnecting, false)
        XCTAssertEqual(client.isDisconnectedByUser, false)
        XCTAssertEqual(client.clientId, "yolo")
        client.close()

        XCTAssertEqual(client.isSocketEstablished, true)
        XCTAssertEqual(client.isConnected, false)
        XCTAssertEqual(client.isConnecting, false)
        XCTAssertNil(client.clientId)
        XCTAssertEqual(client.isDisconnectedByUser, true)
    }

    func testReconnectInterval() throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        for index in 0 ..< 50 {
            let time = client.reconnectInterval
            XCTAssertLessThan(time, 30)
            XCTAssertGreaterThan(time, -1)
            client.attempts += index
        }
    }

    func testRandomIdGenerator() throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        for index in 1 ..< 50 {
            let idGenerated = client.requestIdGenerator()
            XCTAssertEqual(idGenerated.value, index)
        }
    }
/*
    func testSubscribe() throws {
        if #available(iOS 13.0, *) {
            var query = GameScore.query("score" > 9)
            guard let subscription = query.subscribe else {
                return
            }

            let expectation1 = XCTestExpectation(description: "Fetch user1")

            subscription.handleSubscribe { subscribedQuery, isNew in

                //: You can check this subscription is for this query\
                if isNew {
                    print("Successfully subscribed to new query \(subscribedQuery)")
                } else {
                    print("Successfully updated subscription to new query \(subscribedQuery)")
                }
            }

            subscription.handleEvent { query, event in
                print(query)
                print(event)
                switch event {

                case .entered(let enter):
                    print(enter)
                case .left(let leave):
                    print(leave)
                case .created(let create):
                    print(create)
                case .updated(let update):
                    print(update)
                case .deleted(let delete):
                    print(delete)
                }
            }

            subscription.handleUnsubscribe { query in
                print("Unsubscribed from \(query)")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                //try? query.unsubscribe()
                query = GameScore.query("score" > 40)
                do {
                    try query.update(subscription)
                } catch {
                    print(error)
                }
            }

            wait(for: [expectation1], timeout: 200.0)
        } else {
            // Fallback on earlier versions
        }
    }
*/
}
