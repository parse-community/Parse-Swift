//
//  ParseType.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/31/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

public protocol ParseType: Encodable {}

// MARK: CustomDebugStringConvertible
extension ParseType {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "()"
        }

        return "\(descriptionString)"
    }
}

// MARK: CustomStringConvertible
extension ParseType {
    public var description: String {
        debugDescription
    }
}
