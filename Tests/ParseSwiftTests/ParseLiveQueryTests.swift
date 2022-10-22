//
//  ParseLiveQueryTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/3/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//
#if !os(Linux) && !os(Android) && !os(Windows)
import Foundation
import XCTest
@testable import ParseSwift

class ParseLiveQueryTests: XCTestCase {
    struct GameScore: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int = 0

        //custom initializer
        init() {}

        init(points: Int) {
            self.points = points
        }

        init(objectId: String?) {
            self.objectId = objectId
        }
    }

    class TestDelegate: ParseLiveQueryDelegate {
        var error: ParseError?
        var code: URLSessionWebSocketTask.CloseCode?
        var reason: Data?
        func received(_ error: Error) {
            if let error = error as? ParseError {
                self.error = error
            }
        }
        func closedSocket(_ code: URLSessionWebSocketTask.CloseCode?, reason: Data?) {
            self.code = code
            self.reason = reason
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
                              primaryKey: "primaryKey",
                              serverURL: url,
                              testing: true)
        ParseLiveQuery.setDefault(try ParseLiveQuery(isDefault: true))
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

    func testWebsocketURL() throws {
        guard let originalURL = URL(string: "http://localhost:1337/1"),
            var components = URLComponents(url: originalURL,
                                             resolvingAgainstBaseURL: false) else {
            XCTFail("Should have retrieved URL components")
            return
        }
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"
        let webSocketURL = components.url

        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }

        XCTAssertEqual(client.url, webSocketURL)
        XCTAssertTrue(client.url.absoluteString.contains("ws"))

        let expectation1 = XCTestExpectation(description: "Socket delegate")
        client.synchronizationQueue.asyncAfter(deadline: .now() + 2) {
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
            XCTFail("Should have retrieved URL components")
            return
        }
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"
        let webSocketURL = components.url

        guard let client = try? ParseLiveQuery(serverURL: originalURL),
              let defaultClient = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to initialize a new client")
            return
        }

        XCTAssertEqual(client.url, webSocketURL)
        XCTAssertTrue(client.url.absoluteString.contains("ws"))
        XCTAssertNotEqual(client, defaultClient)
        let expectation1 = XCTestExpectation(description: "Socket delegate")
        client.synchronizationQueue.asyncAfter(deadline: .now() + 2) {
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
        client.synchronizationQueue.asyncAfter(deadline: .now() + 2) {
            let socketDelegates = URLSession.liveQuery.delegates
            XCTAssertNotNil(socketDelegates[client.task])
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeinitializingNewShouldNotEffectDefault() throws {
        guard let defaultClient = ParseLiveQuery.defaultClient else {
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
        XCTAssertNotNil(ParseLiveQuery.defaultClient)
        let expectation1 = XCTestExpectation(description: "Socket delegate")
        defaultClient.synchronizationQueue.asyncAfter(deadline: .now() + 2) {
            let socketDelegates = URLSession.liveQuery.delegates
            XCTAssertNotNil(socketDelegates[defaultClient.task])
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testBecomingSocketAuthDelegate() throws {
        let delegate = TestDelegate()
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertNil(URLSession.liveQuery.authenticationDelegate)
        client.authenticationDelegate = delegate
        guard let authDelegate = URLSession
                .liveQuery
                .authenticationDelegate as? ParseLiveQuery else {
            XCTFail("Should be able to cast")
            return
        }
        XCTAssertEqual(client, authDelegate)
        XCTAssertNotNil(URLSession.liveQuery.authenticationDelegate)
        client.authenticationDelegate = nil
        XCTAssertNil(URLSession.liveQuery.authenticationDelegate)
    }

    func testStandardMessageEncoding() throws {
        guard let installationId = BaseParseInstallation.currentContainer.installationId else {
            XCTFail("Should have installationId")
            return
        }
        // swiftlint:disable:next line_length
        let expected = "{\"applicationId\":\"applicationId\",\"clientKey\":\"clientKey\",\"installationId\":\"\(installationId)\",\"masterKey\":\"primaryKey\",\"op\":\"connect\"}"
        let message = StandardMessage(operation: .connect, additionalProperties: true)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testSubscribeMessageFieldsEncoding() throws {
        // swiftlint:disable:next line_length
        let expected = "{\"op\":\"subscribe\",\"query\":{\"className\":\"GameScore\",\"fields\":[\"points\"],\"where\":{\"points\":{\"$gt\":9}}},\"requestId\":1}"
        let query = GameScore.query("points" > 9)
            .fields(["points"])
            .select(["talk"])
        let message = SubscribeMessage(operation: .subscribe,
                                       requestId: RequestId(value: 1),
                                       query: query,
                                       additionalProperties: true)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testSubscribeMessageSelectEncoding() throws {
        // swiftlint:disable:next line_length
        let expected = "{\"op\":\"subscribe\",\"query\":{\"className\":\"GameScore\",\"fields\":[\"points\"],\"where\":{\"points\":{\"$gt\":9}}},\"requestId\":1}"
        let query = GameScore.query("points" > 9)
            .select(["points"])
        let message = SubscribeMessage(operation: .subscribe,
                                       requestId: RequestId(value: 1),
                                       query: query,
                                       additionalProperties: true)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testFieldKeys() throws {
        let query = GameScore.query
        XCTAssertNil(query.keys)

        var query2 = GameScore.query.fields(["yolo"])
        XCTAssertEqual(query2.fields?.count, 1)
        XCTAssertEqual(query2.fields?.first, "yolo")

        query2 = query2.fields(["hello", "wow"])
        XCTAssertEqual(query2.fields?.count, 3)
        XCTAssertEqual(query2.fields, ["yolo", "hello", "wow"])
    }

    func testFieldKeysVariadic() throws {
        let query = GameScore.query
        XCTAssertNil(query.keys)

        var query2 = GameScore.query.fields("yolo")
        XCTAssertEqual(query2.fields?.count, 1)
        XCTAssertEqual(query2.fields?.first, "yolo")

        query2 = query2.fields("hello", "wow")
        XCTAssertEqual(query2.fields?.count, 3)
        XCTAssertEqual(query2.fields, ["yolo", "hello", "wow"])
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
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testConnectionResponseDecoding() throws {
        let expected = "{\"clientId\":\"yolo\",\"installationId\":\"naw\",\"op\":\"connected\"}"
        let message = ConnectionResponse(op: .connected, clientId: "yolo", installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testUnsubscribeResponseDecoding() throws {
        let expected = "{\"clientId\":\"yolo\",\"installationId\":\"naw\",\"op\":\"connected\",\"requestId\":1}"
        let message = UnsubscribedResponse(op: .connected, requestId: 1, clientId: "yolo", installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testEventResponseDecoding() throws {
        // swiftlint:disable:next line_length
        let expected = "{\"clientId\":\"yolo\",\"installationId\":\"naw\",\"object\":{\"points\":10},\"op\":\"connected\",\"requestId\":1}"
        let score = GameScore(points: 10)
        let message = EventResponse(op: .connected,
                                    requestId: 1,
                                    object: score,
                                    clientId: "yolo",
                                    installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testErrorResponseDecoding() throws {
        let expected = "{\"code\":1,\"error\":\"message\",\"op\":\"error\",\"reconnect\":true}"
        let message = ErrorResponse(op: .error, code: 1, message: "message", reconnect: true)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testPreliminaryResponseDecoding() throws {
        let expected = "{\"clientId\":\"message\",\"installationId\":\"naw\",\"op\":\"subscribed\",\"requestId\":1}"
        let message = PreliminaryMessageResponse(op: .subscribed,
                                                 requestId: 1,
                                                 clientId: "message",
                                                 installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testSocketNotOpenState() throws {
        guard let client = ParseLiveQuery.defaultClient else {
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
        guard let client = ParseLiveQuery.defaultClient,
              let task = client.task else {
            XCTFail("Should be able to get client and task")
            return
        }
        client.isSocketEstablished = true // Socket needs to be true
        client.isConnecting = true
        client.isConnected = true
        client.attempts = 5
        client.clientId = "yolo"
        client.isDisconnectedByUser = false
        // Only continue test if this is not nil, otherwise skip
        guard let receivingTask = URLSession.liveQuery.receivingTasks[task] else {
            throw XCTSkip("Skip this test when the receiving task is nil")
        }
        XCTAssertEqual(receivingTask, true)
        XCTAssertEqual(client.isSocketEstablished, true)
        XCTAssertEqual(client.isConnecting, false)
        XCTAssertEqual(client.clientId, "yolo")
        XCTAssertEqual(client.attempts, 5)

        // Test too many attempts and close
        client.isSocketEstablished = true // Socket needs to be true
        client.isConnecting = true
        client.isConnected = true
        client.attempts = ParseLiveQueryConstants.maxConnectionAttempts + 1
        client.clientId = "yolo"
        client.isDisconnectedByUser = false

        XCTAssertEqual(client.isSocketEstablished, false)
        XCTAssertEqual(client.isConnecting, false)
        XCTAssertEqual(client.clientId, "yolo")
        XCTAssertEqual(client.attempts, ParseLiveQueryConstants.maxConnectionAttempts + 1)
    }

    func testDisconnectedState() throws {
        guard let client = ParseLiveQuery.defaultClient,
              let task = client.task else {
            XCTFail("Should be able to get client and task")
            return
        }
        client.isSocketEstablished = true // Socket needs to be true
        client.isConnecting = true
        client.isConnected = true
        client.clientId = "yolo"
        // Only continue test if this is not nil, otherwise skip
        guard let receivingTask = URLSession.liveQuery.receivingTasks[task] else {
            throw XCTSkip("Skip this test when the receiving task is nil")
        }
        XCTAssertEqual(receivingTask, true)
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
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        client.isSocketEstablished = true // Socket needs to be true
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
        guard let client = ParseLiveQuery.defaultClient else {
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

        XCTAssertEqual(client.isSocketEstablished, false)
        XCTAssertEqual(client.isConnected, false)
        XCTAssertEqual(client.isConnecting, false)
        XCTAssertNil(client.clientId)
        XCTAssertEqual(client.isDisconnectedByUser, true)
    }

    func testOpenSocket() throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        client.close()
        let expectation1 = XCTestExpectation(description: "Response delegate")
        client.open(isUserWantsToConnect: true) { error in
            XCTAssertNotNil(error) //Should always fail since WS is not intercepted.
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testCloseFromServer() throws {
        guard let client = ParseLiveQuery.defaultClient else {
            throw ParseError(code: .unknownError,
                             message: "Should be able to get client")
        }
        let delegate = TestDelegate()
        client.receiveDelegate = delegate
        client.task = URLSession.liveQuery.createTask(client.url,
                                                      taskDelegate: client)
        // Only continue test if this is not nil, otherwise skip
        guard let receivingTask = URLSession.liveQuery.receivingTasks[client.task] else {
            throw XCTSkip("Skip this test when the receiving task is nil")
        }
        XCTAssertEqual(receivingTask, true)
        client.status(.closed, closeCode: .goingAway, reason: nil)
        let expectation1 = XCTestExpectation(description: "Response delegate")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(delegate.code, .goingAway)
            XCTAssertNil(delegate.reason)
            XCTAssertTrue(client.task.state == .completed)
            XCTAssertNil(URLSession.liveQuery.receivingTasks[client.task])
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testCloseExternal() throws {
        let client = try ParseLiveQuery()
        guard let originalTask = client.task,
              client.task.state == .running else {
            throw XCTSkip("Skip this test when state is not running")
        }
        // Only continue test if this is not nil, otherwise skip
        guard let receivingTask = URLSession.liveQuery.receivingTasks[client.task] else {
            throw XCTSkip("Skip this test when the receiving task is nil")
        }
        XCTAssertEqual(receivingTask, true)
        client.isSocketEstablished = true
        client.isConnected = true
        client.close()
        let expectation1 = XCTestExpectation(description: "Close external")
        client.synchronizationQueue.asyncAfter(deadline: .now() + 2) {
            XCTAssertTrue(client.task.state == .suspended)
            XCTAssertFalse(client.isSocketEstablished)
            XCTAssertFalse(client.isConnected)
            XCTAssertNil(URLSession.liveQuery.delegates[originalTask])
            XCTAssertNil(URLSession.liveQuery.receivingTasks[originalTask])
            XCTAssertNotNil(URLSession.liveQuery.delegates[client.task])
            XCTAssertEqual(URLSession.liveQuery.receivingTasks[client.task], true)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testCloseInternalUseQueue() throws {
        let client = try ParseLiveQuery()
        guard let originalTask = client.task,
              client.task.state == .running else {
            throw XCTSkip("Skip this test when state is not running")
        }
        // Only continue test if this is not nil, otherwise skip
        guard let receivingTask = URLSession.liveQuery.receivingTasks[client.task] else {
            throw XCTSkip("Skip this test when the receiving task is nil")
        }
        XCTAssertEqual(receivingTask, true)
        client.isSocketEstablished = true
        client.isConnected = true
        client.close(useDedicatedQueue: true)
        let expectation1 = XCTestExpectation(description: "Close internal")
        client.synchronizationQueue.asyncAfter(deadline: .now() + 2) {
            XCTAssertTrue(client.task.state == .suspended)
            XCTAssertFalse(client.isSocketEstablished)
            XCTAssertFalse(client.isConnected)
            XCTAssertNil(URLSession.liveQuery.delegates[originalTask])
            XCTAssertNil(URLSession.liveQuery.receivingTasks[originalTask])
            XCTAssertNotNil(URLSession.liveQuery.delegates[client.task])
            XCTAssertEqual(URLSession.liveQuery.receivingTasks[client.task], true)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testCloseInternalDoNotUseQueue() throws {
        let client = try ParseLiveQuery()
        guard let originalTask = client.task,
              client.task.state == .running else {
            throw XCTSkip("Skip this test when state is not running")
        }
        // Only continue test if this is not nil, otherwise skip
        guard let receivingTask = URLSession.liveQuery.receivingTasks[client.task] else {
            throw XCTSkip("Skip this test when the receiving task is nil")
        }
        XCTAssertEqual(receivingTask, true)
        client.isSocketEstablished = true
        client.isConnected = true
        client.close(useDedicatedQueue: false)
        XCTAssertTrue(client.task.state == .suspended)
        XCTAssertFalse(client.isSocketEstablished)
        XCTAssertFalse(client.isConnected)
        XCTAssertNil(URLSession.liveQuery.delegates[originalTask])
        XCTAssertNil(URLSession.liveQuery.receivingTasks[originalTask])
        XCTAssertNotNil(URLSession.liveQuery.delegates[client.task])
        XCTAssertEqual(URLSession.liveQuery.receivingTasks[client.task], true)
    }

    func testCloseAll() throws {
        let client = try ParseLiveQuery()
        guard let originalTask = client.task,
              client.task.state == .running else {
            throw XCTSkip("Skip this test when state is not running")
        }
        // Only continue test if this is not nil, otherwise skip
        guard let receivingTask = URLSession.liveQuery.receivingTasks[client.task] else {
            throw XCTSkip("Skip this test when the receiving task is nil")
        }
        XCTAssertEqual(receivingTask, true)
        client.isSocketEstablished = true
        client.isConnected = true
        client.closeAll()
        let expectation1 = XCTestExpectation(description: "Close all")
        client.synchronizationQueue.asyncAfter(deadline: .now() + 2) {
            XCTAssertTrue(client.task.state == .suspended)
            XCTAssertFalse(client.isSocketEstablished)
            XCTAssertFalse(client.isConnected)
            XCTAssertNil(URLSession.liveQuery.delegates[originalTask])
            XCTAssertNil(URLSession.liveQuery.receivingTasks[originalTask])
            XCTAssertNotNil(URLSession.liveQuery.delegates[client.task])
            XCTAssertEqual(URLSession.liveQuery.receivingTasks[client.task], true)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testPingSocketNotEstablished() throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        client.close()
        let expectation1 = XCTestExpectation(description: "Send Ping")
        client.sendPing { error in
            XCTAssertEqual(client.isSocketEstablished, false)
            guard let urlError = error as? URLError else {
                XCTFail("Should have casted to ParseError.")
                expectation1.fulfill()
                return
            }
            // "Could not connect to the server"
            // because webSocket connections are not intercepted.
            XCTAssertTrue([-1004, -1022].contains(urlError.errorCode))
            expectation1.fulfill()
        }
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

        let expectation1 = XCTestExpectation(description: "Send Ping")
        client.sendPing { error in
            XCTAssertEqual(client.isSocketEstablished, true)
            XCTAssertNotNil(error) // Should have error because testcases do not intercept websocket
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testRandomIdGenerator() throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        for index in 1 ..< 50 {
            let idGenerated = client.requestIdGenerator()
            XCTAssertEqual(idGenerated.value, index)
        }
    }

    func testSubscribeNotConnected() throws {
        let query = GameScore.query("points" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.defaultClient else {
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
        guard let client = ParseLiveQuery.defaultClient else {
            throw ParseError(code: .unknownError,
                             message: "Should be able to get client")
        }
        client.task = URLSession.liveQuery.createTask(client.url,
                                                      taskDelegate: client)
        client.status(.open)
        let response = ConnectionResponse(op: .connected, clientId: "yolo", installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        client.received(encoded)
        // Only continue test if this is not nil, otherwise skip
        guard let receivingTask = URLSession.liveQuery.receivingTasks[client.task],
            receivingTask == true else {
            throw XCTSkip("Skip this test when the receiving task is nil or not true")
        }
    }

    func testSubscribeConnected() throws {
        let query = GameScore.query("points" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Unsubscribe Handler")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {

            guard let subscribed = subscription.subscribed else {
                XCTFail("Should unwrap subscribed.")
                expectation1.fulfill()
                expectation2.fulfill()
                return
            }
            XCTAssertEqual(query, subscribed.query)
            XCTAssertTrue(subscribed.isNew)
            XCTAssertNil(subscription.unsubscribed)
            XCTAssertNil(subscription.event)

            //Unsubscribe
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                guard let unsubscribed = subscription.unsubscribed else {
                    XCTFail("Should unwrap unsubscribed.")
                    expectation2.fulfill()
                    return
                }
                XCTAssertEqual(query, unsubscribed)
                XCTAssertNil(subscription.subscribed)
                XCTAssertNil(subscription.event)
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
                XCTFail("Should have encoded second response")
                expectation2.fulfill()
                return
            }
            client.received(encoded2)
            XCTAssertEqual(client.pendingSubscriptions.count, 0)
            XCTAssertEqual(client.subscriptions.count, 0)
            expectation1.fulfill()
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

    func testSubscribeCallbackConnected() throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let subscription = try Query<GameScore>.subscribe(handler)

        guard let client = ParseLiveQuery.defaultClient else {
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
                XCTAssertTrue(client.pendingSubscriptions.isEmpty)
                XCTAssertTrue(client.subscriptions.isEmpty)
                XCTAssertFalse(client.isSocketEstablished)
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
                XCTFail("Should have encoded second response")
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

    func testSubscribeCloseSubscribe() throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        var subscription = try Query<GameScore>.subscribe(handler)

        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Resubscribe Handler")
        var count = 0
        var originalTask: URLSessionWebSocketTask?
        subscription.handleSubscribe { subscribedQuery, isNew in
            XCTAssertEqual(query, subscribedQuery)
            if count == 0 {
                XCTAssertTrue(isNew)
                XCTAssertEqual(client.pendingSubscriptions.count, 0)
                XCTAssertEqual(client.subscriptions.count, 1)
                XCTAssertNotNil(ParseLiveQuery.client?.task)
                originalTask = ParseLiveQuery.client?.task
                expectation1.fulfill()
            } else {
                XCTAssertNotNil(ParseLiveQuery.client?.task)
                XCTAssertFalse(originalTask == ParseLiveQuery.client?.task)
                expectation2.fulfill()
                return
            }

            ParseLiveQuery.client?.close()
            ParseLiveQuery.client?.synchronizationQueue.sync {
            if let socketEstablished = ParseLiveQuery.client?.isSocketEstablished {
                XCTAssertFalse(socketEstablished)
            } else {
                XCTFail("Should have socket that is not established")
                expectation2.fulfill()
                return
            }

            //Resubscribe
            do {
                count += 1
                subscription = try Query<GameScore>.subscribe(handler)
            } catch {
                XCTFail("\(error)")
                expectation2.fulfill()
                return
            }

            try? self.pretendToBeConnected()
            let response2 = PreliminaryMessageResponse(op: .subscribed,
                                                       requestId: 2,
                                                       clientId: "yolo",
                                                       installationId: "naw")
            guard let encoded2 = try? ParseCoding.jsonEncoder().encode(response2) else {
                XCTFail("Should have encoded second response")
                expectation2.fulfill()
                return
            }
            client.received(encoded2)
            }
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
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }

        guard let url = URL(string: "wss://parse.com") else {
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
        guard let client = ParseLiveQuery.defaultClient else {
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
        let response = ErrorResponse(op: .error, code: 1, message: "message", reconnect: true)
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
        guard let client = ParseLiveQuery.defaultClient else {
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
        let response = ErrorResponse(op: .error, code: 1, message: "message", reconnect: false)
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
        client.synchronizationQueue.asyncAfter(deadline: .now() + 2) {
            XCTAssertTrue(client.isDisconnectedByUser)
            XCTAssertFalse(client.isConnected)
            XCTAssertFalse(client.isConnecting)
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testEventEnter() throws {
        let query = GameScore.query("points" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let event = subscription.event else {
                XCTFail("Should unwrap")
                expectation1.fulfill()
                return
            }
            XCTAssertEqual(query, event.query)
            XCTAssertNil(subscription.subscribed)
            XCTAssertNil(subscription.unsubscribed)

            switch event.event {

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
        let query = GameScore.query("points" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let event = subscription.event else {
                XCTFail("Should unwrap")
                expectation1.fulfill()
                return
            }
            XCTAssertEqual(query, event.query)
            XCTAssertNil(subscription.subscribed)
            XCTAssertNil(subscription.unsubscribed)

            switch event.event {

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
        let query = GameScore.query("points" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let event = subscription.event else {
                XCTFail("Should unwrap")
                expectation1.fulfill()
                return
            }
            XCTAssertEqual(query, event.query)
            XCTAssertNil(subscription.subscribed)
            XCTAssertNil(subscription.unsubscribed)

            switch event.event {

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
        let query = GameScore.query("points" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)
        XCTAssertNil(subscription.subscribed)
        XCTAssertNil(subscription.unsubscribed)

        let score = GameScore(points: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let event = subscription.event else {
                XCTFail("Should unwrap")
                expectation1.fulfill()
                return
            }
            XCTAssertEqual(query, event.query)

            switch event.event {

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
        let query = GameScore.query("points" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let event = subscription.event else {
                XCTFail("Should unwrap")
                expectation1.fulfill()
                return
            }
            XCTAssertEqual(query, event.query)
            XCTAssertNil(subscription.subscribed)
            XCTAssertNil(subscription.unsubscribed)

            switch event.event {

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
        let query = GameScore.query("points" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)
        XCTAssertNil(subscription.event)
        XCTAssertNil(subscription.unsubscribed)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Unsubscribe Handler")
        var count = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let subscribed = subscription.subscribed else {
                XCTFail("Should unwrap")
                expectation1.fulfill()
                expectation2.fulfill()
                return
            }

            XCTAssertEqual(query, subscribed.query)
            if count == 0 {
                XCTAssertTrue(subscribed.isNew)
                count += 1
                expectation1.fulfill()
            }

            //Update
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                guard let subscribed = subscription.subscribed else {
                    XCTFail("Should unwrap")
                    expectation2.fulfill()
                    return
                }

                XCTAssertFalse(subscribed.isNew)
                XCTAssertEqual(client.subscriptions.count, 1)
                XCTAssertEqual(client.pendingSubscriptions.count, 0)
                expectation2.fulfill()
                return
            }
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
        let query = GameScore.query("points" > 9)
        guard let subscription = query.subscribe else {
            XCTFail("Should create subscription")
            return
        }
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Unsubscribe Handler")
        var count = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let subscribed = subscription.subscribed else {
                XCTFail("Should unwrap")
                expectation1.fulfill()
                expectation2.fulfill()
                return
            }
            if count == 0 {
                XCTAssertTrue(subscribed.isNew)
                XCTAssertNil(subscription.event)
                XCTAssertNil(subscription.unsubscribed)
                count += 1
                expectation1.fulfill()
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

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                guard let subscribed = subscription.subscribed else {
                    XCTFail("Should unwrap")
                    expectation2.fulfill()
                    return
                }

                XCTAssertTrue(subscribed.isNew)
                XCTAssertNil(subscription.event)
                XCTAssertNil(subscription.unsubscribed)
                XCTAssertEqual(client.subscriptions.count, 1)
                XCTAssertEqual(client.pendingSubscriptions.count, 0)
                expectation2.fulfill()
                return
            }

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

    func testEventEnterSubscriptionCallback() throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let subscription = try Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
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

    func testEventLeaveSubscriptioinCallback() throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let subscription = try Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
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

    func testEventCreateSubscriptionCallback() throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let subscription = try Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
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

    func testEventUpdateSubscriptionCallback() throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let subscription = try Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
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

    func testEventDeleteSubscriptionCallback() throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let subscription = try Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
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

    func testSubscriptionUpdateSubscriptionCallback() throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let subscription = try Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
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
                expectation1.fulfill()
                expectation2.fulfill()
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
                expectation1.fulfill()
                expectation2.fulfill()
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

    func testResubscribingSubscriptionCallback() throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let subscription = try Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
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
                expectation1.fulfill()
                expectation2.fulfill()
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
