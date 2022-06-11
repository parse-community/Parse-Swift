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

    func testInitializers() throws {
        let applePayload = ParsePushPayloadApple(body: "Hello from ParseSwift!")
        let fcmPayload = ParsePushPayloadFirebase(notification: .init(body: "Bye FCM"))
        let installationQuery = Installation.query(isNotNull(key: "objectId"))

        let push = ParsePush<Installation, ParsePushPayloadApple>(payload: applePayload)
        XCTAssertEqual(push.debugDescription,
                       // swiftlint:disable:next line_length
                       "ParsePush ({\"data\":{\"alert\":{\"body\":\"Hello from ParseSwift!\"},\"push_type\":\"alert\"}})")
        let push2 = ParsePush(payload: applePayload, query: installationQuery)
        XCTAssertEqual(push2.debugDescription,
                       // swiftlint:disable:next line_length
                       "ParsePush ({\"data\":{\"alert\":{\"body\":\"Hello from ParseSwift!\"},\"push_type\":\"alert\"},\"where\":{\"objectId\":{\"$ne\":null}}})")
        let push3 = ParsePush<Installation, ParsePushPayloadApple>(payload: applePayload, expirationInterval: 7)
        XCTAssertEqual(push3.debugDescription,
                       // swiftlint:disable:next line_length
                       "ParsePush ({\"data\":{\"alert\":{\"body\":\"Hello from ParseSwift!\"},\"push_type\":\"alert\"},\"expiration_interval\":7})")
        let push4 = ParsePush<Installation, ParsePushPayloadFirebase>(payload: fcmPayload)
        XCTAssertEqual(push4.debugDescription,
                       "ParsePush ({\"data\":{\"notification\":{\"body\":\"Bye FCM\"}}})")
        let push5 = ParsePush(payload: fcmPayload, query: installationQuery)
        XCTAssertEqual(push5.debugDescription,
                       // swiftlint:disable:next line_length
                       "ParsePush ({\"data\":{\"notification\":{\"body\":\"Bye FCM\"}},\"where\":{\"objectId\":{\"$ne\":null}}})")
        let push6 = ParsePush(payload: fcmPayload, query: installationQuery, expirationInterval: 7)
        XCTAssertEqual(push6.debugDescription,
                       // swiftlint:disable:next line_length
                       "ParsePush ({\"data\":{\"notification\":{\"body\":\"Bye FCM\"}},\"expiration_interval\":7,\"where\":{\"objectId\":{\"$ne\":null}}})")
    }

    func testChannels() throws {
        let currentDate = Date()
        let currentDateData = try ParseCoding.jsonEncoder().encode(currentDate)
        guard let currentDateString = String(data: currentDateData, encoding: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let fcmPayload = ParsePushPayloadFirebase(notification: .init(body: "Bye FCM"))
        var push = ParsePush<Installation, ParsePushPayloadFirebase>(payload: fcmPayload, expirationTime: currentDate)
        push.channels = ["hello"]
        XCTAssertEqual(push.debugDescription,
                       // swiftlint:disable:next line_length
                       "ParsePush ({\"channels\":[\"hello\"],\"data\":{\"notification\":{\"body\":\"Bye FCM\"}},\"expiration_time\":\(currentDateString)})")
    }
}
