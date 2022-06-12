//
//  ParsePushPayloadAppleTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/11/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

// swiftlint:disable line_length

class ParsePushPayloadAppleTests: XCTestCase {

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
        let body = "Hello from ParseSwift!"
        var applePayload = ParsePushPayloadApple(body: body)
        XCTAssertEqual(applePayload.description,
                       "ParsePushPayloadable ({\"alert\":{\"body\":\"\(body)\"},\"push_type\":\"alert\"})")
        let applePayload2 = ParsePushPayloadApple(alert: .init(body: body))
        XCTAssertEqual(applePayload, applePayload2)
        XCTAssertEqual(applePayload.body, body)
        applePayload.alert = nil
        XCTAssertNil(applePayload.body)
        applePayload.body = body
        XCTAssertEqual(applePayload.alert, applePayload2.alert)
    }

    func testBadge() throws {
        let applePayload = ParsePushPayloadApple()
            .setBadge(1)
        XCTAssertEqual(applePayload.description,
                       "ParsePushPayloadable ({\"badge\":1,\"push_type\":\"alert\"})")
        let applePayload2 = ParsePushPayloadApple()
            .incrementBadge()
        XCTAssertEqual(applePayload2.description,
                       "ParsePushPayloadable ({\"badge\":{\"__op\":\"Increment\",\"amount\":1},\"push_type\":\"alert\"})")
    }

    func testSound() throws {
        let applePayload = ParsePushPayloadApple()
            .setSound("hello")
        XCTAssertEqual(applePayload.description,
                       "ParsePushPayloadable ({\"push_type\":\"alert\",\"sound\":\"hello\"})")
        let soundString: String = try applePayload.getSound()
        XCTAssertEqual(soundString, "hello")
        let sound = ParsePushAppleSound(critical: true, name: "hello", volume: 7)
        let applePayload2 = ParsePushPayloadApple()
            .setSound(sound)
        XCTAssertEqual(applePayload2.description,
                       "ParsePushPayloadable ({\"push_type\":\"alert\",\"sound\":{\"critical\":true,\"name\":\"hello\",\"volume\":7}})")
        let soundObject: ParsePushAppleSound = try applePayload2.getSound()
        XCTAssertEqual(soundObject, sound)
    }

    func testCoding() throws {
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
        var applePayload = ParsePushPayloadApple(alert: alert)
            .setBadge(1)
            .setSound(sound)
        applePayload.urlArgs = ["help"]
        applePayload.interruptionLevel = "yolo"
        applePayload.topic = "naw"
        applePayload.threadId = "yep"
        applePayload.collapseId = "nope"
        applePayload.pushType = .background
        applePayload.priority = 6
        applePayload.contentAvailable = 1
        applePayload.mutableContent = 1
        applePayload.targetContentId = "press"
        applePayload.relevanceScore = 2.0
        let encoded = try ParseCoding.parseEncoder().encode(applePayload)
        let decoded = try ParseCoding.jsonDecoder().decode(ParsePushPayloadApple.self, from: encoded)
        XCTAssertEqual(applePayload, decoded)
        XCTAssertEqual(applePayload.description,
                       "ParsePushPayloadable ({\"alert\":{\"action\":\"to\",\"action-loc-key\":\"icon\",\"body\":\"pull up\",\"launch-image\":\"it\",\"loc-args\":[\"mother\"],\"loc-key\":\"cousin\",\"subtitle\":\"trip\",\"subtitle-loc-args\":[\"gone\"],\"subtitle-loc-key\":\"far\",\"title\":\"you\",\"title-loc-args\":[\"arg\"],\"title-loc-key\":\"it\"},\"badge\":1,\"collapse_id\":\"nope\",\"content-available\":1,\"interruptionLevel\":\"yolo\",\"mutable-content\":1,\"priority\":6,\"push_type\":\"background\",\"relevance-score\":2,\"sound\":{\"critical\":true,\"name\":\"hello\",\"volume\":7},\"targetContentIdentifier\":\"press\",\"threadId\":\"yep\",\"topic\":\"naw\",\"urlArgs\":[\"help\"]})")
    }
}
