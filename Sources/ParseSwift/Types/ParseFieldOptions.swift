//
//  ParseFieldOptions.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/29/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/// The options for a field in `ParseSchema`
public struct ParseFieldOptions<V: Codable>: Codable {
    /// Specifies if a field is required.
    public var required: Bool = false

    /// The default value for a field.
    public var defaultValue: V?

    /**
     Create new options for a `ParseSchema` field.
     - parameter required: Specify if the field is required. Defaults to **false**.
     - parameter defauleValue: The default value for the field. Defaults to **nil**.
     */
    public init(required: Bool = false, defauleValue: V? = nil) {
        self.required = required
        self.defaultValue = defauleValue
    }
}

extension ParseFieldOptions where V: ParseObject {
    /**
     Create new options for a `ParseSchema` field.
     - parameter required: Specify if the field is required. Defaults to **false**.
     - parameter defauleValue: The default value for the field. Defaults to **nil**.
     - throws: An error of `ParseError` type.
     */
    public init(required: Bool = false, defauleValue: V? = nil) throws {
        self.required = required
        self.defaultValue = try defauleValue?.toPointer().toObject()
    }
}

// MARK: CustomDebugStringConvertible
extension ParseFieldOptions {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "()"
        }

        return "\(descriptionString)"
    }
}

// MARK: CustomStringConvertible
extension ParseFieldOptions {
    public var description: String {
        debugDescription
    }
}
