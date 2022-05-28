//
//  ParseField.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

struct ParseField: Codable {
    var __op: Operation? // swiftlint:disable:this identifier_name
    var type: ParseFieldType?
    var required: Bool?
    var defaultValue: AnyCodable?
    var targetClass: String?

    init(operation: Operation) {
        __op = operation
    }

    init<V>(type: ParseFieldType, options: ParseFieldOptions<V>) where V: Codable {
        self.type = type
        self.required = options.required
        if let defaultValue = options.defaultValue {
            self.defaultValue = AnyCodable(defaultValue)
        }
    }

    init<V>(type: ParseFieldType, options: ParseFieldOptions<V>) throws where V: ParseObject {
        self.type = type
        self.required = options.required
        if let defaultValue = options.defaultValue {
            self.defaultValue = AnyCodable(try defaultValue.toPointer())
        }
    }

    init<T>(type: ParseFieldType,
            target: T? = nil) where T: ParseObject {
        self.type = type
        self.targetClass = target?.className
    }

    init<T>(type: ParseFieldType,
            target: Pointer<T>? = nil) where T: ParseObject {
        self.type = type
        self.targetClass = target?.className
    }

    init<T, V>(type: ParseFieldType,
               target: T? = nil,
               options: ParseFieldOptions<V>) where T: ParseObject, V: Codable {
        self.type = type
        self.targetClass = target?.className
        self.required = options.required
        if let defaultValue = options.defaultValue {
            self.defaultValue = AnyCodable(defaultValue)
        }
    }

    init<T, V>(type: ParseFieldType,
               target: Pointer<T>? = nil,
               options: ParseFieldOptions<V>) where T: ParseObject, V: Codable {
        self.type = type
        self.targetClass = target?.className
        self.required = options.required
        if let defaultValue = options.defaultValue {
            self.defaultValue = AnyCodable(defaultValue)
        }
    }

    init<T, V>(type: ParseFieldType,
               target: T? = nil,
               options: ParseFieldOptions<V>) throws where T: ParseObject, V: ParseObject {
        self.type = type
        self.targetClass = target?.className
        self.required = options.required
        if let defaultValue = options.defaultValue {
            self.defaultValue = AnyCodable(try defaultValue.toPointer())
        }
    }

    init<T, V>(type: ParseFieldType,
               target: Pointer<T>? = nil,
               options: ParseFieldOptions<V>) throws where T: ParseObject, V: ParseObject {
        self.type = type
        self.targetClass = target?.className
        self.required = options.required
        if let defaultValue = options.defaultValue {
            self.defaultValue = AnyCodable(try defaultValue.toPointer())
        }
    }
}

// MARK: CustomDebugStringConvertible
extension ParseField {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "()"
        }

        return "(\(descriptionString))"
    }
}

// MARK: CustomStringConvertible
extension ParseField {
    public var description: String {
        debugDescription
    }
}

/// The options for a field in `ParseSchema`
public struct ParseFieldOptions<V: Codable>: Codable {
    /// Specifies if a field is required.
    var required: Bool = false

    /// The default value for a field.
    var defaultValue: V?

    public init(required: Bool = false, defauleValue: V? = nil) {
        self.required = required
        self.defaultValue = defauleValue
    }
}

/// Field types available in `ParseSchema`.
public enum ParseFieldType: String, Codable {
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
