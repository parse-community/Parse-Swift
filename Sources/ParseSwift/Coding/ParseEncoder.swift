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

// MARK: ParseEncoder
public struct ParseEncoder {
    let dateEncodingStrategy: AnyCodable.DateEncodingStrategy?
    let jsonEncoder: JSONEncoder
    let skippedKeys: Set<String>

    init(
        dateEncodingStrategy: AnyCodable.DateEncodingStrategy? = nil,
        jsonEncoder: JSONEncoder = JSONEncoder(),
        skippingKeys: Set<String> = []
    ) {
        self.dateEncodingStrategy = dateEncodingStrategy
        self.jsonEncoder = jsonEncoder
        self.skippedKeys = skippingKeys
    }

    func encodeToDictionary<T: Encodable>(_ value: T) throws -> [AnyHashable: Any] {
        let encoder = _ParseEncoder(codingPath: [], dictionary: NSMutableDictionary(), skippingKeys: skippedKeys)
        try value.encode(to: encoder)

        // swiftlint:disable:next force_cast
        return encoder.dictionary as! [AnyHashable: Any]
    }

    func encode<T: Encodable>(_ value: T) throws -> Data {
        let dictionary = try encodeToDictionary(value)
        return try jsonEncoder.encode(AnyCodable(dictionary, dateEncodingStrategy: dateEncodingStrategy!))
    }

    func encode<T: Encodable>(_ array: [T]) throws -> Data {
        let dictionaries = try array.map { try encodeToDictionary($0) }
        return try jsonEncoder.encode(AnyCodable(dictionaries, dateEncodingStrategy: dateEncodingStrategy!))
    }
}

// MARK: _ParseEncoder
internal struct _ParseEncoder: Encoder {
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
        let container = _ParseEncoderKeyedEncodingContainer<Key>(
            codingPath: codingPath,
            dictionary: dictionary,
            skippingKeys: skippedKeys
        )

        return KeyedEncodingContainer(container)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        _ParseEncoderSingleValueEncodingContainer(
            codingPath: codingPath,
            dictionary: dictionary,
            skippingKeys: skippedKeys
        )
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        _ParseEncoderUnkeyedEncodingContainer(
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
             is Float, is Double, is String, is Date:
            return value
        default:
            let dictionary = NSMutableDictionary()
            let encoder = _ParseEncoder(codingPath: codingPath, dictionary: dictionary, skippingKeys: skippedKeys)
            try value.encode(to: encoder)

            return codingPath.last.map { dictionary[$0.stringValue] ?? dictionary } ?? dictionary
        }
    }
}

// MARK: _ParseEncoderKeyedEncodingContainer
internal struct _ParseEncoderKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
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

        dictionary[key.stringValue] = try _ParseEncoder.encode(
            value,
            with: codingPath + [key],
            skippingKeys: skippedKeys
        )
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let container = _ParseEncoderKeyedEncodingContainer<NestedKey>(
            codingPath: codingPath + [key],
            dictionary: dictionary,
            skippingKeys: skippedKeys
        )

        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        _ParseEncoderUnkeyedEncodingContainer(
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

// MARK: _ParseEncoderSingleValueEncodingContainer
internal struct _ParseEncoderSingleValueEncodingContainer: SingleValueEncodingContainer {
    let codingPath: [CodingKey]
    let dictionary: NSMutableDictionary
    let skippedKeys: Set<String>

    init(codingPath: [CodingKey], dictionary: NSMutableDictionary, skippingKeys: Set<String>) {
        self.codingPath = codingPath
        self.dictionary = dictionary
        self.skippedKeys = skippingKeys
    }

    var key: String {
        codingPath.last?.stringValue ?? "<root>"
    }

    mutating func encodeNil() throws {
        dictionary[key] = nil
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        dictionary[key] = try _ParseEncoder.encode(value, with: codingPath, skippingKeys: skippedKeys)
    }
}

// MARK: _ParseEncoderUnkeyedEncodingContainer
internal struct _ParseEncoderUnkeyedEncodingContainer: UnkeyedEncodingContainer {
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
        codingPath.last?.stringValue ?? "<root>"
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
        let encoded = try _ParseEncoder.encode(value, with: codingPath, skippingKeys: skippedKeys)
        array.add(encoded)
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let dictionary = NSMutableDictionary()
        array.add(dictionary)

        let container = _ParseEncoderKeyedEncodingContainer<NestedKey>(
            codingPath: codingPath,
            dictionary: dictionary,
            skippingKeys: skippedKeys
        )

        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let dictionary = NSMutableDictionary()
        array.add(dictionary)

        return _ParseEncoderUnkeyedEncodingContainer(
            codingPath: codingPath,
            dictionary: dictionary,
            skippingKeys: skippedKeys
        )
    }

    mutating func superEncoder() -> Encoder {
        fatalError()
    }
}
