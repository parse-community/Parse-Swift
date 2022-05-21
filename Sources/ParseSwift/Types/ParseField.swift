//
//  ParseField.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

struct ParseField: Codable {
    var type: ParseFieldType
    var required: Bool?
    var defaultValue: AnyCodable?
    var targetClass: String?

    init<V>(type: ParseFieldType, options: ParseFieldOptions<V>) where V: Codable {
        self.type = type
        self.required = options.required
        self.defaultValue = AnyCodable(options.defaultValue)
    }

    init<V>(type: ParseFieldType, options: ParseFieldOptions<V>) throws where V: ParseObject {
        self.type = type
        self.required = options.required
        self.defaultValue = AnyCodable(try options.defaultValue?.toPointer())
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
        self.defaultValue = AnyCodable(options.defaultValue)
    }

    init<T, V>(type: ParseFieldType,
               target: Pointer<T>? = nil,
               options: ParseFieldOptions<V>) where T: ParseObject, V: Codable {
        self.type = type
        self.targetClass = target?.className
        self.required = options.required
        self.defaultValue = AnyCodable(options.defaultValue)
    }

    init<T, V>(type: ParseFieldType,
               target: T? = nil,
               options: ParseFieldOptions<V>) throws where T: ParseObject, V: ParseObject {
        self.type = type
        self.targetClass = target?.className
        self.required = options.required
        self.defaultValue = AnyCodable(try options.defaultValue?.toPointer())
    }

    init<T, V>(type: ParseFieldType,
               target: Pointer<T>? = nil,
               options: ParseFieldOptions<V>) throws where T: ParseObject, V: ParseObject {
        self.type = type
        self.targetClass = target?.className
        self.required = options.required
        self.defaultValue = AnyCodable(try options.defaultValue?.toPointer())
    }
}

public struct ParseFieldOptions<V: Codable>: Codable {
    var required: Bool = false
    var defaultValue: V?
}

public enum ParseFieldType: String, Codable {
    case string = "String"
    case number = "Number"
    case boolean = "Boolean"
    case date = "Date"
    case file = "File"
    case geoPoint = "GeoPoint"
    case polygon = "Polygon"
    case array = "Array"
    case object = "Object"
    case pointer = "Pointer"
    case relation = "Relation"
    case bytes = "Bytes"
    case acl = "ACL"
}
