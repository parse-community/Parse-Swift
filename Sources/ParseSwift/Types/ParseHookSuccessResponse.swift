//
//  ParseHookResponseSuccess.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 Build a successful response after processing a `ParseHookFunctionRequest`
 or `ParseHookTriggerRequest`.
 */
public struct ParseHookSuccessResponse<R: Codable & Equatable>: ParseTypeable {
    /// The data to return in the response.
    public let success: R
}

public extension ParseHookSuccessResponse {
    /**
     Create a successful response after processing a `ParseHookFunctionRequest`
     or `ParseHookTriggerRequest`.
     - parameter success: The data to return in the response.
     */
    init(_ success: R) {
        self.success = success
    }
}
