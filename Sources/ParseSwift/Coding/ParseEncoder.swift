//
//  ParseEncoder.swift
//  ParseSwift
//
//  Created by Pranjal Satija on 7/20/20.
//  Copyright © 2020 Parse. All rights reserved.
//

// This rule doesn't allow types with underscores in their names.
// swiftlint:disable type_name

import Foundation

public struct ParseEncoder {
    let jsonEncoder: JSONEncoder
    let skippedKeys: Set<String>

    init(jsonEncoder: JSONEncoder = JSONEncoder(), skippingKeys: Set<String> = []) {
        self.jsonEncoder = jsonEncoder
        self.skippedKeys = skippingKeys
    }

    func encodeToDictionary<T: Encodable>(_ value: T) throws -> [AnyHashable: Any] {
        let encoder = _NewParseEncoder(codingPath: [], dictionary: NSMutableDictionary(), skippingKeys: skippedKeys)
        try value.encode(to: encoder)

        // swiftlint:disable:next force_cast
        return encoder.dictionary as! [AnyHashable: Any]
    }

    func encode<T: Encodable>(_ value: T) throws -> Data {
        let dictionary = try encodeToDictionary(value)
        return try jsonEncoder.encode(AnyCodable(dictionary))
    }
}

internal struct _NewParseEncoder: Encoder {
    let codingPath: [CodingKey]
    let dictionary: NSMutableDictionary
    let skippedKeys: Set<String>
    let userInfo: [CodingUserInfoKey: Any] = [:]

    init(codingPath: [CodingKey], dictionary: NSMutableDictionary, skippingKeys: Set<String>) {
        self.codingPath = codingPath
        self.dictionary = dictionary
        self.skippedKeys = skippingKeys
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let container = _NewParseEncoderKeyedEncodingContainer<Key>(
            codingPath: codingPath,
            dictionary: dictionary,
            skippingKeys: skippedKeys
        )

        return KeyedEncodingContainer(container)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        _NewParseEncoderSingleValueEncodingContainer(
            codingPath: codingPath,
            dictionary: dictionary,
            skippingKeys: skippedKeys
        )
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        _NewParseEncoderUnkeyedEncodingContainer(
            codingPath: codingPath,
            dictionary: dictionary,
            skippingKeys: skippedKeys
        )
    }

    static func encode<T: Encodable>(
        _ value: T,
        with codingPath: [CodingKey],
        skippingKeys skippedKeys: Set<String>
    ) throws -> Any {
        switch value {
        case is Bool, is Int, is Int8, is Int16, is Int32, is Int64, is UInt, is UInt8, is UInt16, is UInt32, is UInt64,
             is Float, is Double, is String:
            return value
        default:
            let dictionary = NSMutableDictionary()
            let encoder = _NewParseEncoder(codingPath: codingPath, dictionary: dictionary, skippingKeys: skippedKeys)
            try value.encode(to: encoder)

            return codingPath.last.map { dictionary[$0.stringValue] ?? dictionary } ?? dictionary
        }
    }
}

internal struct _NewParseEncoderKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let codingPath: [CodingKey]
    let dictionary: NSMutableDictionary
    let skippedKeys: Set<String>

    init(codingPath: [CodingKey], dictionary: NSMutableDictionary, skippingKeys: Set<String>) {
        self.codingPath = codingPath
        self.dictionary = dictionary
        self.skippedKeys = skippingKeys
    }

    mutating func encodeNil(forKey key: Key) throws {
        if skippedKeys.contains(key.stringValue) { return }

        dictionary[key.stringValue] = nil
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        if skippedKeys.contains(key.stringValue) { return }

        dictionary[key.stringValue] = try _NewParseEncoder.encode(
            value,
            with: codingPath + [key],
            skippingKeys: skippedKeys
        )
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let container = _NewParseEncoderKeyedEncodingContainer<NestedKey>(
            codingPath: codingPath + [key],
            dictionary: dictionary,
            skippingKeys: skippedKeys
        )

        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        _NewParseEncoderUnkeyedEncodingContainer(
            codingPath: codingPath + [key],
            dictionary: dictionary,
            skippingKeys: skippedKeys
        )
    }

    mutating func superEncoder() -> Encoder {
        fatalError()
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        fatalError()
    }
}

internal struct _NewParseEncoderSingleValueEncodingContainer: SingleValueEncodingContainer {
    let codingPath: [CodingKey]
    let dictionary: NSMutableDictionary
    let skippedKeys: Set<String>

    init(codingPath: [CodingKey], dictionary: NSMutableDictionary, skippingKeys: Set<String>) {
        self.codingPath = codingPath
        self.dictionary = dictionary
        self.skippedKeys = skippingKeys
    }

    var key: String {
        codingPath.last?.stringValue ?? "_"
    }

    mutating func encodeNil() throws {
        dictionary[key] = nil
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        dictionary[key] = try _NewParseEncoder.encode(value, with: codingPath, skippingKeys: skippedKeys)
    }
}

internal struct _NewParseEncoderUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    let codingPath: [CodingKey]
    let dictionary: NSMutableDictionary
    let skippedKeys: Set<String>

    var array: NSMutableArray {
        get {
            // swiftlint:disable:next force_cast
            dictionary[key] as! NSMutableArray
        }

        set { dictionary[key] = newValue }
    }

    var count: Int {
        array.count
    }

    var key: String {
        codingPath.last?.stringValue ?? "_"
    }

    init(codingPath: [CodingKey], dictionary: NSMutableDictionary, skippingKeys: Set<String>) {
        self.codingPath = codingPath
        self.dictionary = dictionary
        self.skippedKeys = skippingKeys

        self.array = NSMutableArray()
    }

    mutating func encodeNil() throws {
        array.add(NSNull())
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        let encoded = try _NewParseEncoder.encode(value, with: codingPath, skippingKeys: skippedKeys)
        array.add(encoded)
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let dictionary = NSMutableDictionary()
        array.add(dictionary)

        let container = _NewParseEncoderKeyedEncodingContainer<NestedKey>(
            codingPath: codingPath,
            dictionary: dictionary,
            skippingKeys: skippedKeys
        )

        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let dictionary = NSMutableDictionary()
        array.add(dictionary)

        return _NewParseEncoderUnkeyedEncodingContainer(
            codingPath: codingPath,
            dictionary: dictionary,
            skippingKeys: skippedKeys
        )
    }

    mutating func superEncoder() -> Encoder {
        fatalError()
    }
}
