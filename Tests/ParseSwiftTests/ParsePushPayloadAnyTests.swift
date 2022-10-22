//
//  ParsePushPayloadAnyTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/12/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

// swiftlint:disable line_length

class ParsePushPayloadAnyTests: XCTestCase {

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

    func testCoding() throws {

        // Setup Apple
        let sound = ParsePushAppleSound(critical: true, name: "hello", volume: 7)
        var alert = ParsePushAppleAlert(body: "pull up")
        alert.titleLocKey = "yes"
        alert.title = "you"
        alert.locArgs = ["mother"]
        alert.locKey = "cousin"
        alert.action = "to"
        alert.actionLocKey = "icon"
        alert.subtitle = "trip"
        alert.subtitleLocKey = "far"
        alert.subtitleLocArgs = ["gone"]
        alert.launchImage = "it"
        alert.titleLocArgs = ["arg"]
        alert.titleLocKey = "it"

        // Setup Firebase
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

        // Set Apple
        var anyPayload = ParsePushPayloadAny()
        anyPayload.alert = alert
        anyPayload.badge = AnyCodable(1)
        anyPayload.sound = AnyCodable(sound)
        anyPayload.urlArgs = ["help"]
        anyPayload.interruptionLevel = "yolo"
        anyPayload.topic = "naw"
        anyPayload.threadId = "yep"
        anyPayload.collapseId = "nope"
        anyPayload.pushType = .background
        anyPayload.targetContentId = "press"
        anyPayload.relevanceScore = 2.0
        anyPayload.priority = 6
        anyPayload.contentAvailable = 1
        anyPayload.mutableContent = 1

        // Set Firebase
        anyPayload.notification = notification
        anyPayload.data = ["help": "you"]
        anyPayload.collapseKey = "nope"
        anyPayload.delayWhileIdle = false
        anyPayload.dryRun = false
        anyPayload.title = "peace"
        anyPayload.restrictedPackageName = "geez"
        anyPayload.uri = URL(string: "https://parse.org")

        // Test Apple
        let applePayload = anyPayload.convertToApple()
        let encoded = try ParseCoding.parseEncoder().encode(applePayload)
        let decoded = try ParseCoding.jsonDecoder().decode(ParsePushPayloadApple.self, from: encoded)
        XCTAssertEqual(applePayload, decoded)
        XCTAssertEqual(applePayload.description,
                       "{\"alert\":{\"action\":\"to\",\"action-loc-key\":\"icon\",\"body\":\"pull up\",\"launch-image\":\"it\",\"loc-args\":[\"mother\"],\"loc-key\":\"cousin\",\"subtitle\":\"trip\",\"subtitle-loc-args\":[\"gone\"],\"subtitle-loc-key\":\"far\",\"title\":\"you\",\"title-loc-args\":[\"arg\"],\"title-loc-key\":\"it\"},\"badge\":1,\"collapse_id\":\"nope\",\"content-available\":1,\"interruptionLevel\":\"yolo\",\"mutable-content\":1,\"priority\":6,\"push_type\":\"background\",\"relevance-score\":2,\"sound\":{\"critical\":true,\"name\":\"hello\",\"volume\":7},\"targetContentIdentifier\":\"press\",\"threadId\":\"yep\",\"topic\":\"naw\",\"urlArgs\":[\"help\"]}")
        let decodedAny = try ParseCoding.jsonDecoder().decode(ParsePushPayloadAny.self, from: encoded).convertToApple()
        XCTAssertEqual(decodedAny, applePayload)

        // Test Firebase
        let fcmPayload = anyPayload.convertToFirebase()
        let encoded2 = try ParseCoding.parseEncoder().encode(fcmPayload)
        let decoded2 = try ParseCoding.jsonDecoder().decode(ParsePushPayloadFirebase.self, from: encoded2)
        XCTAssertEqual(fcmPayload, decoded2)
        let decodedAny2 = try ParseCoding.jsonDecoder().decode(ParsePushPayloadAny.self, from: encoded).convertToApple()
        XCTAssertEqual(decodedAny2, applePayload)
        #if !os(Linux) && !os(Android) && !os(Windows)
        XCTAssertEqual(fcmPayload.description,
                       "{\"collapseKey\":\"nope\",\"data\":{\"help\":\"you\"},\"delayWhileIdle\":false,\"dryRun\":false,\"notification\":{\"android_channel_id\":\"you\",\"badge\":\"no\",\"body\":\"android\",\"body_loc-key\":\"cousin\",\"body-loc-args\":[\"mother\"],\"click_action\":\"to\",\"color\":\"blue\",\"icon\":\"world\",\"image\":\"icon\",\"sound\":\"yes\",\"subtitle\":\"trip\",\"tag\":\"it\",\"title\":\"hello\",\"title_loc_args\":[\"arg\"],\"title_loc_key\":\"it\"},\"restrictedPackageName\":\"geez\",\"title\":\"peace\",\"uri\":\"https:\\/\\/parse.org\"}")
        #endif
    }

    func testAppleAlertStringDecode() throws {
        let sound = ParsePushAppleSound(critical: true, name: "hello", volume: 7)
        let alert = ParsePushAppleAlert(body: "pull up")
        var anyPayload = ParsePushPayloadAny()
        anyPayload.alert = alert
        anyPayload.badge = AnyCodable(1)
        anyPayload.sound = AnyCodable(sound)
        anyPayload.urlArgs = ["help"]
        anyPayload.interruptionLevel = "yolo"
        anyPayload.topic = "naw"
        anyPayload.threadId = "yep"
        anyPayload.collapseId = "nope"
        anyPayload.pushType = .background
        anyPayload.targetContentId = "press"
        anyPayload.relevanceScore = 2.0
        anyPayload.priority = 6
        anyPayload.contentAvailable = 1
        anyPayload.mutableContent = 1

        let applePayload = anyPayload.convertToApple()
        guard let jsonData = "{\"alert\":\"pull up\",\"badge\":1,\"collapse_id\":\"nope\",\"content-available\":1,\"interruptionLevel\":\"yolo\",\"mutable-content\":1,\"priority\":6,\"push_type\":\"background\",\"relevance-score\":2,\"sound\":{\"critical\":true,\"name\":\"hello\",\"volume\":7},\"targetContentIdentifier\":\"press\",\"threadId\":\"yep\",\"topic\":\"naw\",\"urlArgs\":[\"help\"]}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decodedAlert = try ParseCoding.jsonDecoder().decode(ParsePushPayloadAny.self, from: jsonData).convertToApple()
        XCTAssertEqual(decodedAlert, applePayload)
    }

    func testConvertToApple() throws {
        let sound = ParsePushAppleSound(critical: true, name: "hello", volume: 7)
        var alert = ParsePushAppleAlert(body: "pull up")
        alert.titleLocKey = "yes"
        alert.title = "you"
        alert.locArgs = ["mother"]
        alert.locKey = "cousin"
        alert.action = "to"
        alert.actionLocKey = "icon"
        alert.subtitle = "trip"
        alert.subtitleLocKey = "far"
        alert.subtitleLocArgs = ["gone"]
        alert.launchImage = "it"
        alert.titleLocArgs = ["arg"]
        alert.titleLocKey = "it"

        var anyPayload = ParsePushPayloadAny()
        anyPayload.alert = alert
        anyPayload.badge = AnyCodable(1)
        anyPayload.sound = AnyCodable(sound)
        anyPayload.urlArgs = ["help"]
        anyPayload.interruptionLevel = "yolo"
        anyPayload.topic = "naw"
        anyPayload.threadId = "yep"
        anyPayload.collapseId = "nope"
        anyPayload.pushType = .background
        anyPayload.targetContentId = "press"
        anyPayload.relevanceScore = 2.0
        anyPayload.priority = 6
        anyPayload.contentAvailable = 1
        anyPayload.mutableContent = 1

        let applePayload = anyPayload.convertToApple()
        let encoded = try ParseCoding.parseEncoder().encode(applePayload)
        let decoded = try ParseCoding.jsonDecoder().decode(ParsePushPayloadApple.self, from: encoded)
        XCTAssertEqual(applePayload, decoded)
        XCTAssertEqual(applePayload.description,
                       "{\"alert\":{\"action\":\"to\",\"action-loc-key\":\"icon\",\"body\":\"pull up\",\"launch-image\":\"it\",\"loc-args\":[\"mother\"],\"loc-key\":\"cousin\",\"subtitle\":\"trip\",\"subtitle-loc-args\":[\"gone\"],\"subtitle-loc-key\":\"far\",\"title\":\"you\",\"title-loc-args\":[\"arg\"],\"title-loc-key\":\"it\"},\"badge\":1,\"collapse_id\":\"nope\",\"content-available\":1,\"interruptionLevel\":\"yolo\",\"mutable-content\":1,\"priority\":6,\"push_type\":\"background\",\"relevance-score\":2,\"sound\":{\"critical\":true,\"name\":\"hello\",\"volume\":7},\"targetContentIdentifier\":\"press\",\"threadId\":\"yep\",\"topic\":\"naw\",\"urlArgs\":[\"help\"]}")
        let decoded2 = try ParseCoding.jsonDecoder().decode(ParsePushPayloadAny.self, from: encoded).convertToApple()
        XCTAssertEqual(decoded2, applePayload)
        var applePayload2 = applePayload
        applePayload2.sound = AnyCodable("wow")
        let encodedSound = try ParseCoding.parseEncoder().encode(applePayload2)
        let decodedSound = try ParseCoding.jsonDecoder().decode(ParsePushPayloadAny.self, from: encodedSound).convertToApple()
        XCTAssertEqual(decodedSound, applePayload2)
    }

    func testConvertToFirebase() throws {
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

        var anyPayload = ParsePushPayloadAny()
        anyPayload.priority = AnyCodable(ParsePushPayloadFirebase.PushPriority.high)
        anyPayload.contentAvailable = true
        anyPayload.mutableContent = true
        anyPayload.notification = notification
        anyPayload.data = ["help": "you"]
        anyPayload.collapseKey = "nope"
        anyPayload.delayWhileIdle = false
        anyPayload.dryRun = false
        anyPayload.title = "peace"
        anyPayload.restrictedPackageName = "geez"
        anyPayload.uri = URL(string: "https://parse.org")

        let fcmPayload = anyPayload.convertToFirebase()
        let encoded = try ParseCoding.parseEncoder().encode(fcmPayload)
        let decoded = try ParseCoding.jsonDecoder().decode(ParsePushPayloadFirebase.self, from: encoded)
        XCTAssertEqual(fcmPayload, decoded)
        let decoded2 = try ParseCoding.jsonDecoder().decode(ParsePushPayloadAny.self, from: encoded).convertToFirebase()
        XCTAssertEqual(decoded2, fcmPayload)
        #if !os(Linux) && !os(Android) && !os(Windows)
        XCTAssertEqual(fcmPayload.description,
                       "{\"collapseKey\":\"nope\",\"contentAvailable\":true,\"data\":{\"help\":\"you\"},\"delayWhileIdle\":false,\"dryRun\":false,\"mutableContent\":true,\"notification\":{\"android_channel_id\":\"you\",\"badge\":\"no\",\"body\":\"android\",\"body_loc-key\":\"cousin\",\"body-loc-args\":[\"mother\"],\"click_action\":\"to\",\"color\":\"blue\",\"icon\":\"world\",\"image\":\"icon\",\"sound\":\"yes\",\"subtitle\":\"trip\",\"tag\":\"it\",\"title\":\"hello\",\"title_loc_args\":[\"arg\"],\"title_loc_key\":\"it\"},\"priority\":\"high\",\"restrictedPackageName\":\"geez\",\"title\":\"peace\",\"uri\":\"https:\\/\\/parse.org\"}")
        #endif
    }
}
