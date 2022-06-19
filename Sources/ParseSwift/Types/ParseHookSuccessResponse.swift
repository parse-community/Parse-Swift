//
//  ParseHookResponseSuccess.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 Build a successful response to return from a `ParseHook`.
 */
public struct ParseHookSuccessResponse<R: Codable & Equatable>: ParseTypeable {
    /// The data to return in the response.
    public let success: R
}

public extension ParseHookSuccessResponse {
    /**
     Create a successful response to a `ParseHook`.
     - parameter success: The data to return in the response.
     */
    init(_ success: R) {
        self.success = success
    }
}
