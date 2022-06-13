//
//  ParsePushApplePayloadable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/8/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 A protocol for adding the standard properties for Apple push notifications.
 - warning: You should add `alert`, `badge`, and `sound` properties to your type.
 They are not provided by default as they need to be type erased. You will also
 need to implement `CodingKeys`, see `ParsePushPayloadApple` for an example.
 */
public protocol ParsePushApplePayloadable: ParsePushPayloadable {
    /**
     The payload for displaying an alert.
     */
    var alert: ParsePushAppleAlert? { get set }
    /**
     The destination topic for the notification.
     */
    var topic: String? { get set }
    /**
     Multiple notifications with same collapse identifier are displayed to the user as a single
     notification. The value should not exceed 64 bytes.
     */
    var collapseId: String? { get set }
    /**
     The type of the notification. The value is alert or background. Specify alert when the
     delivery of your notification displays an alert, plays a sound, or badges your app’s icon.
     Specify background for silent notifications that do not interact with the user.
     Defaults to alert if no value is set.
     - warning: Required when delivering notifications to
     devices running iOS 13 and later, or watchOS 6 and later. Ignored on earlier OS versions.
     */
    var pushType: ParsePushPayloadApple.PushType? { get set }
    /**
     The identifier of the `UNNotification​Category` for this push notification.
     See Apple's
     [documentation](https://developer.apple.com/documentation/usernotifications/unnotificationcategory)
     for more information.
     */
    var category: String? { get set }
    /**
     Used for Safari Push Notifications and should be an array of values. See the
     [Notification Programming Guide for Websites](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/NotificationProgrammingGuideForWebsites/PushNotifications/PushNotifications.html#//apple_ref/doc/uid/TP40013225-CH3-SW12).
     */
    var urlArgs: [String]? { get set }
    /**
     The identifier of the window brought forward. The value of this key will be populated
     on the [UNNotificationContent](https://developer.apple.com/documentation/usernotifications/unnotificationcontent)
     object created from the push payload. Access the value
     using the UNNotificationContent object’s [targetContentIdentifier](https://developer.apple.com/documentation/usernotifications/unnotificationcontent/3235764-targetcontentidentifier)
     property.
     */
    var targetContentId: String? { get set }
    /**
     An app-specific identifier for grouping related notifications. This value corresponds
     to the [threadIdentifier](https://developer.apple.com/documentation/usernotifications/unmutablenotificationcontent/1649872-threadidentifier)
     property in the UNNotificationContent object.
     */
    var threadId: String? { get set }
    /**
     A string that indicates the importance and delivery timing of a notification.
     The string values “passive”, “active”, “time-sensitive”, or “critical” correspond
     to the [UNNotificationInterruptionLevel](https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel)
     enumeration cases.
     */
    var interruptionLevel: String? { get set }
    /**
     The relevance score, a number between 0 and 1, that the system uses to
     sort the notifications from your app. The highest score gets featured in the
     notification summary. See [relevanceScore](https://developer.apple.com/documentation/usernotifications/unnotificationcontent/3821031-relevancescore).
     */
    var relevanceScore: Double? { get set }
    /**
     Specify for the `mdm` field where applicable.
     */
    var mdm: String? { get set }
}
