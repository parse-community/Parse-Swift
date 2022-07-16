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

    public init() { }

    /**
     Create an instance of `ParsePushPayloadApple` .
     - parameter alert: The alert payload for the Apple push notification.
     */
    public init(alert: ParsePushAppleAlert) {
        self.alert = alert
    }

    /**
     Create an instance of `ParsePushPayloadApple` .
     - parameter body: The body message to display for the Apple push notification.
     */
    public init(body: String) {
        self.body = body
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        do {
            alert = try values.decode(ParsePushAppleAlert.self, forKey: .alert)
        } catch {
            if let alertBody = try values.decodeIfPresent(String.self, forKey: .alert) {
                alert = ParsePushAppleAlert(body: alertBody)
            }
        }
        relevanceScore = try values.decodeIfPresent(Double.self, forKey: .relevanceScore)
        targetContentId = try values.decodeIfPresent(String.self, forKey: .targetContentId)
        mutableContent = try values.decodeIfPresent(Int.self, forKey: .mutableContent)
        contentAvailable = try values.decodeIfPresent(Int.self, forKey: .contentAvailable)
        priority = try values.decodeIfPresent(Int.self, forKey: .priority)
        pushType = try values.decodeIfPresent(Self.PushType.self, forKey: .pushType)
        collapseId = try values.decodeIfPresent(String.self, forKey: .collapseId)
        category = try values.decodeIfPresent(String.self, forKey: .category)
        sound = try values.decodeIfPresent(AnyCodable.self, forKey: .sound)
        badge = try values.decodeIfPresent(AnyCodable.self, forKey: .badge)
        threadId = try values.decodeIfPresent(String.self, forKey: .threadId)
        mdm = try values.decodeIfPresent(String.self, forKey: .mdm)
        topic = try values.decodeIfPresent(String.self, forKey: .topic)
        interruptionLevel = try values.decodeIfPresent(String.self, forKey: .interruptionLevel)
        urlArgs = try values.decodeIfPresent([String].self, forKey: .urlArgs)
    }

    /**
     Set the name of a sound file in your app’s main bundle or in the Library/Sounds folder
     of your app’s container directory. For information about how to prepare sounds, see
     [UNNotificationSound](https://developer.apple.com/documentation/usernotifications/unnotificationsound).
     - parameter sound: An instance of `ParsePushAppleSound`.
     - returns: A mutated instance of `ParsePushPayloadApple` for easy chaining.
     - warning: For Apple OS's only.
     */
    public func setSound(_ sound: ParsePushAppleSound) -> Self {
        var mutablePayload = self
        mutablePayload.sound = AnyCodable(sound)
        return mutablePayload
    }

    /**
     Set the name of a sound file in your app’s main bundle or in the Library/Sounds folder
     of your app’s container directory. Specify the string “default” to play the system
     sound. Pass a string for **regular** notifications. For critical alerts, pass the sound
     `ParsePushAppleSound` instead. For information about how to prepare sounds, see
     [UNNotificationSound](https://developer.apple.com/documentation/usernotifications/unnotificationsound).
     - parameter sound: A `String` or any `Codable` object that can be sent to APN.
     - returns: A mutated instance of `ParsePushPayloadApple` for easy chaining.
     - warning: For Apple OS's only.
     */
    public func setSound<V>(_ sound: V) -> Self where V: Codable {
        var mutablePayload = self
        mutablePayload.sound = AnyCodable(sound)
        return mutablePayload
    }

    /**
     Get the sound using any type that conforms to `Codable`.
     - returns: The sound casted to the inferred type.
     - throws: An error of type `ParseError`.
     */
    public func getSound<V>() throws -> V where V: Codable {
        guard let sound = sound?.value as? V else {
            throw ParseError(code: .unknownError,
                             message: "Cannot be casted to the inferred type")
        }
        return sound
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
