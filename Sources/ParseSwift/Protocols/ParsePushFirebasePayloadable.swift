//
//  ParsePushFirebasePayloadable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/8/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 A protocol for adding the standard properties for Firebase Cloud Messaging (FCM) push notifications.
 - warning: You will also need to implement `CodingKeys`, see `ParsePushPayloadFirebase` for an example.
 */
public protocol ParsePushFirebasePayloadable: ParsePushPayloadable {
    /**
     An optional field that contains a URI. When the notification is opened, an
     Activity associated with opening the URI is launched.
     */
    var uri: URL? { get set }
    /**
     The value displayed in the Android system tray notification.
     */
    var title: String? { get set }
    /**
     When there is a newer message that renders an older,
     related message irrelevant to the client app, FCM
     replaces the older message.
     */
    var collapseKey: String? { get set }
    /**
     If the device is connected but idle, the message will
     still be delivered right away unless the `delayWhileIdle`
     flag is set to **true**. Otherwise, it will be stored in the
     FCM servers until the device is awake. And that's where
     the `collapseKey` flag plays a role: if there is already a
     message with the same collapse key (and registration ID)
     stored and waiting for delivery, the old message will be
     discarded and the new message will take its place
     (that is, the old message will be collapsed by the new one).
     */
    var delayWhileIdle: Bool? { get set }
    /**
     This parameter specifies the package name of the application where
     the registration tokens must match in order to receive the message.
     */
    var restrictedPackageName: String? { get set }
    /**
     This parameter, when set to **true**, allows developers to test a request
     without actually sending a message.
     */
    var dryRun: Bool? { get set }
    /**
     This parameter specifies the custom key-value pairs of the
     message's payload.
     */
    var data: [String: String]? { get set }
    /**
     The predefined, user-visible notification payload.
     */
    var notification: ParsePushFirebaseNotification? { get set }
}
