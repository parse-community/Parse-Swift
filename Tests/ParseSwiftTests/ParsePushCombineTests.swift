//
//  ParsePushCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/11/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class ParsePushCombineTests: XCTestCase {
    struct Installation: ParseInstallation {
        var installationId: String?
        var deviceType: String?
        var deviceToken: String?
        var badge: Int?
        var timeZone: String?
        var channels: [String]?
        var appName: String?
        var appIdentifier: String?
        var appVersion: String?
        var parseVersion: String?
        var localeIdentifier: String?
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?
        var customKey: String?

        //: Implement your own version of merge
        func merge(with object: Self) throws -> Self {
            var updated = try mergeParse(with: object)
            if updated.shouldRestoreKey(\.customKey,
                                         original: object) {
                updated.customKey = object.customKey
            }
            return updated
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
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testSend() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Send")

        let objectId = "yolo"
        let appleAlert = ParsePushAppleAlert(body: "hello world")

        let headers = ["X-Parse-Push-Status-Id": objectId]
        let results = BooleanResponse(result: true)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0, headerFields: headers)
            } catch {
                return nil
            }
        }

        let applePayload = ParsePushPayloadApple(alert: appleAlert)
        let push = ParsePush(payload: applePayload)
        let publisher = push.sendPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { pushStatus in

            XCTAssertEqual(pushStatus, objectId)
        })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testSendErrorServerReturnedFalse() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Send")

        let objectId = "yolo"
        let appleAlert = ParsePushAppleAlert(body: "hello world")

        let headers = ["X-Parse-Push-Status-Id": objectId]
        let results = BooleanResponse(result: false)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0, headerFields: headers)
            } catch {
                return nil
            }
        }

        let applePayload = ParsePushPayloadApple(alert: appleAlert)
        let push = ParsePush(payload: applePayload)
        let publisher = push.sendPublisher()
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    XCTFail("Should have thrown ParseError")
                case .failure(let error):
                    XCTAssertTrue(error.message.contains("unsuccessful"))
                }
                expectation1.fulfill()

        }, receiveValue: { _ in

            XCTFail("Should have thrown ParseError")
        })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testSendErrorTimeAndIntervalSet() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Send")

        let objectId = "yolo"
        let appleAlert = ParsePushAppleAlert(body: "hello world")

        let headers = ["X-Parse-Push-Status-Id": objectId]
        let results = BooleanResponse(result: true)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0, headerFields: headers)
            } catch {
                return nil
            }
        }

        let applePayload = ParsePushPayloadApple(alert: appleAlert)
        var push = ParsePush(payload: applePayload, expirationDate: Date())
        push.expirationInterval = 7
        let publisher = push.sendPublisher()
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    XCTFail("Should have thrown ParseError")
                case .failure(let error):
                    XCTAssertTrue(error.message.contains("expirationTime"))
                }
                expectation1.fulfill()

        }, receiveValue: { _ in

            XCTFail("Should have thrown ParseError")
        })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testSendErrorQueryAndChannelsSet() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Send")

        let objectId = "yolo"
        let appleAlert = ParsePushAppleAlert(body: "hello world")

        let headers = ["X-Parse-Push-Status-Id": objectId]
        let results = BooleanResponse(result: true)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0, headerFields: headers)
            } catch {
                return nil
            }
        }

        let applePayload = ParsePushPayloadApple(alert: appleAlert)
        let installationQuery = Installation.query(isNotNull(key: "objectId"))
        var push = ParsePush(payload: applePayload, query: installationQuery)
        push.channels = ["hello"]
        let publisher = push.sendPublisher()
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    XCTFail("Should have thrown ParseError")
                case .failure(let error):
                    XCTAssertTrue(error.message.contains("query"))
                }
                expectation1.fulfill()

        }, receiveValue: { _ in

            XCTFail("Should have thrown ParseError")
        })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testSendErrorServerReturnedWrongType() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Send")

        let objectId = "yolo"
        let appleAlert = ParsePushAppleAlert(body: "hello world")

        let headers = ["X-Parse-Push-Status-Id": objectId]
        let results = HealthResponse(status: "peace")
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0, headerFields: headers)
            } catch {
                return nil
            }
        }

        let applePayload = ParsePushPayloadApple(alert: appleAlert)
        let push = ParsePush(payload: applePayload)
        let publisher = push.sendPublisher()
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    XCTFail("Should have thrown ParseError")
                case .failure(let error):
                    XCTAssertTrue(error.message.contains("Boolean"))
                }
                expectation1.fulfill()

        }, receiveValue: { _ in

            XCTFail("Should have thrown ParseError")
        })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testSendErrorServerMissingHeader() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Send")

        let appleAlert = ParsePushAppleAlert(body: "hello world")

        let results = BooleanResponse(result: true)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let applePayload = ParsePushPayloadApple(alert: appleAlert)
        let push = ParsePush(payload: applePayload)
        let publisher = push.sendPublisher()
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    XCTFail("Should have thrown ParseError")
                case .failure(let error):
                    XCTAssertTrue(error.message.contains("X-Parse-Push-Status-Id"))
                }
                expectation1.fulfill()

        }, receiveValue: { _ in

            XCTFail("Should have thrown ParseError")
        })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetch() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Send")

        let objectId = "yolo"
        let appleAlert = ParsePushAppleAlert(body: "hello world")
        var anyPayload = ParsePushPayloadAny()
        anyPayload.alert = appleAlert
        var statusOnServer = ParsePushStatus<ParsePushPayloadAny>()
        statusOnServer.payload = anyPayload
        statusOnServer.objectId = objectId
        statusOnServer.createdAt = Date()
        statusOnServer.updatedAt = statusOnServer.createdAt

        let results = QueryResponse<ParsePushStatus<ParsePushPayloadAny>>(results: [statusOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let applePayload = ParsePushPayloadApple(alert: appleAlert)
        let push = ParsePush(payload: applePayload)
        let publisher = push.fetchStatusPublisher(objectId)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { found in

            XCTAssert(found.hasSameObjectId(as: statusOnServer))
            XCTAssertEqual(found.payload, anyPayload.convertToApple())
        })
        publisher.store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }
}
#endif
