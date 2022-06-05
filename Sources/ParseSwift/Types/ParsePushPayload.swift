//
//  ParsePushPayload.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/4/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/// A `ParsePushStatusable` payload.
public struct ParsePushPayload<V: ParsePushPayloadDatable>: Codable, Equatable {
    /// The data of the payload.
    public var data: V?
}
