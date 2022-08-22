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
public struct ParsePushStatus<V: ParsePushPayloadable>: ParsePushStatusable {
    public typealias PayloadType = V

    public var originalData: Data?

    public var objectId: String?

    public var createdAt: Date?

    public var updatedAt: Date?

    public var ACL: ParseACL?

    public var query: QueryWhere?

    public var pushTime: Date?

    public var source: String?

    public var payload: PayloadType?

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

    enum CodingKeys: String, CodingKey {
        case expirationInterval = "expiration_interval"
        case objectId, createdAt, updatedAt, ACL
        case count, failedPerUTCOffset, sentPerUTCOffset,
             sentPerType, failedPerType, errorMessage, pushHash,
             numFailed, numSent, status, expiry, title, source,
             pushTime, query, payload
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        objectId = try values.decodeIfPresent(String.self, forKey: .objectId)
        createdAt = try values.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try values.decodeIfPresent(Date.self, forKey: .updatedAt)
        ACL = try values.decodeIfPresent(ParseACL.self, forKey: .ACL)
        count = try values.decodeIfPresent(Int.self, forKey: .count)
        failedPerUTCOffset = try values.decodeIfPresent([String: Int].self, forKey: .failedPerUTCOffset)
        sentPerUTCOffset = try values.decodeIfPresent([String: Int].self, forKey: .sentPerType)
        sentPerType = try values.decodeIfPresent([String: Int].self, forKey: .sentPerType)
        failedPerType = try values.decodeIfPresent([String: Int].self, forKey: .failedPerType)
        errorMessage = try values.decodeIfPresent(ParseError.self, forKey: .errorMessage)
        pushHash = try values.decodeIfPresent(String.self, forKey: .pushHash)
        numFailed = try values.decodeIfPresent(Int.self, forKey: .numFailed)
        numSent = try values.decodeIfPresent(Int.self, forKey: .numSent)
        status = try values.decodeIfPresent(String.self, forKey: .status)
        expiry = try values.decodeIfPresent(Int.self, forKey: .expiry)
        title = try values.decodeIfPresent(String.self, forKey: .title)
        source = try values.decodeIfPresent(String.self, forKey: .source)
        pushTime = try values.decodeIfPresent(Date.self, forKey: .pushTime)
        expirationInterval = try values.decodeIfPresent(String.self, forKey: .expirationInterval)
        // Handle when Parse Server sends doubly encoded fields.
        do {
            // Attempt the correct decoding first.
            payload = try values.decodeIfPresent(PayloadType.self, forKey: .payload)
        } catch {
            let payloadString = try values.decode(String.self, forKey: .payload)
            guard let payloadData = payloadString.data(using: .utf8) else {
                throw ParseError(code: .unknownError, message: "Could not decode payload")
            }
            payload = try ParseCoding.jsonDecoder().decode(PayloadType.self, from: payloadData)
        }
        do {
            // Attempt the correct decoding first.
            query = try values.decodeIfPresent(QueryWhere.self, forKey: .query)
        } catch {
            let queryString = try values.decode(String.self, forKey: .query)
            guard let queryData = queryString.data(using: .utf8) else {
                throw ParseError(code: .unknownError, message: "Could not decode query")
            }
            query = try ParseCoding.jsonDecoder().decode(QueryWhere.self, from: queryData)
        }
    }
}
