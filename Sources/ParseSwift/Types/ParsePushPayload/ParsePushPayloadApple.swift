//
//  ParsePushPayload.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/5/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/// The payload data for an Apple push notification.
public struct ParsePushPayloadApple: ParsePushApplePayloadable {
    /**
     If you are a writing an app using the Remote Notification
     Background Mode introduced in iOS7 (a.k.a. “Background Push”), set this value to
     1 to trigger a background download.
     - warning: For Apple OS's only. You also have to set `pushType` starting iOS 13
     and watchOS 6.
     */
    public var contentAvailable: Int?
    /**
     If you are a writing an app using the Remote Notification Background Mode introduced
     in iOS7 (a.k.a. “Background Push”), set this value to 1 to trigger a background download.
     - warning: You also have to set `pushType` starting iOS 13
     and watchOS 6.
     */
    public var mutableContent: Int?
    /**
     The priority of the notification. Specify 10 to send the notification immediately.
     Specify 5 to send the notification based on power considerations on the user’s device.
     See Apple's [documentation](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns)
     for more information.
     - warning: For Apple OS's only.
     */
    public var priority: Int?

    public var topic: String?

    public var collapseId: String?

    public var relevanceScore: Double?

    public var targetContentId: String?

    public var interruptionLevel: String?

    public var pushType: PushType? = .alert

    public var category: String?

    public var urlArgs: [String]?

    public var threadId: String?

    public var mdm: String?

    public var expirationTime: TimeInterval?

    var alert: AnyCodable?
    var badge: AnyCodable?
    var sound: AnyCodable?

    /// The type of notification.
    public enum PushType: String, Codable {
        /// Send as an alert.
        case alert
        /// Send as a background notification.
        case background
    }

    enum CodingKeys: String, CodingKey {
        case relevanceScore = "relevance-score"
        case targetContentId = "targetContentIdentifier"
        case mutableContent = "mutable-content"
        case contentAvailable = "content-available"
        case expirationTime = "expiration_time"
        case pushType = "push_type"
        case collapseId = "collapse_id"
        case category, sound, badge, alert, threadId,
             mdm, priority, topic, interruptionLevel,
             urlArgs
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
    public mutating func incrementBadge() {
        self.badge = AnyCodable(Increment(amount: 1))
    }
}
