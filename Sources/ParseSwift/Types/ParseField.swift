//
//  ParseField.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/// A type used to create internal fields for `ParseSchema`.
public struct ParseField: ParseTypeable {
    var __op: Operation? // swiftlint:disable:this identifier_name
    var type: FieldType?
    var required: Bool?
    var defaultValue: AnyCodable?
    var targetClass: String?

    /// Field types available in `ParseSchema`.
    public enum FieldType: String, Codable {
        /// A string type.
        case string = "String"
        /// A number type.
        case number = "Number"
        /// A boolean type.
        case boolean = "Boolean"
        /// A date type.
        case date = "Date"
        /// A file type.
        case file = "File"
        /// A geoPoint type.
        case geoPoint = "GeoPoint"
        /// A polygon type.
        case polygon = "Polygon"
        /// An array type.
        case array = "Array"
        /// An object type.
        case object = "Object"
        /// A pointer type.
        case pointer = "Pointer"
        /// A relation type.
        case relation = "Relation"
        /// A bytes type.
        case bytes = "Bytes"
        /// A acl type.
        case acl = "ACL"
    }

    init(operation: Operation) {
        __op = operation
    }

    init<V>(type: FieldType, options: ParseFieldOptions<V>) where V: Codable {
        self.type = type
        self.required = options.required
        if let defaultValue = options.defaultValue {
            self.defaultValue = AnyCodable(defaultValue)
        }
    }

    init<T>(type: FieldType,
            options: ParseFieldOptions<T>) where T: ParseObject {
        self.type = type
        self.targetClass = T.className
        self.required = options.required
        if let defaultValue = options.defaultValue {
            self.defaultValue = AnyCodable(defaultValue)
        }
    }
}
