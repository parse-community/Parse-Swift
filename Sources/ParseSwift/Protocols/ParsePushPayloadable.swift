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
public protocol ParsePushPayloadable: ParseTypeable {

    /// Creates an empty payload.
    init()
}
