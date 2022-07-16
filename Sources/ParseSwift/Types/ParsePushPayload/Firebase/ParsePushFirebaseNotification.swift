//
//  ParsePushFirebaseNotification.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/11/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 The Firebase Cloud Messaging (FCM) notification payload. For more information, see
 [Firebase Cloud Messaging](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages#Notification)
 and [Firebase Cloud Messaging (legacy)](https://firebase.google.com/docs/cloud-messaging/http-server-ref#notification-payload-support).
 */
public struct ParsePushFirebaseNotification: ParseTypeable {
    /**
     Indicates notification icon. On Android: sets value to myicon for
     drawable resource **myicon.png**.
     - note: Android: Required, Apple: Not Avialable.
     - warning: Only valid for FCM legacy HTTP API.
     */
    public var icon: String?

    /**
     Contains the URL of an image that is going to be downloaded on
     the device and displayed in a notification. JPEG, PNG, BMP have
     full support across platforms. Animated GIF and video only work on
     iOS. WebP and HEIF have varying levels of support across platforms
     and platform versions. Android has 1MB image size limit.
     - note: Android: Optional, Apple: Optional.
     - warning: Only valid for FCM HTTP v1 API.
     */
    public var image: String?

    /**
     Indicates notification body text.
     - note: Android: Optional, Apple: Optional.
     - warning: Only valid for FCM legacy HTTP API.
     */
    public var body: String?
    /**
     Indicates notification title. This field is not visible on iOS phones and tablets.
     - note: Android: Required, Apple: Optional.
     - warning: Only valid for FCM legacy HTTP API.
     */
    public var title: String?
    /**
     The notification's subtitle.
     - note: Android: Required, Apple-watchOS: Optional.
     - warning: Only valid for FCM legacy HTTP API.
     */
    public var subtitle: String?
    /**
     Indicates sound to be played. Supports only default currently.
     - note: Android: Optional, Apple: Optional.
     - warning: Only valid for FCM legacy HTTP API.
     */
    public var sound: String?
    /**
     Indicates the badge on client app home icon.
     - note: Android: Not Available, Apple: Optional.
     - warning: Only valid for FCM legacy HTTP API.
     */
    public var badge: String?
    /**
     Indicates whether each notification message results in a new
     entry on the notification center on Android. If not set, each request
     creates a new notification. If set, and a notification with the same
     tag is already being shown, the new notification replaces the
     existing one in notification center.
     - note: Android: Optional, Apple: Not Available.
     - warning: Only valid for FCM legacy HTTP API.
     */
    public var tag: String?
    /**
     Indicates color of the icon, expressed in #rrggbb format.
     - note: Android: Optional, Apple: Not Available.
     - warning: Only valid for FCM legacy HTTP API.
     */
    public var color: String?
    /**
     The action associated with a user click on the notification. On Android,
     if this is set, an activity with a matching intent filter is launched when
     user clicks the notification.
     - note: Android: Optional, Apple: Optional.
     - warning: Only valid for FCM legacy HTTP API.
     */
    public var clickAction: String?
    /**
     Indicates the key to the body string for localization. On iOS, this
     corresponds to "loc-key" in APNS payload.
     - note: Android: Not Available, Apple: Optional.
     - warning: Only valid for FCM legacy HTTP API.
     */
    public var bodyLocKey: String?
    /**
     Indicates the string value to replace format specifiers in body string
     for localization. On iOS, this corresponds to "loc-args" in APNS payload.
     - note: Android: Not Available, Apple: Optional.
     - warning: Only valid for FCM legacy HTTP API.
     */
    public var bodyLocArgs: [String]?
    /**
     Indicates the string value to replace format specifiers in title string for l
     ocalization. On iOS, this corresponds to "title-loc-args" in APNS payload.
     - note: Android: Not Available, Apple: Optional.
     - warning: Only valid for FCM legacy HTTP API.
     */
    public var titleLocKey: String?
    /**
     Indicates the key to the title string for localization. On iOS, this
     corresponds to "title-loc-key" in APNS payload.
     - note: Android: Not Available, Apple: Optional.
     - warning: Only valid for FCM legacy HTTP API.
     */
    public var titleLocArgs: [String]?
    /**
     The app must create a channel with this channel ID before any
     notification with this channel ID is received.
     - note: Android: Optional, Apple: Not Available.
     - warning: Only valid for FCM legacy HTTP API.
     */
    public var androidChannelId: String?

    enum CodingKeys: String, CodingKey {
        case titleLocKey = "title_loc_key"
        case titleLocArgs = "title_loc_args"
        case bodyLocKey = "body_loc-key"
        case bodyLocArgs = "body-loc-args"
        case clickAction = "click_action"
        case androidChannelId = "android_channel_id"
        case title, icon, body, sound, badge, tag,
            color, subtitle, image
    }

    /**
     Creates a new instance of `ParsePushFirebaseNotification`.
     - parameter title: Indicates notification body text.
     - parameter body: Indicates notification body text.
     - parameter icon: Indicates notification icon. On Android: sets
     value to myicon for drawable resource **myicon.png**. Only valid
     for FCM legacy HTTP API.
     */
    public init(title: String? = nil,
                body: String? = nil,
                icon: String? = nil) {
        self.title = title
        self.body = body
        self.icon = icon
    }

    /**
     Creates a new instance of `ParsePushFirebaseNotification`.
     - parameter title: Indicates notification body text.
     - parameter body: Indicates notification body text.
     - parameter image: Contains the URL of an image that is going
     to be downloaded on the device and displayed in a notification. JPEG,
     PNG, BMP have full support across platforms. Animated GIF and
     video only work on iOS. WebP and HEIF have varying levels of support
     across platforms and platform versions. Android has 1MB image size
     limit. Only valid for FCM HTTP v1 API.
     */
    public init(title: String? = nil,
                body: String? = nil,
                image: String?) {
        self.title = title
        self.body = body
        self.image = image
    }
}
