//
//  ParsePushPayloadDatable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/5/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 A protocol for adding the standard properties for push notifications.
 - warning: You should add `alert`, `badge`, and `sound` properties to your type.
 They are not provided by default as they need to be type erased. You will also
 need to implement `CodingKeys`, see `ParsePushPayloadData` for an example.
 */
public protocol ParsePushPayloadDatable: Codable, Equatable {
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
     If you are a writing an app using the Remote Notification Background Mode introduced
     in iOS7 (a.k.a. “Background Push”), set this value to 1 to trigger a background download.
     - warning: For Apple OS's only. You also have to set `pushType` starting iOS 13
     and watchOS 6.
     */
    var contentAvailable: Int? { get set }
    /**
     If you are a writing an app using the Remote Notification Background Mode introduced
     in iOS7 (a.k.a. “Background Push”), set this value to 1 to trigger a background download.
     - warning: For Apple OS's only. You also have to set `pushType` starting iOS 13
     and watchOS 6.
     */
    var mutableContent: Int? { get set }
    /**
     The type of the notification. The value is alert or background. Specify alert when the
     delivery of your notification displays an alert, plays a sound, or badges your app’s icon.
     Specify background for silent notifications that do not interact with the user.
     Defaults to alert if no value is set.
     - warning: For Apple OS's only. Required when delivering notifications to
     devices running iOS 13 and later, or watchOS 6 and later. Ignored on earlier OS versions.
     */
    var pushType: ParsePushPayloadData.PushType? { get set }
    /**
     The priority of the notification. Specify 10 to send the notification immediately.
     Specify 5 to send the notification based on power considerations on the user’s device.
     See Apple's [documentation](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns)
     for more information.
     - warning: For Apple OS's only.
     */
    var priority: Int? { get set }
    /**
     The identifier of the `UNNotification​Category` for this push notification.
     See Apple's
     [documentation](https://developer.apple.com/documentation/usernotifications/unnotificationcategory)
     for more information.
     - warning: For Apple OS's only.
     */
    var category: String? { get set }
    /**
     - warning: For Apple OS's only.
     */
    var urlArgs: [String]? { get set }
    /**
     The identifier of the window brought forward. The value of this key will be populated
     on the [UNNotificationContent](https://developer.apple.com/documentation/usernotifications/unnotificationcontent)
     object created from the push payload. Access the value
     using the UNNotificationContent object’s [targetContentIdentifier](https://developer.apple.com/documentation/usernotifications/unnotificationcontent/3235764-targetcontentidentifier)
     property.
     - warning: For Apple OS's only.
     */
    var targetContentId: String? { get set }
    /**
     An app-specific identifier for grouping related notifications. This value corresponds
     to the [threadIdentifier](https://developer.apple.com/documentation/usernotifications/unmutablenotificationcontent/1649872-threadidentifier)
     property in the UNNotificationContent object.
     - warning: For Apple OS's only.
     */
    var threadId: String? { get set }
    /**
     A string that indicates the importance and delivery timing of a notification.
     The string values “passive”, “active”, “time-sensitive”, or “critical” correspond
     to the [UNNotificationInterruptionLevel](https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel)
     enumeration cases.
     - warning: For Apple OS's only.
     */
    var interruptionLevel: String? { get set }
    /**
     The relevance score, a number between 0 and 1, that the system uses to
     sort the notifications from your app. The highest score gets featured in the
     notification summary. See [relevanceScore](https://developer.apple.com/documentation/usernotifications/unnotificationcontent/3821031-relevancescore).
     - warning: For Apple OS's only.
     */
    var relevanceScore: Double? { get set }
    /**
     - warning: For Apple OS's only.
     */
    var mdm: String? { get set }
    /**
     An optional field that contains a URI. When the notification is opened, an
     Activity associated with opening the URI is launched.
     - warning: For Android only.
     */
    var uri: URL? { get set }
    /**
     The value displayed in the Android system tray notification.
     - warning: For Android only.
     */
    var title: String? { get set }

    /// Initialize an empty payload.
    init()
}

public extension ParsePushPayloadDatable {
    init() {
        self.init()
    }
}
