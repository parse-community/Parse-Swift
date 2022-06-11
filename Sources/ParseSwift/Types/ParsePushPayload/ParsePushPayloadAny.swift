//
//  ParsePushPayloadAny.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/8/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public struct ParsePushPayloadAny: ParsePushApplePayloadable, ParsePushFirebasePayloadable {
    public var topic: String?
    public var collapseId: String?
    public var pushType: ParsePushPayloadApple.PushType?
    public var category: String?
    public var urlArgs: [String]?
    public var targetContentId: String?
    public var threadId: String?
    public var interruptionLevel: String?
    public var relevanceScore: Double?
    public var mdm: String?
    public var uri: URL?
    public var title: String?
    public var collapseKey: String?
    public var delayWhileIdle: Bool?
    public var restrictedPackageName: String?
    public var dryRun: Bool?
    public var data: [String: String]?
    public var notification: ParsePushFirebaseNotification?
    public var expirationTime: TimeInterval?
    public var alert: ParsePushAppleAlert?
    var badge: AnyCodable?
    var sound: AnyCodable?
    var priority: AnyCodable?
    var contentAvailable: AnyCodable?
    var mutableContent: AnyCodable?

    public init() { }

    /**
     Convert the current `ParsePushPayloadGeneric` to `ParsePushPayloadApple`.
     - returns: A `ParsePushPayloadApple` instance.
     */
    public func convertToApple() -> ParsePushPayloadApple {
        var payload = ParsePushPayloadApple()
        payload.expirationTime = expirationTime
        payload.topic = topic
        payload.collapseId = collapseId
        payload.pushType = pushType
        payload.category = category
        payload.urlArgs = urlArgs
        payload.targetContentId = targetContentId
        payload.threadId = threadId
        payload.interruptionLevel = interruptionLevel
        payload.relevanceScore = relevanceScore
        payload.mdm = mdm
        payload.alert = alert
        payload.badge = badge
        payload.sound = sound
        if let priority = priority?.value as? Int {
            payload.priority = priority
        }
        if let contentAvailable = contentAvailable?.value as? Int {
            payload.contentAvailable = contentAvailable
        }
        if let mutableContent = mutableContent?.value as? Int {
            payload.mutableContent = mutableContent
        }
        return payload
    }

    /**
     Convert the current `ParsePushPayloadGeneric` to `ParsePushPayloadFCM`.
     - returns: A `ParsePushPayloadFCM` instance.
     */
    public func convertToFCM() -> ParsePushPayloadFirebase {
        var payload = ParsePushPayloadFirebase()
        payload.expirationTime = expirationTime
        payload.uri = uri
        payload.title = title
        payload.collapseKey = collapseKey
        payload.delayWhileIdle = delayWhileIdle
        payload.restrictedPackageName = restrictedPackageName
        payload.dryRun = dryRun
        payload.data = data
        payload.notification = notification
        if let priority = priority?.value as? ParsePushPayloadFirebase.PushPriority {
            payload.priority = priority
        }
        if let contentAvailable = contentAvailable?.value as? Bool {
            payload.contentAvailable = contentAvailable
        }
        if let mutableContent = mutableContent?.value as? Bool {
            payload.mutableContent = mutableContent
        }
        return payload
    }
}
