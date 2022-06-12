//
//  ParsePushStatus.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/30/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 Objects that conform to the `ParsePushStatusable` protocol represent
 PushStatus on the Parse Server.
 - warning: These objects are only read-only.
 - requires: `.useMasterKey` has to be available. It is recommended to only
 use the master key in server-side applications where the key is kept secure and not
 exposed to the public.
 */
public protocol ParsePushStatusable: ParseObject {
    /// A type that conforms to `ParsePushPayloadable`.
    associatedtype PushType: ParsePushPayloadable

    /// The time the notification was pushed.
    var pushTime: Date? { get }

    /// The source that created the notification.
    var source: String? { get }

    /// The **where** query used to  select what installations received the notification.
    var query: QueryWhere? { get }

    /// The data sent in the notification.
    var payload: PushType? { get }

    /// The data sent in the notification.
    var title: String? { get }

    /// The date to expire the notification.
    var expiry: Int? { get }

    /// The amount of seconds until the notification expires after scheduling.
    var expirationInterval: String? { get }

    /// The status of the notification.
    var status: String? { get }

    /// The amount of notificaitons sent.
    var numSent: Int? { get }

    /// The amount of notifications that failed.
    var numFailed: Int? { get }

    /// The hash of the alert.
    var pushHash: String? { get }

    /// The associated error message.
    var errorMessage: ParseError? { get }

    /// The amount of notifications sent per type.
    var sentPerType: [String: Int]? { get }

    /// The amount of notifications failed per type.
    var failedPerType: [String: Int]? { get }

    /// The UTC offeset of notifications sent per type.
    var sentPerUTCOffset: [String: Int]? { get }

    /// The UTC offeset of notifications failed per type.
    var failedPerUTCOffset: [String: Int]? { get }

    /// The amount of batches queued.
    var count: Int? { get }

    /// Create a an empty `ParsePushStatus`.
    init()
}

// MARK: Default Implementations
public extension ParsePushStatusable {
    static var className: String {
        "_PushStatus"
    }
}
