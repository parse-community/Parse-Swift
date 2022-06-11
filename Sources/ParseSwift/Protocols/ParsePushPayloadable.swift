//
//  ParsePushPayloadDatable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/5/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 A protocol for adding the standard properties for push notifications.
 - warning: You will also need to implement `CodingKeys`,
 see `ParsePushPayloadData` for an example.
 */
public protocol ParsePushPayloadable: Codable, Equatable, CustomDebugStringConvertible, CustomStringConvertible {
    /**
     The UNIX timestamp when the notification should expire.
     If the notification cannot be delivered to the device, will retry until it expires.
     An expiry of **0** indicates that the notification expires immediately, therefore
     no retries will be attempted.
     - note: This shouldn't be set directly using a **Date** type. Instead it should
     be set using `expirationDate`.
     */
    var expirationTime: TimeInterval? { get set }

    /**
     The date when the notification should expire.
     If the notification cannot be delivered to the device, will retry until it expires.
     - note: This takes any date and turns it into a UNIX timestamp and sets the
     value of `expirationTime`.
     */
    var expirationDate: Date? { get set }

    /// Initialize an empty payload.
    init()
}

public extension ParsePushPayloadable {
    init() {
        self.init()
    }

    var expirationDate: Date? {
        get {
            guard let interval = expirationTime else {
                return nil
            }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            expirationTime = newValue?.timeIntervalSince1970
        }
    }
}

// MARK: CustomDebugStringConvertible
extension ParsePushPayloadable {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
            return "ParsePushPayloadable ()"
        }
        return "ParsePushPayloadable (\(descriptionString))"
    }
}

// MARK: CustomStringConvertible
extension ParsePushPayloadable {
    public var description: String {
        debugDescription
    }
}
