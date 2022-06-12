//
//  ParsePushPayloadDatable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/5/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 A protocol for making push notification payloads.
 See `ParsePushPayloadApple` or `ParsePushPayloadFirebase` for examples.
 */
public protocol ParsePushPayloadable: Codable, Equatable, CustomDebugStringConvertible, CustomStringConvertible {

    /// Creates an empty payload.
    init()
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
