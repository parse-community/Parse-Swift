//
//  ParsePushAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/11/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParsePushAsyncTests: XCTestCase {
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
                              masterKey: "masterKey",
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

    @MainActor
    func testSend() async throws {
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
        let push = ParsePush<Installation, ParsePushPayloadApple>(payload: applePayload)
        let pushStatus = try await push.send()
        XCTAssertEqual(pushStatus, objectId)
    }

    @MainActor
    func testSendErrorServerReturnedFalse() async throws {
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
        let push = ParsePush<Installation, ParsePushPayloadApple>(payload: applePayload)
        do {
            _ = try await push.send()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("unsuccessful"))
        }
    }

    @MainActor
    func testSendErrorTimeAndIntervalSet() async throws {
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
        var push = ParsePush<Installation, ParsePushPayloadApple>(payload: applePayload, expirationTime: Date())
        push.expirationInterval = 7
        do {
            _ = try await push.send()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("expirationTime"))
        }
    }

    @MainActor
    func testSendErrorQueryAndChannelsSet() async throws {
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
        var push = ParsePush<Installation, ParsePushPayloadApple>(payload: applePayload, query: installationQuery)
        push.channels = ["hello"]
        do {
            _ = try await push.send()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("query"))
        }
    }

    @MainActor
    func testSendErrorServerReturnedWrongType() async throws {
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
        let push = ParsePush<Installation, ParsePushPayloadApple>(payload: applePayload)
        do {
            _ = try await push.send()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("Boolean"))
        }
    }

    @MainActor
    func testSendErrorServerMissingHeader() async throws {
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
        let push = ParsePush<Installation, ParsePushPayloadApple>(payload: applePayload)
        do {
            _ = try await push.send()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("X-Parse-Push-Status-Id"))
        }
    }

    @MainActor
    func testSendErrorServerMissingHeaderBodyFalse() async throws {
        let appleAlert = ParsePushAppleAlert(body: "hello world")

        let results = BooleanResponse(result: false)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let applePayload = ParsePushPayloadApple(alert: appleAlert)
        let push = ParsePush<Installation, ParsePushPayloadApple>(payload: applePayload)
        do {
            _ = try await push.send()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("X-Parse-Push-Status-Id"))
        }
    }

    @MainActor
    func testFetch() async throws {
        let objectId = "yolo"
        let appleAlert = ParsePushAppleAlert(body: "hello world")
        var anyPayload = ParsePushPayloadAny()
        anyPayload.alert = appleAlert
        var statusOnServer = ParsePushStatus<Installation, ParsePushPayloadAny>()
        statusOnServer.payload = anyPayload
        statusOnServer.objectId = objectId
        statusOnServer.createdAt = Date()
        statusOnServer.updatedAt = statusOnServer.createdAt

        // swiftlint:disable:next line_length
        let results = QueryResponse<ParsePushStatus<Installation, ParsePushPayloadAny>>(results: [statusOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let applePayload = ParsePushPayloadApple(alert: appleAlert)
        let push = ParsePush<Installation, ParsePushPayloadApple>(payload: applePayload)
        let found = try await push.fetchStatus(objectId)
        XCTAssert(found.hasSameObjectId(as: statusOnServer))
        XCTAssertEqual(found.payload, anyPayload.convertToApple())
    }
}
#endif
