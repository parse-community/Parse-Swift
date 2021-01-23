//
//  ParseLiveQueryTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/3/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//
#if !os(Linux)
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

    class TestDelegate: ParseLiveQueryDelegate {
        var error: ParseError?
        func received(_ error: ParseError) {
            self.error = error
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
        ParseLiveQuery.client = try? ParseLiveQuery(isDefault: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
        URLSession.liveQuery.closeAll()
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

        let expectation1 = XCTestExpectation(description: "Socket delegate")
        client.synchronizationQueue.async {
            let socketDelegates = URLSession.liveQuery.delegates
            XCTAssertNotNil(socketDelegates[client.task])
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testInitializeWithNewURL() throws {
        guard let originalURL = URL(string: "http://parse:1337/1"),
            var components = URLComponents(url: originalURL,
                                             resolvingAgainstBaseURL: false) else {
            return
        }
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"
        let webSocketURL = components.url

        guard let client = try? ParseLiveQuery(serverURL: originalURL),
              let defaultClient = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to initialize a new client")
            return
        }

        XCTAssertEqual(client.url, webSocketURL)
        XCTAssertTrue(client.url.absoluteString.contains("ws"))
        XCTAssertNotEqual(client, defaultClient)
        let expectation1 = XCTestExpectation(description: "Socket delegate")
        client.synchronizationQueue.async {
            let socketDelegates = URLSession.liveQuery.delegates
            XCTAssertNotNil(socketDelegates[client.task])
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testInitializeNewDefault() throws {

        guard let client = try? ParseLiveQuery(isDefault: true),
              let defaultClient = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to initialize a new client")
            return
        }

        XCTAssertTrue(client.url.absoluteString.contains("ws"))
        XCTAssertEqual(client, defaultClient)
        let expectation1 = XCTestExpectation(description: "Socket delegate")
        client.synchronizationQueue.async {
            let socketDelegates = URLSession.liveQuery.delegates
            XCTAssertNotNil(socketDelegates[client.task])
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeinitializingNewShouldNotEffectDefault() throws {
        guard let defaultClient = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to initialize a new client")
            return
        }
        var client = try? ParseLiveQuery()
        if let client = client {
            XCTAssertTrue(client.url.absoluteString.contains("ws"))
        } else {
            XCTFail("Should have initialized client and contained ws")
        }
        XCTAssertNotEqual(client, defaultClient)
        client = nil
        XCTAssertNotNil(ParseLiveQuery.getDefault())
        let expectation1 = XCTestExpectation(description: "Socket delegate")
        defaultClient.synchronizationQueue.async {
            let socketDelegates = URLSession.liveQuery.delegates
            XCTAssertNotNil(socketDelegates[defaultClient.task])
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testBecomingSocketAuthDelegate() throws {
        let delegate = TestDelegate()
        let client = ParseLiveQuery.getDefault()
        XCTAssertNil(URLSession.liveQuery.authenticationDelegate)
        client?.authenticationDelegate = delegate
        guard let authDelegate = URLSession
                .liveQuery
                .authenticationDelegate as? ParseLiveQuery else {
            XCTFail("Should be able to cast")
            return
        }
        XCTAssertEqual(client, authDelegate)
        XCTAssertNotNil(URLSession.liveQuery.authenticationDelegate)
        client?.authenticationDelegate = nil
        XCTAssertNil(URLSession.liveQuery.authenticationDelegate)
    }

    func testStandardMessageEncoding() throws {
        guard let installationId = BaseParseInstallation.currentInstallationContainer.installationId else {
            XCTFail("Should have installationId")
            return
        }
        // swiftlint:disable:next line_length
        let expected = "{\"op\":\"connect\",\"applicationId\":\"applicationId\",\"clientKey\":\"clientKey\",\"masterKey\":\"masterKey\",\"installationId\":\"\(installationId)\"}"
        let message = StandardMessage(operation: .connect, additionalProperties: true)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testSubscribeMessageEncoding() throws {
        // swiftlint:disable:next line_length
        let expected = "{\"op\":\"subscribe\",\"requestId\":1,\"query\":{\"className\":\"GameScore\",\"where\":{\"score\":{\"$gt\":9}},\"fields\":[\"score\"]}}"
        let query = GameScore.query("score" > 9)
            .fields("score")
        let message = SubscribeMessage(operation: .subscribe,
                                       requestId: RequestId(value: 1),
                                       query: query,
                                       additionalProperties: true)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testRedirectResponseDecoding() throws {
        guard let url = URL(string: "http://parse.org") else {
            XCTFail("Should have url")
            return
        }
        let expected = "{\"op\":\"redirect\",\"url\":\"http:\\/\\/parse.org\"}"
        let message = RedirectResponse(op: .redirect, url: url)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testConnectionResponseDecoding() throws {
        let expected = "{\"op\":\"connected\",\"clientId\":\"yolo\",\"installationId\":\"naw\"}"
        let message = ConnectionResponse(op: .connected, clientId: "yolo", installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testUnsubscribeResponseDecoding() throws {
        let expected = "{\"op\":\"connected\",\"clientId\":\"yolo\",\"requestId\":1,\"installationId\":\"naw\"}"
        let message = UnsubscribedResponse(op: .connected, requestId: 1, clientId: "yolo", installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testEventResponseDecoding() throws {
        // swiftlint:disable:next line_length
        let expected = "{\"op\":\"connected\",\"object\":{\"score\":10},\"requestId\":1,\"clientId\":\"yolo\",\"installationId\":\"naw\"}"
        let score = GameScore(score: 10)
        let message = EventResponse(op: .connected,
                                    requestId: 1,
                                    object: score,
                                    clientId: "yolo",
                                    installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testErrorResponseDecoding() throws {
        let expected = "{\"code\":1,\"op\":\"error\",\"error\":\"message\",\"reconnect\":true}"
        let message = ErrorResponse(op: .error, code: 1, error: "message", reconnect: true)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testPreliminaryResponseDecoding() throws {
        let expected = "{\"op\":\"subscribed\",\"clientId\":\"message\",\"requestId\":1,\"installationId\":\"naw\"}"
        let message = PreliminaryMessageResponse(op: .subscribed,
                                                 requestId: 1,
                                                 clientId: "message",
                                                 installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testSocketNotOpenState() throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        client.isConnecting = true
        XCTAssertEqual(client.isConnecting, false)
        client.isConnected = true
        XCTAssertEqual(client.isConnecting, false)
        XCTAssertEqual(client.isConnected, false)
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

    func testSubscribeNotConnected() throws {
        let query = GameScore.query("score" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)
        XCTAssertFalse(try client.isSubscribed(query))
        XCTAssertTrue(try client.isPendingSubscription(query))
        XCTAssertEqual(client.subscriptions.count, 0)
        XCTAssertEqual(client.pendingSubscriptions.count, 1)
        XCTAssertNoThrow(try client.removePendingSubscription(query))
        XCTAssertEqual(client.pendingSubscriptions.count, 0)
    }

    func pretendToBeConnected() throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        client.task = URLSession.liveQuery.createTask(client.url)
        client.status(.open)
        let response = ConnectionResponse(op: .connected, clientId: "yolo", installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        client.received(encoded)
    }

    func testSubscribeConnected() throws {
        let query = GameScore.query("score" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Unsubscribe Handler")
        subscription.handleSubscribe { subscribedQuery, isNew in
            XCTAssertEqual(query, subscribedQuery)
            XCTAssertTrue(isNew)
            expectation1.fulfill()

            //Unsubscribe
            subscription.handleUnsubscribe { query in
                XCTAssertEqual(query, subscribedQuery)
                expectation2.fulfill()
            }
            XCTAssertNotNil(try? query.unsubscribe())
            XCTAssertEqual(client.pendingSubscriptions.count, 1)
            XCTAssertEqual(client.subscriptions.count, 1)

            //Received Unsubscribe
            let response2 = PreliminaryMessageResponse(op: .unsubscribed,
                                                               requestId: 1,
                                                               clientId: "yolo",
                                                               installationId: "naw")
            guard let encoded2 = try? ParseCoding.jsonEncoder().encode(response2) else {
                expectation2.fulfill()
                return
            }
            client.received(encoded2)
            XCTAssertEqual(client.pendingSubscriptions.count, 0)
            XCTAssertEqual(client.subscriptions.count, 0)
        }

        XCTAssertFalse(try client.isSubscribed(query))
        XCTAssertTrue(try client.isPendingSubscription(query))
        XCTAssertEqual(client.subscriptions.count, 0)
        XCTAssertEqual(client.pendingSubscriptions.count, 1)
        try pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        client.received(encoded)
        XCTAssertTrue(try client.isSubscribed(query))
        XCTAssertFalse(try client.isPendingSubscription(query))
        XCTAssertEqual(client.subscriptions.count, 1)
        XCTAssertEqual(client.pendingSubscriptions.count, 0)

        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testServerRedirectResponse() throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        try pretendToBeConnected()

        guard let url = URL(string: "http://parse.com") else {
            XCTFail("should create url")
            return
        }
        XCTAssertNotEqual(client.url, url)
        let response = RedirectResponse(op: .redirect, url: url)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        client.received(encoded)
        XCTAssertEqual(client.url, url)
    }

    func testServerErrorResponse() throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        let delegate = TestDelegate()
        client.receiveDelegate = delegate
        try pretendToBeConnected()
        XCTAssertNil(delegate.error)
        guard let url = URL(string: "http://parse.com") else {
            XCTFail("should create url")
            return
        }
        XCTAssertNotEqual(client.url, url)
        let response = ErrorResponse(op: .error, code: 1, error: "message", reconnect: true)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        client.received(encoded)
        let expectation1 = XCTestExpectation(description: "Response delegate")
        DispatchQueue.main.async {
            XCTAssertNotNil(delegate.error)
            XCTAssertEqual(delegate.error?.code, ParseError.Code.internalServer)
            XCTAssertTrue(delegate.error?.message.contains("message") != nil)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testServerErrorResponseNoReconnect() throws {
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        let delegate = TestDelegate()
        client.receiveDelegate = delegate
        try pretendToBeConnected()
        XCTAssertNil(delegate.error)
        guard let url = URL(string: "http://parse.com") else {
            XCTFail("should create url")
            return
        }
        XCTAssertNotEqual(client.url, url)
        let response = ErrorResponse(op: .error, code: 1, error: "message", reconnect: false)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        client.received(encoded)
        let expectation1 = XCTestExpectation(description: "Response delegate")
        DispatchQueue.main.async {
            XCTAssertNotNil(delegate.error)
            XCTAssertEqual(delegate.error?.code, ParseError.Code.internalServer)
            XCTAssertTrue(delegate.error?.message.contains("message") != nil)
            expectation1.fulfill()
        }
        let expectation2 = XCTestExpectation(description: "Client closed")
        client.synchronizationQueue.async {
            XCTAssertTrue(client.isDisconnectedByUser)
            XCTAssertFalse(client.isConnected)
            XCTAssertFalse(client.isConnecting)
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testEventEnter() throws {
        let query = GameScore.query("score" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(score: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        subscription.handleEvent { subscribedQuery, event in
            XCTAssertEqual(query, subscribedQuery)

            switch event {

            case .entered(let enter):
                XCTAssertEqual(enter, score)
            default:
                XCTFail("Should have receeived event")
            }
            expectation1.fulfill()
        }

        try pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        client.received(encoded)

        let response2 = EventResponse(op: .enter,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: "naw")
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        client.received(encoded2)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testEventLeave() throws {
        let query = GameScore.query("score" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(score: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        subscription.handleEvent { subscribedQuery, event in
            XCTAssertEqual(query, subscribedQuery)

            switch event {

            case .left(let enter):
                XCTAssertEqual(enter, score)
            default:
                XCTFail("Should have receeived event")
            }
            expectation1.fulfill()
        }

        try pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        client.received(encoded)

        let response2 = EventResponse(op: .leave,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: "naw")
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        client.received(encoded2)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testEventCreate() throws {
        let query = GameScore.query("score" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(score: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        subscription.handleEvent { subscribedQuery, event in
            XCTAssertEqual(query, subscribedQuery)

            switch event {

            case .created(let enter):
                XCTAssertEqual(enter, score)
            default:
                XCTFail("Should have receeived event")
            }
            expectation1.fulfill()
        }

        try pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        client.received(encoded)

        let response2 = EventResponse(op: .create,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: "naw")
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        client.received(encoded2)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testEventUpdate() throws {
        let query = GameScore.query("score" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(score: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        subscription.handleEvent { subscribedQuery, event in
            XCTAssertEqual(query, subscribedQuery)

            switch event {

            case .updated(let enter):
                XCTAssertEqual(enter, score)
            default:
                XCTFail("Should have receeived event")
            }
            expectation1.fulfill()
        }

        try pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        client.received(encoded)

        let response2 = EventResponse(op: .update,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: "naw")
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        client.received(encoded2)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testEventDelete() throws {
        let query = GameScore.query("score" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(score: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        subscription.handleEvent { subscribedQuery, event in
            XCTAssertEqual(query, subscribedQuery)

            switch event {

            case .deleted(let enter):
                XCTAssertEqual(enter, score)
            default:
                XCTFail("Should have receeived event")
            }
            expectation1.fulfill()
        }

        try pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        client.received(encoded)

        let response2 = EventResponse(op: .delete,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: "naw")
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        client.received(encoded2)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSubscriptionUpdate() throws {
        let query = GameScore.query("score" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Unsubscribe Handler")
        var count = 0
        subscription.handleSubscribe { subscribedQuery, isNew in
            XCTAssertEqual(query, subscribedQuery)
            if count == 0 {
                XCTAssertTrue(isNew)
                count += 1
                expectation1.fulfill()
            } else {
                XCTAssertFalse(isNew)
                XCTAssertEqual(client.subscriptions.count, 1)
                XCTAssertEqual(client.pendingSubscriptions.count, 0)
                expectation2.fulfill()
                return
            }

            //Update
            XCTAssertNotNil(try? query.update(subscription))

            guard let isSubscribed = try? client.isSubscribed(query),
                  let isPending = try? client.isPendingSubscription(query) else {
                XCTFail("Shound unwrap")
                return
            }
            XCTAssertTrue(isSubscribed)
            XCTAssertTrue(isPending)
            XCTAssertEqual(client.subscriptions.count, 1)
            XCTAssertEqual(client.pendingSubscriptions.count, 1)

            let response = PreliminaryMessageResponse(op: .subscribed,
                                                               requestId: 1,
                                                               clientId: "yolo",
                                                               installationId: "naw")
            guard let encoded = try? ParseCoding.jsonEncoder().encode(response) else {
                XCTFail("Should encode")
                return
            }
            client.received(encoded)
        }

        XCTAssertFalse(try client.isSubscribed(query))
        XCTAssertTrue(try client.isPendingSubscription(query))
        XCTAssertEqual(client.subscriptions.count, 0)
        XCTAssertEqual(client.pendingSubscriptions.count, 1)
        try pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        client.received(encoded)
        XCTAssertTrue(try client.isSubscribed(query))
        XCTAssertFalse(try client.isPendingSubscription(query))
        XCTAssertEqual(client.subscriptions.count, 1)
        XCTAssertEqual(client.pendingSubscriptions.count, 0)

        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testResubscribing() throws {
        let query = GameScore.query("score" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.getDefault() else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Unsubscribe Handler")
        var count = 0
        subscription.handleSubscribe { subscribedQuery, isNew in
            XCTAssertEqual(query, subscribedQuery)
            if count == 0 {
                XCTAssertTrue(isNew)
                count += 1
                expectation1.fulfill()
            } else {
                XCTAssertTrue(isNew)
                XCTAssertEqual(client.subscriptions.count, 1)
                XCTAssertEqual(client.pendingSubscriptions.count, 0)
                expectation2.fulfill()
                return
            }

            //Disconnect, subscriptions should remain the same
            client.isConnected = false
            XCTAssertEqual(client.subscriptions.count, 1)
            XCTAssertEqual(client.pendingSubscriptions.count, 0)

            //Connect moving to true should move to pending
            client.clientId = "naw"
            client.isConnected = true
            XCTAssertEqual(client.subscriptions.count, 0)
            XCTAssertEqual(client.pendingSubscriptions.count, 1)

            //Fake server response
            let response = PreliminaryMessageResponse(op: .subscribed,
                                                               requestId: 1,
                                                               clientId: "yolo",
                                                               installationId: "naw")
            guard let encoded = try? ParseCoding.jsonEncoder().encode(response) else {
                XCTFail("Should have encoded")
                return
            }
            client.received(encoded)
        }

        XCTAssertFalse(try client.isSubscribed(query))
        XCTAssertTrue(try client.isPendingSubscription(query))
        XCTAssertEqual(client.subscriptions.count, 0)
        XCTAssertEqual(client.pendingSubscriptions.count, 1)
        try pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        client.received(encoded)
        XCTAssertTrue(try client.isSubscribed(query))
        XCTAssertFalse(try client.isPendingSubscription(query))
        XCTAssertEqual(client.subscriptions.count, 1)
        XCTAssertEqual(client.pendingSubscriptions.count, 0)

        wait(for: [expectation1, expectation2], timeout: 20.0)
    }
}
#endif
