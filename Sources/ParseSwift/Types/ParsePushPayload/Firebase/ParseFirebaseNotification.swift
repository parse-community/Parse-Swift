//
//  ParseFirebaseNotification.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/11/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 FCM automatically displays the message to end-user devices on behalf of the client
 app. Notification messages have a predefined set of user-visible keys and an
 optional data payload of custom key-value pairs. For more information, see
 [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging/http-server-ref#notification-payload-support).
 */
public struct ParseFirebaseNotification: Codable, Equatable {
    /**
     Contains the URL of an image that is going to be downloaded
     on the device and displayed in a notification. JPEG, PNG, BMP
     have full support across platforms. Animated GIF and video only
     work on iOS. WebP and HEIF have varying levels of support
     across platforms and platform versions. Android has 1MB image
     size limit.
     */
    public var image: String?
    /**
     Indicates notification icon. On Android: sets value to myicon for
     drawable resource **myicon.png**.
     */
    public var icon: String?
    /**
     Indicates notification body text.
     */
    public var body: String?
    /**
     Indicates notification title. This field is not visible on iOS phones and tablets.
     - warning: Required for Android, optional for iOS.
     */
    public var title: String?
    /**
     The notification's subtitle.
     */
    public var subtitle: String?
    /**
     Indicates sound to be played. Supports only default currently.
     */
    public var sound: String?
    /**
     Indicates the badge on client app home icon.
     */
    public var badge: String?
    /**
     Indicates whether each notification message results in a new
     entry on the notification center on Android. If not set, each request
     creates a new notification. If set, and a notification with the same
     tag is already being shown, the new notification replaces the
     existing one in notification center.
     */
    public var tag: String?
    /**
     Indicates color of the icon, expressed in #rrggbb format.
     */
    public var color: String?
    /**
     The action associated with a user click on the notification. On Android,
     if this is set, an activity with a matching intent filter is launched when
     user clicks the notification.
     */
    public var clickAction: String?
    /**
     Indicates the key to the body string for localization. On iOS, this
     corresponds to "loc-key" in APNS payload.
     */
    public var bodyLocKey: String?
    /**
     Indicates the string value to replace format specifiers in body string
     for localization. On iOS, this corresponds to "loc-args" in APNS payload.
     */
    public var bodyLocArgs: [String]?
    /**
     Indicates the string value to replace format specifiers in title string for l
     ocalization. On iOS, this corresponds to "title-loc-args" in APNS payload.
     */
    public var titleLocKey: String?
    /**
     Indicates the key to the title string for localization. On iOS, this
     corresponds to "title-loc-key" in APNS payload.
     */
    public var titleLocArgs: [String]?
    /**
     The app must create a channel with this channel ID before any
     notification with this channel ID is received.
     */
    public var channelId: String?
    /**
     Sets the "ticker" text, which is sent to accessibility services. Prior
     to API level 21 (Lollipop), sets the text that is displayed in the
     status bar when the notification first arrives.
     */
    public var ticker: String?
    /**
     When set to **false** or unset, the notification is automatically dismissed
     when the user clicks it in the panel. When set to **true**, the notification
     persists even when the user clicks it.
     */
    public var sticky: Bool?
    public var eventTime: TimeInterval?
    public var localOnly: Bool?
    public var notificationPriority: Level?
    public var defaultSound: Bool?
    public var defaultVibrateTimings: Bool?
    public var defaultVibrateSettings: Bool?
    public var visibility: Visibility?
    public var notificationCount: Int?

    enum CodingKeys: String, CodingKey {
        case titleLocKey = "title_loc_key"
        case titleLocArgs = "title_loc_args"
        case bodyLocKey = "body_loc-key"
        case bodyLocArgs = "body-loc-args"
        case clickAction = "click_action"
        case channelId = "channel_id"
        case eventTime = "event_time"
        case localOnly = "local_only"
        case notificationPriority = "notification_priority"
        case defaultSound = "default_sound"
        case defaultVibrateTimings = "default_vibrate_timings"
        case defaultVibrateSettings = "default_light_settings"
        case notificationCount = "notification_count"
        case title, image, icon, body, sound, badge, tag,
            color, subtitle, ticker, sticky, visibility
    }

    /// Different visibility levels of a notification.
    public enum Visibility: Int, Codable {
        /// Show this notification on all lockscreens, but conceal
        /// sensitive or private information on secure lockscreens.
        case privateLevel = 0
        /// Show this notification in its entirety on all lockscreens.
        case publicLevel = 1
        /// Do not reveal any part of this notification on a secure
        /// lockscreen.
        case secretLevel = 2
    }

    /// Priority levels of a notification.
    public enum Level: Int, Codable {
        /**
         Lowest notification priority. Notifications with this
         PRIORITY_MIN might not be shown to the user except
         under special circumstances, such as detailed notification logs.
         */
        case minPriority = 0
        /**
         Lower notification priority. The UI may choose to show the
         notifications smaller, or at a different position in the list,
         compared with notifications with PRIORITY_DEFAULT.
         */
        case lowPriority = 1
        /**
         Default notification priority. If the application does not prioritize
         its own notifications, use this value for all notifications.
         */
        case defaultPriority = 2
        /**
         Higher notification priority. Use this for more important notifications
         or alerts. The UI may choose to show these notifications larger, or
         at a different position in the notification lists, compared with
         notifications with PRIORITY_DEFAULT.
         */
        case highPriority = 3
        /**
         Highest notification priority. Use this for the application's most
         important items that require the user's prompt attention or input.
         */
        case maxPriority = 4
    }

    public init(title: String? = nil,
                body: String? = nil,
                icon: String?) {
        self.title = title
        self.body = body
        self.icon = icon
    }

    public init(title: String? = nil,
                body: String? = nil,
                image: String? = nil) {
        self.title = title
        self.body = body
        self.image = image
    }
}
