//
//  ParseHookable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/15/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 Hooks and Triggers should conform to `ParseHookable`.
 */
public protocol ParseHookable: ParseTypeable {
    /// The endpoint of the hook.
    var url: URL? { get set }

    /// Create an empty initializer.
    init()
}

extension ParseHookable {
    static func checkHookKey(_ data: Data) throws -> Data {
        guard let clientHookKey = ParseSwift.configuration.hookKey else {
            return data
        }
        let hookResponse = try ParseCoding.jsonDecoder().decode(HookResponse.self, from: data)
        guard clientHookKey == hookResponse.hookKey else {
            throw ParseError(code: .unknownError, message: "Web hook keys do not match")
        }
        return hookResponse.data
    }
}
