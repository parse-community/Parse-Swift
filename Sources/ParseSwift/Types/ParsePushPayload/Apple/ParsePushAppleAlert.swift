//
//  ParsePushAppleAlert.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/5/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 An alert payload for Apple push notifications. See Apple's [documentation](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification#2943365)
 for more information.
 */
public struct ParsePushAppleAlert: ParseTypeable {
    /**
     The content of the alert message.
     */
    public var body: String?
    /**
     The name of the launch image file to display. If the user chooses to
     launch your app, the contents of the specified image or storyboard file
     are displayed instead of your app’s normal launch image.
     */
    public var launchImage: String?
    /**
     The key for a localized message string. Use this key, instead of the body
     key, to retrieve the message text from your app’s Localizable.strings file.
     The value must contain the name of a key in your strings file.
     */
    public var locKey: String?
    /**
     An array of strings containing replacement values for variables in your
     message text. Each %@ character in the string specified by loc-key is
     replaced by a value from this array. The first item in the array replaces
     the first instance of the %@ character in the string, the second item
     replaces the second instance, and so on.
     */
    public var locArgs: [String]?
    /**
     The title of the notification. Apple Watch displays this string in the short
     look notification interface. Specify a string that’s quickly understood by the user.
     */
    public var title: String?
    /**
     The key for a localized title string. Specify this key instead of the title key to
     retrieve the title from your app’s Localizable.strings files. The value must
     contain the name of a key in your strings file.
     */
    public var titleLocKey: String?
    /**
     An array of strings containing replacement values for variables in your title string.
     Each %@ character in the string specified by the title-loc-key is replaced by a
     value from this array. The first item in the array replaces the first instance of the
     %@ character in the string, the second item replaces the second instance, and so on.
     */
    public var titleLocArgs: [String]?
    /**
     Additional information that explains the purpose of the notification.
     */
    public var subtitle: String?
    /**
     The key for a localized subtitle string. Use this key, instead of the subtitle key, to
     retrieve the subtitle from your app’s Localizable.strings file. The value must contain
     the name of a key in your strings file.
     */
    public var subtitleLocKey: String?
    /**
     An array of strings containing replacement values for variables in your title string.
     Each %@ character in the string specified by subtitle-loc-key is replaced by a value
     from this array. The first item in the array replaces the first instance of the %@
     character in the string, the second item replaces the second instance, and so on.
     */
    public var subtitleLocArgs: [String]?
    public var action: String?
    /**
     If a string is specified, the system displays an alert that includes the Close and
     View buttons. The string is used as a key to get a localized string in the current
     localization to use for the right button’s title instead of “View”. See [Localizing the
     Content of Your Remote Notifications](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html#//apple_ref/doc/uid/TP40008194-CH10-SW9) for more information.
     */
    public var actionLocKey: String?

    /// Create an empty alert.
    public init() { }

    /// Create an alert with a body message.
    /// - parameter body: The message to send in the alert.
    public init(body: String) {
        self.body = body
    }

    enum CodingKeys: String, CodingKey {
        case launchImage = "launch-image"
        case titleLocKey = "title-loc-key"
        case titleLocArgs = "title-loc-args"
        case subtitleLocKey = "subtitle-loc-key"
        case subtitleLocArgs = "subtitle-loc-args"
        case locKey = "loc-key"
        case locArgs = "loc-args"
        case actionLocKey = "action-loc-key"
        case title, subtitle, body, action
    }
}
