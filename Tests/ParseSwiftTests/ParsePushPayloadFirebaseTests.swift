//
//  ParsePushPayloadFirebaseTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/12/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

// swiftlint:disable line_length

class ParsePushPayloadFirebaseTests: XCTestCase {

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
        let fcmPayload = ParsePushPayloadFirebase(notification: .init(body: "Bye FCM"))
        XCTAssertEqual(fcmPayload.description, "{\"notification\":{\"body\":\"Bye FCM\"}}")
        let notification = ParsePushFirebaseNotification(title: "hello", body: "new", image: "world")
        XCTAssertEqual(notification.description, "{\"body\":\"new\",\"image\":\"world\",\"title\":\"hello\"}")
    }

    func testCoding() throws {
        var notification = ParsePushFirebaseNotification(title: "hello", body: "android", icon: "world")
        notification.sound = "yes"
        notification.badge = "no"
        notification.androidChannelId = "you"
        notification.bodyLocArgs = ["mother"]
        notification.bodyLocKey = "cousin"
        notification.clickAction = "to"
        notification.image = "icon"
        notification.subtitle = "trip"
        notification.tag = "it"
        notification.color = "blue"
        notification.titleLocArgs = ["arg"]
        notification.titleLocKey = "it"
        var fcmPayload = ParsePushPayloadFirebase(notification: notification)
        fcmPayload.data = ["help": "you"]
        fcmPayload.priority = .high
        fcmPayload.contentAvailable = true
        fcmPayload.mutableContent = true
        fcmPayload.collapseKey = "nope"
        fcmPayload.delayWhileIdle = false
        fcmPayload.dryRun = false
        fcmPayload.title = "peace"
        fcmPayload.restrictedPackageName = "geez"
        fcmPayload.uri = URL(string: "https://parse.org")
        let encoded = try ParseCoding.parseEncoder().encode(fcmPayload)
        let decoded = try ParseCoding.jsonDecoder().decode(ParsePushPayloadFirebase.self, from: encoded)
        XCTAssertEqual(fcmPayload, decoded)
        #if !os(Linux) && !os(Android) && !os(Windows)
        XCTAssertEqual(fcmPayload.description,
                       "{\"collapseKey\":\"nope\",\"contentAvailable\":true,\"data\":{\"help\":\"you\"},\"delayWhileIdle\":false,\"dryRun\":false,\"mutableContent\":true,\"notification\":{\"android_channel_id\":\"you\",\"badge\":\"no\",\"body\":\"android\",\"body_loc-key\":\"cousin\",\"body-loc-args\":[\"mother\"],\"click_action\":\"to\",\"color\":\"blue\",\"icon\":\"world\",\"image\":\"icon\",\"sound\":\"yes\",\"subtitle\":\"trip\",\"tag\":\"it\",\"title\":\"hello\",\"title_loc_args\":[\"arg\"],\"title_loc_key\":\"it\"},\"priority\":\"high\",\"restrictedPackageName\":\"geez\",\"title\":\"peace\",\"uri\":\"https:\\/\\/parse.org\"}")
        #endif
    }
}
