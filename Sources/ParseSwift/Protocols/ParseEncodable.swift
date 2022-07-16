//
//  ParseEncodable.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/31/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

/**
 Types that conform to **ParseEncodable** should be encoded by the
 `ParseEncoder` when necessary.
 */
public protocol ParseEncodable: Encodable {}

// MARK: CustomDebugStringConvertible
extension ParseEncodable {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "()"
        }

        return "\(descriptionString)"
    }
}

// MARK: CustomStringConvertible
extension ParseEncodable {
    public var description: String {
        debugDescription
    }
}
