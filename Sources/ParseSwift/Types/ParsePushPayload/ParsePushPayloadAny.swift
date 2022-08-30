//
//  ParsePushPayloadAny.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/8/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 The payload data for both a `ParsePushPayloadApple` and
 `ParsePushPayloadFirebase` push notification.
 */
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
    public var alert: ParsePushAppleAlert?
    var badge: AnyCodable?
    var sound: AnyCodable?
    var priority: AnyCodable?
    var contentAvailable: AnyCodable?
    var mutableContent: AnyCodable?

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: RawCodingKey.self)
        relevanceScore = try values.decodeIfPresent(Double.self, forKey: .key("relevance-score"))
        targetContentId = try values.decodeIfPresent(String.self, forKey: .key("targetContentIdentifier"))
        do {
            mutableContent = try values.decode(AnyCodable.self, forKey: .key("mutable-content"))
        } catch {
            mutableContent = try values.decodeIfPresent(AnyCodable.self, forKey: .key("mutableContent"))
        }
        do {
            contentAvailable = try values.decode(AnyCodable.self, forKey: .key("content-available"))
        } catch {
            contentAvailable = try values.decodeIfPresent(AnyCodable.self, forKey: .key("contentAvailable"))
        }
        do {
            let priorityInt = try values.decode(Int.self, forKey: .key("priority"))
            priority = AnyCodable(priorityInt)
        } catch {
            if let priorityString = try values.decodeIfPresent(String.self, forKey: .key("priority")),
               let priorityEnum = ParsePushPayloadFirebase.PushPriority(rawValue: priorityString) {
                priority = AnyCodable(priorityEnum)
            }
        }
        pushType = try values.decodeIfPresent(ParsePushPayloadApple.PushType.self, forKey: .key("push_type"))
        collapseId = try values.decodeIfPresent(String.self, forKey: .key("collapse_id"))
        category = try values.decodeIfPresent(String.self, forKey: .key("category"))
        sound = try values.decodeIfPresent(AnyCodable.self, forKey: .key("sound"))
        badge = try values.decodeIfPresent(AnyCodable.self, forKey: .key("badge"))
        do {
            alert = try values.decode(ParsePushAppleAlert.self, forKey: .key("alert"))
        } catch {
            if let alertBody = try? values.decode(String.self, forKey: .key("alert")) {
                alert = ParsePushAppleAlert(body: alertBody)
            }
        }
        threadId = try values.decodeIfPresent(String.self, forKey: .key("threadId"))
        mdm = try values.decodeIfPresent(String.self, forKey: .key("mdm"))
        topic = try values.decodeIfPresent(String.self, forKey: .key("topic"))
        interruptionLevel = try values.decodeIfPresent(String.self, forKey: .key("interruptionLevel"))
        urlArgs = try values.decodeIfPresent([String].self, forKey: .key("urlArgs"))
        title = try values.decodeIfPresent(String.self, forKey: .key("title"))
        uri = try values.decodeIfPresent(URL.self, forKey: .key("uri"))
        collapseKey = try values.decodeIfPresent(String.self, forKey: .key("collapseKey"))
        delayWhileIdle = try values.decodeIfPresent(Bool.self, forKey: .key("delayWhileIdle"))
        restrictedPackageName = try values.decodeIfPresent(String.self, forKey: .key("restrictedPackageName"))
        dryRun = try values.decodeIfPresent(Bool.self, forKey: .key("dryRun"))
        data = try values.decodeIfPresent([String: String].self, forKey: .key("data"))
        notification = try values.decodeIfPresent(ParsePushFirebaseNotification.self, forKey: .key("notification"))
    }

    public init() { }

    /**
     Convert the current `ParsePushPayloadAny` to `ParsePushPayloadApple`.
     - returns: A `ParsePushPayloadApple` instance.
     */
    public func convertToApple() -> ParsePushPayloadApple {
        var payload = ParsePushPayloadApple()
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
     Convert the current `ParsePushPayloadAny` to `ParsePushPayloadFirebase`.
     - returns: A `ParsePushPayloadFirebase` instance.
     */
    public func convertToFirebase() -> ParsePushPayloadFirebase {
        var payload = ParsePushPayloadFirebase()
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
