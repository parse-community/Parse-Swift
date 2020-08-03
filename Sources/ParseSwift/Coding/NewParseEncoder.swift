//
//  NewParseEncoder.swift
//  ParseSwift
//
//  Created by Pranjal Satija on 7/20/20.
//  Copyright © 2020 Parse. All rights reserved.
//

// This rule doesn't allow types with underscores in their names.
// swiftlint:disable type_name

import Foundation

public struct NewParseEncoder {
    func encode<T: Encodable>(_ value: T) throws -> [AnyHashable: Any] {
        let encoder = _NewParseEncoder(codingPath: [], dictionary: NSMutableDictionary())
        try value.encode(to: encoder)

        // swiftlint:disable:next force_cast
        return encoder.dictionary as! [AnyHashable: Any]
    }
}

internal struct _NewParseEncoder: Encoder {
    let codingPath: [CodingKey]
    let dictionary: NSMutableDictionary
    let userInfo: [CodingUserInfoKey: Any] = [:]

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let container = _NewParseEncoderKeyedEncodingContainer<Key>(codingPath: codingPath, dictionary: dictionary)
        return KeyedEncodingContainer(container)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        _NewParseEncoderSingleValueEncodingContainer(codingPath: codingPath, dictionary: dictionary)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        _NewParseEncoderUnkeyedEncodingContainer(codingPath: codingPath, dictionary: dictionary)
    }
}

internal struct _NewParseEncoderKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let codingPath: [CodingKey]
    let dictionary: NSMutableDictionary

    mutating func encodeNil(forKey key: Key) throws {
        dictionary[key.stringValue] = nil
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        dictionary[key.stringValue] = value
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let container = _NewParseEncoderKeyedEncodingContainer<NestedKey>(
            codingPath: codingPath + [key],
            dictionary: dictionary
        )

        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        _NewParseEncoderUnkeyedEncodingContainer(codingPath: codingPath + [key], dictionary: dictionary)
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

    var key: String {
        codingPath.last?.stringValue ?? "_"
    }

    mutating func encodeNil() throws {
        dictionary.setValue(nil, forKey: key)
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        dictionary.setValue(value, forKey: key)
    }
}

internal struct _NewParseEncoderUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    let codingPath: [CodingKey]
    let dictionary: NSMutableDictionary

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

    init(codingPath: [CodingKey], dictionary: NSMutableDictionary) {
        self.codingPath = codingPath
        self.dictionary = dictionary

        self.array = NSMutableArray()
    }

    mutating func encodeNil() throws {
        array.add(NSNull())
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        let encoder = _NewParseEncoder(codingPath: codingPath, dictionary: NSMutableDictionary())
        try value.encode(to: encoder)

        array.add(encoder.dictionary)
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let dictionary = NSMutableDictionary()
        array.add(dictionary)

        let container = _NewParseEncoderKeyedEncodingContainer<NestedKey>(
            codingPath: codingPath,
            dictionary: dictionary
        )

        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let dictionary = NSMutableDictionary()
        array.add(dictionary)

        return _NewParseEncoderUnkeyedEncodingContainer(codingPath: codingPath, dictionary: dictionary)
    }

    mutating func superEncoder() -> Encoder {
        fatalError()
    }
}
