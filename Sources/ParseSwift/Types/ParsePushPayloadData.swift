//
//  ParsePushPayloadData.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/5/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/// The payload data for a push notification.
public struct ParsePushPayloadData: ParsePushPayloadDatable {
    public var topic: String?

    public var collapseId: String?

    public var relevanceScore: Double?

    public var targetContentId: String?

    public var interruptionLevel: String?

    public var contentAvailable: Int?

    public var mutableContent: Int?

    public var pushType: PushType?

    public var priority: Int?

    public var category: String?

    public var urlArgs: [String]?

    public var threadId: String?

    public var mdm: String?

    public var uri: URL?

    public var title: String?

    var alert: AnyCodable?
    var badge: AnyCodable?
    var sound: AnyCodable?

    public enum PushType: String, Codable {
        case alert, backgroud
    }

    enum CodingKeys: String, CodingKey {
        case relevanceScore = "relevance-score"
        case interruptionLevel = "interruption-level"
        case targetContentId = "target-content-id"
        case mutableContent = "mutable-content"
        case contentAvailable = "content-available"
        case threadId = "thread-id"
        case category, sound, badge, alert,
             pushType, mdm, title, uri, priority,
             topic, collapseId
    }

    /// Create an empty payload.
    public init() { }

    /**
     Set the alert using a `String`.
     - parameter alert: The information for displaying an alert.
     */
    public mutating func setAlert(_ alert: String) {
        self.alert = AnyCodable(alert)
    }

    /**
     Set the alert using a `ParsePushPayloadAlert`.
     - parameter alert: The `ParsePushPayloadAlert`.
     - warning: For Apple OS's only.
     */
    public mutating func setAlert(_ alert: ParsePushPayloadAppleAlert) {
        self.alert = AnyCodable(alert)
    }

    /**
     Set the alert using any type that conforms to `Codable`.
     - parameter alert: The `Codable` alert.
     */
    public mutating func setAlert(_ alert: Codable) {
        self.alert = AnyCodable(alert)
    }

    /**
     Set the name of a sound file in your app’s main bundle or in the Library/Sounds folder
     of your app’s container directory. Specify the string “default” to play the system
     sound. Use this key for **regular** notifications. For critical alerts, use the sound
     `ParsePushPayloadAppleSound` instead. For information about how to prepare sounds, see
     [UNNotificationSound](https://developer.apple.com/documentation/usernotifications/unnotificationsound).
     - warning: For Apple OS's only.
     */
    public mutating func setSound(_ name: String) {
        self.sound = AnyCodable(name)
    }

    /**
     Set the **critical** sound in your app’s main bundle or in the Library/Sounds folder
     of your app’s container directory. Specify the string “default” to play the system
     sound. Use this key for **critical** notifications. For regular alerts, use the sound
     `ParsePushPayloadAppleSound` instead. For information about how to prepare sounds, see
     [UNNotificationSound](https://developer.apple.com/documentation/usernotifications/unnotificationsound).
     - parameter alert: The `ParsePushPayloadSound`.
     - warning: For Apple OS's only.
     */
    public mutating func setSound(_ payload: ParsePushPayloadAppleSound) {
        self.sound = AnyCodable(payload)
    }

    /**
     Set the sound using any type that conforms to `Codable`.
     - parameter alert: The `Codable` alert.
     */
    public mutating func setSound(_ payload: Codable) {
        self.sound = AnyCodable(payload)
    }

    /**
     Set the badge to a specific value to display on your app's icon.
     - parameter badge: The number to display in a badge on your app’s icon.
     Specify 0 to remove the current badge, if any.
     - warning: For Apple OS's only.
     */
    public mutating func setBadge(_ number: Int) {
        self.badge = AnyCodable(number)
    }

    /**
     Increment the badge value by 1 to display on your app's icon.
     - warning: For Apple OS's only.
     */
    public mutating func increaseBadge() {
        self.badge = AnyCodable(Increment(amount: 1))
    }
}
