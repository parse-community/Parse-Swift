//
//  ParsePushPayload.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/4/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/// A `ParsePushStatusable` payload.
public struct ParsePushPayload: Codable, Hashable {
    /// The data of the payload.
    var data: ParsePushPayloadData?
}

public struct ParsePushPayloadData: Codable, Hashable {
    /// The alert message.
    var alert: String?
    /// The badge number.
    var badge: Int?
}
