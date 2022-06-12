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

    public var alert: ParsePushAppleAlert?

    /**
     The content of the alert message.
     */
    public var body: String? {
        get {
            alert?.body
        }
        set {
            if alert != nil {
                alert?.body = newValue
            } else if let newBody = newValue {
                alert = .init(body: newBody)
            }
        }
    }
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
        case pushType = "push_type"
        case collapseId = "collapse_id"
        case category, sound, badge, alert, threadId,
             mdm, priority, topic, interruptionLevel,
             urlArgs
    }

    /**
     Create an instance of `ParsePushPayloadApple` .
     - parameter alert: The alert payload for the Apple push notification.
     Defaults to **nil**.
     */
    public init(alert: ParsePushAppleAlert? = nil) {
        self.alert = alert
    }

    /**
     Create an instance of `ParsePushPayloadApple` .
     - parameter body: The body message to display for the Apple push notification.
     */
    public init(body: String) {
        self.body = body
    }

    /**
     Set the name of a sound file in your app’s main bundle or in the Library/Sounds folder
     of your app’s container directory. Specify the string “default” to play the system
     sound. Use this key for **regular** notifications. For critical alerts, use the sound
     `ParsePushPayloadAppleSound` instead. For information about how to prepare sounds, see
     [UNNotificationSound](https://developer.apple.com/documentation/usernotifications/unnotificationsound).
     - returns: A mutated instance of `ParsePushPayloadApple` for easy chaining.
     - warning: For Apple OS's only.
     */
    public func setSound(_ name: String) -> Self {
        var mutablePayload = self
        mutablePayload.sound = AnyCodable(name)
        return mutablePayload
    }

    /**
     Set the **critical** sound in your app’s main bundle or in the Library/Sounds folder
     of your app’s container directory. Specify the string “default” to play the system
     sound. Use this key for **critical** notifications. For regular alerts, use the sound
     `ParsePushPayloadAppleSound` instead. For information about how to prepare sounds, see
     [UNNotificationSound](https://developer.apple.com/documentation/usernotifications/unnotificationsound).
     - parameter alert: The `ParsePushPayloadSound`.
     - returns: A mutated instance of `ParsePushPayloadApple` for easy chaining.
     */
    public func setSound(_ payload: ParsePushAppleSound) -> Self {
        var mutablePayload = self
        mutablePayload.sound = AnyCodable(payload)
        return mutablePayload
    }

    /**
     Set the sound using any type that conforms to `Codable`.
     - parameter alert: The `Codable` alert.
     - returns: A mutated instance of `ParsePushPayloadApple` for easy chaining.
     */
    public func setSound(_ payload: Codable) -> Self {
        var mutablePayload = self
        mutablePayload.sound = AnyCodable(payload)
        return mutablePayload
    }

    /**
     Set the badge to a specific value to display on your app's icon.
     - parameter badge: The number to display in a badge on your app’s icon.
     Specify 0 to remove the current badge, if any.
     - returns: A mutated instance of `ParsePushPayloadApple` for easy chaining.
     - warning: For Apple OS's only.
     */
    public func setBadge(_ number: Int) -> Self {
        var mutablePayload = self
        mutablePayload.badge = AnyCodable(number)
        return mutablePayload
    }

    /**
     Increment the badge value by 1 to display on your app's icon.
     - warning: For Apple OS's only.
     - returns: A mutated instance of `ParsePushPayloadApple` for easy chaining.
     */
    public func incrementBadge() -> Self {
        var mutablePayload = self
        mutablePayload.badge = AnyCodable(Increment(amount: 1))
        return mutablePayload
    }
}
