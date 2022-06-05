//
//  ParsePushStatus.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/30/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 The PushStatus on the Parse Server.
 - warning: These objects are only read-only.
 - requires: `.useMasterKey` has to be available. It is recommended to only
 use the master key in server-side applications where the key is kept secure and not
 exposed to the public.
 */
public struct ParsePushStatus<U: ParseInstallation>: ParsePushStatusable {
    public typealias InstallationQuery = U

    public var originalData: Data?

    public var objectId: String?

    public var createdAt: Date?

    public var updatedAt: Date?

    public var ACL: ParseACL?

    public var query: Query<U>?

    public var pushTime: Date?

    public var source: String?

    public var payload: ParsePushPayload?

    public var title: String?

    public var expiry: Int?

    public var expirationInterval: String?

    public var status: String?

    public var numSent: Int?

    public var numFailed: Int?

    public var pushHash: String?

    public var errorMessage: ParseError?

    public var sentPerType: [String: Int]?

    public var failedPerType: [String: Int]?

    public var sentPerUTCOffset: [String: Int]?

    public var failedPerUTCOffset: [String: Int]?

    public var count: Int?

    public init() { }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.debugDescription)
    }

    enum CodingKeys: String, CodingKey {
        case expirationInterval = "expiration_interval"
        case objectId, createdAt, updatedAt, ACL
        case count, failedPerUTCOffset, sentPerUTCOffset,
             sentPerType, failedPerType, errorMessage, pushHash,
             numFailed, numSent, status, expiry, title, payload,
             source, pushTime, query
    }
}
