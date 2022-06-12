//
//  ParsePushPayloadFirebase.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/8/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 The payload data for an Firebase Cloud Messaging (FCM) push notification.
 See [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging/http-server-ref)
 documentation for more information.
 */
public struct ParsePushPayloadFirebase: ParsePushFirebasePayloadable {
    /**
     The delivery priority to downstream messages. Can be either
     **normal** or **high** priority. On Apple platforms,
     these correspond to APNs priorities 5 and 10.
     */
    public var priority: Self.PushPriority?
    /**
     On Apple platforms, use this field to represent content-available
     in the APNs payload. When a notification or message is sent and
     this is set to true, an inactive client app is awoken, and the message
     is sent through APNs as a silent notification and not through FCM.
     - note: Silent notifications in APNs are not guaranteed to be
     delivered, and can depend on factors such as the user turning on
     Low Power Mode, force quitting the app, etc. On Android, data
     messages wake the app by default. On Chrome, currently not supported.
     */
    public var contentAvailable: Bool?
    /**
     On Apple platforms, use this field to represent mutable-content in
     the APNs payload.
     */
    public var mutableContent: Bool?
    public var uri: URL?
    public var title: String?
    public var collapseKey: String?
    public var delayWhileIdle: Bool?
    public var restrictedPackageName: String?
    public var dryRun: Bool?
    public var data: [String: String]?
    public var notification: ParsePushFirebaseNotification?

    /// The priority type of a notification.
    public enum PushPriority: String, Codable {
        /// Sets the priority to **5**.
        case normal
        /// Sets the priority to **10**.
        case high
    }

    public init() { }

    /**
     Create a new instance of `ParsePushPayloadFirebase`.
     - parameter notification: The predefined, user-visible notification payload.
     */
    public init(notification: ParsePushFirebaseNotification) {
        self.notification = notification
    }

    enum CodingKeys: String, CodingKey {
        case priority, contentAvailable, title, uri,
             collapseKey, delayWhileIdle, restrictedPackageName,
             dryRun, data, notification, mutableContent
    }
}
