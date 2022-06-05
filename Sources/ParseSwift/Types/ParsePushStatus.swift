//
//  ParsePushStatus.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/30/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public struct ParsePushStatus<U: ParseObject>: ParsePushStatusable {
    public typealias QueryObject = U

    public var originalData: Data?

    public var objectId: String?

    public var createdAt: Date?

    public var updatedAt: Date?

    public var ACL: ParseACL?

    public var query: Query<U>?

    public var pushTime: String?

    public var source: String?

    public var payload: String?

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
             sentPerType, errorMessage, pushHash, numFailed, numSent, status,
             expiry, title, payload, source, pushTime, query
    }
}
