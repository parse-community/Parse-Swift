//
//  ParsePushTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/11/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

/**
 For testing _PushStatus response of at least Parse Server 5.2.1 and below.
 - warning: This struct should be kept inline with `ParsePushStatus`
 so tests do not break.
*/
internal struct ParsePushStatusResponse: ParseObject {

    var originalData: Data?

    var objectId: String?

    var createdAt: Date?

    var updatedAt: Date?

    var ACL: ParseACL?

    var query: String?

    var pushTime: Date?

    var source: String?

    var payload: String?

    var title: String?

    var expiry: Int?

    var expirationInterval: String?

    var status: String?

    var numSent: Int?

    var numFailed: Int?

    var pushHash: String?

    var errorMessage: ParseError?

    var sentPerType: [String: Int]?

    var failedPerType: [String: Int]?

    var sentPerUTCOffset: [String: Int]?

    var failedPerUTCOffset: [String: Int]?

    var count: Int?

    init() { }

    func setQueryWhere(_ query: QueryWhere) throws -> Self {
        var mutatingResponse = self
        let whereData = try ParseCoding.jsonEncoder().encode(query)
        guard let whereString = String(data: whereData, encoding: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have created String")
        }
        mutatingResponse.query = whereString
        return mutatingResponse
    }

    func setPayload<V: ParsePushPayloadable>(_ payload: V) throws -> Self {
        var mutatingResponse = self
        let payloadData = try ParseCoding.jsonEncoder().encode(payload)
        guard let payloadString = String(data: payloadData, encoding: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have created String")
        }
        mutatingResponse.payload = payloadString
        return mutatingResponse
    }

    enum CodingKeys: String, CodingKey {
        case expirationInterval = "expiration_interval"
        case objectId, createdAt, updatedAt, ACL
        case count, failedPerUTCOffset, sentPerUTCOffset,
             sentPerType, failedPerType, errorMessage, pushHash,
             numFailed, numSent, status, expiry, title, source,
             pushTime, query, payload
    }
}

class ParsePushTests: XCTestCase {

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

    func testInitializers() throws {
        let applePayload = ParsePushPayloadApple(body: "Hello from ParseSwift!")
        let fcmPayload = ParsePushPayloadFirebase(notification: .init(body: "Bye FCM"))
        let installationQuery = Installation.query(isNotNull(key: "objectId"))

        let push = ParsePush(payload: applePayload)
        XCTAssertEqual(push.debugDescription,
                       "{\"data\":{\"alert\":{\"body\":\"Hello from ParseSwift!\"},\"push_type\":\"alert\"}}")
        let push2 = ParsePush(payload: applePayload, query: installationQuery)
        XCTAssertEqual(push2.debugDescription,
                       // swiftlint:disable:next line_length
                       "{\"data\":{\"alert\":{\"body\":\"Hello from ParseSwift!\"},\"push_type\":\"alert\"},\"where\":{\"objectId\":{\"$ne\":null}}}")
        let push3 = ParsePush(payload: applePayload, expirationInterval: 7)
        XCTAssertEqual(push3.debugDescription,
                       // swiftlint:disable:next line_length
                       "{\"data\":{\"alert\":{\"body\":\"Hello from ParseSwift!\"},\"push_type\":\"alert\"},\"expiration_interval\":7}")
        let push4 = ParsePush(payload: fcmPayload)
        XCTAssertEqual(push4.debugDescription,
                       "{\"data\":{\"notification\":{\"body\":\"Bye FCM\"}}}")
        let push5 = ParsePush(payload: fcmPayload, query: installationQuery)
        XCTAssertEqual(push5.debugDescription,
                       "{\"data\":{\"notification\":{\"body\":\"Bye FCM\"}},\"where\":{\"objectId\":{\"$ne\":null}}}")
        let push6 = ParsePush(payload: fcmPayload, query: installationQuery, expirationInterval: 7)
        XCTAssertEqual(push6.debugDescription,
                       // swiftlint:disable:next line_length
                       "{\"data\":{\"notification\":{\"body\":\"Bye FCM\"}},\"expiration_interval\":7,\"where\":{\"objectId\":{\"$ne\":null}}}")
    }

    func testChannels() throws {
        let currentDate = Date()
        let currentDateInterval = currentDate.timeIntervalSince1970
        let currentDateData = try ParseCoding.jsonEncoder().encode(currentDateInterval)
        guard let currentDateString = String(data: currentDateData, encoding: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let fcmPayload = ParsePushPayloadFirebase(notification: .init(body: "Bye FCM"))
        var push = ParsePush(payload: fcmPayload, expirationDate: currentDate)
        push.channels = ["hello"]
        XCTAssertEqual(push.description,
                       // swiftlint:disable:next line_length
                       "{\"channels\":[\"hello\"],\"data\":{\"notification\":{\"body\":\"Bye FCM\"}},\"expiration_time\":\(currentDateString)}")
        guard let pushDate = push.expirationDate else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertLessThan(pushDate.timeIntervalSince(currentDate), 1)
        push.expirationTime = nil
        XCTAssertNil(push.expirationDate)
    }
}
