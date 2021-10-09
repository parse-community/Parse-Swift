//
//  ParseEncoder.swift
//  ParseSwift
//
//  Created by Pranjal Satija on 7/20/20.
//  Copyright © 2020 Parse. All rights reserved.
//

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

/// A marker protocol used to determine whether a value is a `String`-keyed `Dictionary`
/// containing `Encodable` values (in which case it should be exempt from key conversion strategies).
///
/// NOTE: The architecture and environment check is due to a bug in the current (2018-08-08) Swift 4.2
/// runtime when running on i386 simulator. The issue is tracked in https://bugs.swift.org/browse/SR-8276
/// Making the protocol `internal` instead of `private` works around this issue.
/// Once SR-8276 is fixed, this check can be removed and the protocol always be made private.
#if arch(i386) || arch(arm)
internal protocol _JSONStringDictionaryEncodableMarker { }
#else
private protocol _JSONStringDictionaryEncodableMarker { }
#endif
extension Dictionary: _JSONStringDictionaryEncodableMarker where Key == String, Value: Encodable { }

// This rule doesn't allow types with underscores in their names.
// swiftlint:disable type_name
// swiftlint:disable colon
// swiftlint:disable force_cast
// swiftlint:disable line_length
// swiftlint:disable return_arrow_whitespace
// swiftlint:disable file_length
// swiftlint:disable redundant_discardable_let
// swiftlint:disable cyclomatic_complexity

// MARK: ParseEncoder
/** An object that encodes Parse instances of a data type as JSON objects.
 - note: `JSONEncoder` facilitates the encoding of `Encodable` values into JSON.
 `ParseEncoder` facilitates the encoding of `ParseType` values into JSON.
 All Credit to Apple, this is a custom encoder with capability of skipping keys at runtime.
 ParseEncoder matches the features of the [Swift 5.4 JSONEncoder ](https://github.com/apple/swift/blob/main/stdlib/public/Darwin/Foundation/JSONEncoder.swift).
 Update commits as needed for improvement.
 */
public struct ParseEncoder {
    let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy?

    /// Keys to skip during encoding.
    public enum SkipKeys {
        /// Skip keys for `ParseObject`'s.
        case object
        /// Skip keys for `ParseCloud` functions or jobs.
        case cloud
        /// Do not skip any keys.
        case none
        /// Skip keys for `ParseObject`'s when using custom `objectId`'s.
        case customObjectId
        /// Specify a custom set of keys to skip.
        case custom(Set<String>)

        func keys() -> Set<String> {
            switch self {

            case .object:
                return Set(["createdAt", "updatedAt", "objectId", "className", "emailVerified", "id"])
            case .customObjectId:
                return Set(["createdAt", "updatedAt", "className", "emailVerified", "id"])
            case .cloud:
                return Set(["functionJobName"])
            case .none:
                return .init()
            case .custom(let keys):
                return keys
            }
        }
    }

    init(
        dateEncodingStrategy: JSONEncoder.DateEncodingStrategy? = nil
    ) {
        self.dateEncodingStrategy = dateEncodingStrategy
    }

    func encode(_ value: Encodable) throws -> Data {
        let encoder = _ParseEncoder(codingPath: [], dictionary: NSMutableDictionary(), skippingKeys: SkipKeys.none.keys())
        if let dateEncodingStrategy = dateEncodingStrategy {
            encoder.dateEncodingStrategy = dateEncodingStrategy
        }
        return try encoder.encodeObject(value,
                                        collectChildren: false,
                                        uniquePointer: nil,
                                        objectsSavedBeforeThisOne: nil,
                                        filesSavedBeforeThisOne: nil).encoded
    }

    /**
     Encodes an instance of the indicated `ParseType`.
     - parameter value: The `ParseType` instance to encode.
     - parameter skipKeys: The set of keys to skip during encoding.
     */
    public func encode<T: ParseType>(_ value: T,
                                     skipKeys: SkipKeys) throws -> Data {
        let encoder = _ParseEncoder(codingPath: [], dictionary: NSMutableDictionary(), skippingKeys: skipKeys.keys())
        if let dateEncodingStrategy = dateEncodingStrategy {
            encoder.dateEncodingStrategy = dateEncodingStrategy
        }
        return try encoder.encodeObject(value,
                                        collectChildren: false,
                                        uniquePointer: nil,
                                        objectsSavedBeforeThisOne: nil,
                                        filesSavedBeforeThisOne: nil).encoded
    }

    // swiftlint:disable large_tuple
    internal func encode<T: ParseObject>(_ value: T,
                                         objectsSavedBeforeThisOne: [String: PointerType]?,
                                         filesSavedBeforeThisOne: [UUID: ParseFile]?) throws -> (encoded: Data, unique: PointerType?, unsavedChildren: [Encodable]) {
        let keysToSkip: Set<String>!
        if !ParseSwift.configuration.allowCustomObjectId {
            keysToSkip = SkipKeys.object.keys()
        } else {
            keysToSkip = SkipKeys.customObjectId.keys()
        }
        let encoder = _ParseEncoder(codingPath: [], dictionary: NSMutableDictionary(), skippingKeys: keysToSkip)
        if let dateEncodingStrategy = dateEncodingStrategy {
            encoder.dateEncodingStrategy = dateEncodingStrategy
        }
        return try encoder.encodeObject(value,
                                        collectChildren: true,
                                        uniquePointer: try? value.toPointer(),
                                        objectsSavedBeforeThisOne: objectsSavedBeforeThisOne,
                                        filesSavedBeforeThisOne: filesSavedBeforeThisOne)
    }

    // swiftlint:disable large_tuple
    internal func encode(_ value: ParseType,
                         collectChildren: Bool,
                         objectsSavedBeforeThisOne: [String: PointerType]?,
                         filesSavedBeforeThisOne: [UUID: ParseFile]?) throws -> (encoded: Data, unique: PointerType?, unsavedChildren: [Encodable]) {
        let keysToSkip: Set<String>!
        if !ParseSwift.configuration.allowCustomObjectId {
            keysToSkip = SkipKeys.object.keys()
        } else {
            keysToSkip = SkipKeys.customObjectId.keys()
        }
        let encoder = _ParseEncoder(codingPath: [], dictionary: NSMutableDictionary(), skippingKeys: keysToSkip)
        if let dateEncodingStrategy = dateEncodingStrategy {
            encoder.dateEncodingStrategy = dateEncodingStrategy
        }
        return try encoder.encodeObject(value,
                                        collectChildren: collectChildren,
                                        uniquePointer: nil,
                                        objectsSavedBeforeThisOne: objectsSavedBeforeThisOne,
                                        filesSavedBeforeThisOne: filesSavedBeforeThisOne)
    }
}

// MARK: _ParseEncoder
private class _ParseEncoder: JSONEncoder, Encoder {
    var codingPath: [CodingKey]
    let dictionary: NSMutableDictionary
    let skippedKeys: Set<String>
    var uniquePointer: PointerType?
    var uniqueFiles = Set<ParseFile>()
    var newObjects = [Encodable]()
    var collectChildren = false
    var objectsSavedBeforeThisOne: [String: PointerType]?
    var filesSavedBeforeThisOne: [UUID: ParseFile]?
    /// The encoder's storage.
    var storage: _ParseEncodingStorage
    var ignoreSkipKeys = false

    /// Options set on the top-level encoder to pass down the encoding hierarchy.
    fileprivate struct _Options {
        let dateEncodingStrategy: DateEncodingStrategy
        let dataEncodingStrategy: DataEncodingStrategy
        let nonConformingFloatEncodingStrategy: NonConformingFloatEncodingStrategy
        let keyEncodingStrategy: KeyEncodingStrategy
        let userInfo: [CodingUserInfoKey: Any]
    }

    /// The options set on the top-level encoder.
    fileprivate var options: _Options {
        return _Options(dateEncodingStrategy: dateEncodingStrategy,
                        dataEncodingStrategy: dataEncodingStrategy,
                        nonConformingFloatEncodingStrategy: nonConformingFloatEncodingStrategy,
                        keyEncodingStrategy: keyEncodingStrategy,
                        userInfo: userInfo)
    }

    init(codingPath: [CodingKey], dictionary: NSMutableDictionary, skippingKeys: Set<String>) {
        self.codingPath = codingPath
        self.dictionary = dictionary
        self.skippedKeys = skippingKeys
        self.storage = _ParseEncodingStorage()
        super.init()
    }

    /// Returns whether a new element can be encoded at this coding path.
    ///
    /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
    var canEncodeNewValue: Bool {
        // Every time a new value gets encoded, the key it's encoded for is pushed onto the coding path (even if it's a nil key from an unkeyed container).
        // At the same time, every time a container is requested, a new value gets pushed onto the storage stack.
        // If there are more values on the storage stack than on the coding path, it means the value is requesting more than one container, which violates the precondition.
        //
        // This means that anytime something that can request a new container goes onto the stack, we MUST push a key onto the coding path.
        // Things which will not request containers do not need to have the coding path extended for them (but it doesn't matter if it is, because they will not reach here).
        return self.storage.count == self.codingPath.count
    }

    @available(*, unavailable)
    override func encode<T : Encodable>(_ value: T) throws -> Data {
        throw ParseError(code: .unknownError, message: "This method shouldn't be used. Either use the JSONEncoder or if you are encoding a ParseObject use \"encodeObject\"")
    }

    func encodeObject(_ value: Encodable,
                      collectChildren: Bool,
                      uniquePointer: PointerType?,
                      objectsSavedBeforeThisOne: [String: PointerType]?,
                      filesSavedBeforeThisOne: [UUID: ParseFile]?) throws -> (encoded: Data, unique: PointerType?, unsavedChildren: [Encodable]) {

        let encoder = _ParseEncoder(codingPath: codingPath, dictionary: dictionary, skippingKeys: skippedKeys)
        encoder.collectChildren = collectChildren
        encoder.outputFormatting = outputFormatting
        encoder.dateEncodingStrategy = dateEncodingStrategy
        encoder.dataEncodingStrategy = dataEncodingStrategy
        encoder.nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy
        encoder.keyEncodingStrategy = keyEncodingStrategy
        encoder.userInfo = userInfo
        encoder.objectsSavedBeforeThisOne = objectsSavedBeforeThisOne
        encoder.filesSavedBeforeThisOne = filesSavedBeforeThisOne
        encoder.uniquePointer = uniquePointer

        guard let topLevel = try encoder.box_(value) else {
            throw EncodingError.invalidValue(value,
                                             EncodingError.Context(codingPath: [], debugDescription: "Top-level \(value) did not encode any values."))
        }

        let writingOptions = JSONSerialization.WritingOptions(rawValue: self.outputFormatting.rawValue).union(.fragmentsAllowed)
        do {
            let serialized = try JSONSerialization.data(withJSONObject: topLevel, options: writingOptions)
            return (serialized, encoder.uniquePointer, encoder.newObjects)
        } catch {
            throw EncodingError.invalidValue(value,
                                             EncodingError.Context(codingPath: [], debugDescription: "Unable to encode the given top-level value to JSON.", underlyingError: error))
        }
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {

        // If an existing keyed container was already requested, return that one.
        let topContainer: NSMutableDictionary
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = self.storage.pushKeyedContainer()
        } else {
            guard let container = self.storage.containers.last as? NSMutableDictionary else {
                preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }

            topContainer = container
        }

        let container = _ParseEncoderKeyedEncodingContainer<Key>(
            referencing: self, codingPath: codingPath,
            wrapping: topContainer
        )

        return KeyedEncodingContainer(container)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        self
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        // If an existing unkeyed container was already requested, return that one.
        let topContainer: NSMutableArray
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = self.storage.pushUnkeyedContainer()
        } else {
            guard let container = self.storage.containers.last as? NSMutableArray else {
                preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
            }

            topContainer = container
        }

        return _ParseEncoderUnkeyedEncodingContainer(
            referencing: self,
            codingPath: codingPath,
            wrapping: topContainer
        )
    }

    func deepFindAndReplaceParseObjects(_ value: Encodable) throws -> Encodable? {
        var valueToEncode: Encodable?
        if let pointer = value as? ParsePointer {
            if let uniquePointer = self.uniquePointer,
               uniquePointer.hasSameObjectId(as: pointer) {
                throw ParseError(code: .unknownError,
                                 message: "Found a circular dependency when encoding.")
            }
            if !self.collectChildren && codingPath.count > 0 {
                valueToEncode = value
            } else {
                valueToEncode = pointer
            }
        } else if let object = value as? Objectable,
                  let pointer = try? PointerType(object) {
            if let uniquePointer = self.uniquePointer,
               uniquePointer.hasSameObjectId(as: pointer) {
                throw ParseError(code: .unknownError,
                                 message: "Found a circular dependency when encoding.")
            }
            if !self.collectChildren && codingPath.count > 0 {
                valueToEncode = value
            } else {
                valueToEncode = pointer
            }
        } else {
            let hashOfCurrentObject = try BaseObjectable.createHash(value)
            if self.collectChildren {
                if let pointerForCurrentObject = self.objectsSavedBeforeThisOne?[hashOfCurrentObject] {
                    valueToEncode = pointerForCurrentObject
                } else {
                    //New object needs to be saved before it can be pointed to
                    self.newObjects.append(value)
                }
            } else if let pointerForCurrentObject = self.objectsSavedBeforeThisOne?[hashOfCurrentObject] {
                valueToEncode = pointerForCurrentObject
            } else if dictionary.count > 0 {
                //Only top level objects can be saved without a pointer
                throw ParseError(code: .unknownError, message: "Error. Couldn't resolve unsaved object while encoding.")
            }
        }
        return valueToEncode
    }

    func deepFindAndReplaceParseFiles(_ value: ParseFile) throws -> Encodable? {
        var valueToEncode: Encodable?
        if value.isSaved {
            if self.uniqueFiles.contains(value) {
                throw ParseError(code: .unknownError, message: "Found a circular dependency when encoding.")
            }
            self.uniqueFiles.insert(value)
            if !self.collectChildren {
                valueToEncode = value
            }
        } else {
            if self.collectChildren {
                if let updatedFile = self.filesSavedBeforeThisOne?[value.id] {
                    valueToEncode = updatedFile
                } else {
                    //New object needs to be saved before it can be stored
                    self.newObjects.append(value)
                }
            } else if let currentFile = self.filesSavedBeforeThisOne?[value.id] {
                valueToEncode = currentFile
            } else if dictionary.count > 0 {
                //Only top level objects can be saved without a pointer
                throw ParseError(code: .unknownError, message: "Error. Couldn't resolve unsaved file while encoding.")
            }
        }
        return valueToEncode
    }
}

// MARK: _ParseEncoderKeyedEncodingContainer
private struct _ParseEncoderKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let encoder: _ParseEncoder
    var codingPath: [CodingKey]
    let container: NSMutableDictionary

    init(referencing encoder: _ParseEncoder, codingPath: [CodingKey], wrapping container: NSMutableDictionary) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    // MARK: - KeyedEncodingContainerProtocol Methods
    mutating func encodeNil(forKey key: Key) throws {
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        container[key.stringValue] = NSNull()
    }
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        self.container[key.stringValue] = self.encoder.box(value)
    }
    mutating func encode(_ value: Int, forKey key: Key) throws {
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        self.container[key.stringValue] = self.encoder.box(value)
    }
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        self.container[key.stringValue] = self.encoder.box(value)
    }
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        self.container[key.stringValue] = self.encoder.box(value)
    }
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        self.container[key.stringValue] = self.encoder.box(value)
    }
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        self.container[key.stringValue] = self.encoder.box(value)
    }
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        self.container[key.stringValue] = self.encoder.box(value)
    }
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        self.container[key.stringValue] = self.encoder.box(value)
    }
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        self.container[key.stringValue] = self.encoder.box(value)
    }
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        self.container[key.stringValue] = self.encoder.box(value)
    }
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        self.container[key.stringValue] = self.encoder.box(value)
    }
    mutating func encode(_ value: String, forKey key: Key) throws {
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        self.container[key.stringValue] = self.encoder.box(value)
    }
    mutating func encode(_ value: Float, forKey key: Key) throws {
        // Since the float may be invalid and throw, the coding path needs to contain this key.
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[key.stringValue] = try self.encoder.box(value)
    }

    mutating func encode(_ value: Double, forKey key: Key) throws {
        // Since the double may be invalid and throw, the coding path needs to contain this key.
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[key.stringValue] = try self.encoder.box(value)
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        if self.encoder.skippedKeys.contains(key.stringValue) && !self.encoder.ignoreSkipKeys { return }

        var valueToEncode: Encodable = value
        if ((value as? Objectable) != nil)
            || ((value as? ParsePointer) != nil) {
            if let replacedObject = try self.encoder.deepFindAndReplaceParseObjects(value) {
                valueToEncode = replacedObject
            }
        } else if let parsePointers = value as? [ParsePointer] {
            _ = try parsePointers.compactMap { try self.encoder.deepFindAndReplaceParseObjects($0) }
        } else if let parseObjects = value as? [Objectable] {
            let replacedObjects = try parseObjects.compactMap { try self.encoder.deepFindAndReplaceParseObjects($0) }
            if replacedObjects.count > 0 {
                self.encoder.codingPath.append(key)
                defer { self.encoder.codingPath.removeLast() }
                self.container[key.stringValue] = try replacedObjects.map { try self.encoder.box($0) }
                return
            }
        } else if let parseFile = value as? ParseFile {
            if let replacedObject = try self.encoder.deepFindAndReplaceParseFiles(parseFile) {
                valueToEncode = replacedObject
            }
        } else if let parseFiles = value as? [ParseFile] {
            let replacedFiles = try parseFiles.compactMap { try self.encoder.deepFindAndReplaceParseFiles($0) }
            if replacedFiles.count > 0 {
                self.encoder.codingPath.append(key)
                defer { self.encoder.codingPath.removeLast() }
                self.container[key.stringValue] = try replacedFiles.map { try self.encoder.box($0) }
                return
            }
        }

        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[key.stringValue] = try self.encoder.box(valueToEncode)
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let containerKey = key.stringValue
        let dictionary: NSMutableDictionary

        if let existingContainer = self.container[containerKey] {
            precondition(
                existingContainer is NSMutableDictionary,
                "Attempt to re-encode into nested KeyedEncodingContainer<\(Key.self)> for key \"\(containerKey)\" is invalid: non-keyed container already encoded for this key"
            )
            dictionary = existingContainer as! NSMutableDictionary
        } else {
            dictionary = NSMutableDictionary()
            self.container[containerKey] = dictionary
        }

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        let container = _ParseEncoderKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath,
                                                                       wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let containerKey = key.stringValue
        let array: NSMutableArray
        if let existingContainer = self.container[containerKey] {
            precondition(
                existingContainer is NSMutableArray,
                "Attempt to re-encode into nested UnkeyedEncodingContainer for key \"\(containerKey)\" is invalid: keyed container/single value already encoded for this key"
            )
            array = existingContainer as! NSMutableArray
        } else {
            array = NSMutableArray()
            self.container[containerKey] = array
        }

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return _ParseEncoderUnkeyedEncodingContainer(
            referencing: self.encoder,
            codingPath: codingPath,
            wrapping: array
        )
    }

    mutating func superEncoder() -> Encoder {
        _ParseReferencingEncoder(referencing: self.encoder, key: _JSONKey.super, wrapping: self.container, skippingKeys: self.encoder.skippedKeys, collectChildren: self.encoder.collectChildren, objectsSavedBeforeThisOne: self.encoder.objectsSavedBeforeThisOne, filesSavedBeforeThisOne: self.encoder.filesSavedBeforeThisOne)
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        _ParseReferencingEncoder(referencing: self.encoder, key: key, wrapping: self.container, skippingKeys: self.encoder.skippedKeys, collectChildren: self.encoder.collectChildren, objectsSavedBeforeThisOne: self.encoder.objectsSavedBeforeThisOne, filesSavedBeforeThisOne: self.encoder.filesSavedBeforeThisOne)
    }
}

// MARK: _ParseEncoderUnkeyedEncodingContainer
private struct _ParseEncoderUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    /// A reference to the encoder we're writing to.
    let encoder: _ParseEncoder
    var codingPath: [CodingKey]
    let container: NSMutableArray

    /// The number of elements encoded into the container.
    public var count: Int {
        return self.container.count
    }

    init(referencing encoder: _ParseEncoder, codingPath: [CodingKey], wrapping container: NSMutableArray) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    // MARK: - UnkeyedEncodingContainer Methods

    public mutating func encodeNil()             throws { self.container.add(NSNull()) }
    public mutating func encode(_ value: Bool)   throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int)    throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int8)   throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int16)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int32)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: Int64)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt)   throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt8)  throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt16) throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt32) throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: UInt64) throws { self.container.add(self.encoder.box(value)) }
    public mutating func encode(_ value: String) throws { self.container.add(self.encoder.box(value)) }

    public mutating func encode(_ value: Float)  throws {
        // Since the float may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(_JSONKey(index: self.count))
        defer { self.encoder.codingPath.removeLast() }
        self.container.add(try self.encoder.box(value))
    }

    public mutating func encode(_ value: Double) throws {
        // Since the double may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(_JSONKey(index: self.count))
        defer { self.encoder.codingPath.removeLast() }
        self.container.add(try self.encoder.box(value))
    }

    public mutating func encode<T : Encodable>(_ value: T) throws {
        self.encoder.codingPath.append(_JSONKey(index: self.count))
        defer { self.encoder.codingPath.removeLast() }
        self.container.add(try self.encoder.box(value))
    }

    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        self.codingPath.append(_JSONKey(index: self.count))
        defer { self.codingPath.removeLast() }

        let dictionary = NSMutableDictionary()
        self.container.add(dictionary)

        let container = _ParseEncoderKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        self.codingPath.append(_JSONKey(index: self.count))
        defer { self.codingPath.removeLast() }

        let array = NSMutableArray()
        self.container.add(array)
        return _ParseEncoderUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
    }

    public mutating func superEncoder() -> Encoder {
        return _ParseReferencingEncoder(referencing: self.encoder, at: self.container.count, wrapping: self.container, skippingKeys: self.encoder.skippedKeys, collectChildren: self.encoder.collectChildren, objectsSavedBeforeThisOne: self.encoder.objectsSavedBeforeThisOne, filesSavedBeforeThisOne: self.encoder.filesSavedBeforeThisOne)
    }
}

extension _ParseEncoder : SingleValueEncodingContainer {
    // MARK: - SingleValueEncodingContainer Methods

    private func assertCanEncodeNewValue() {
        precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
    }

    func encodeNil() throws {
        assertCanEncodeNewValue()
        self.storage.push(container: NSNull())
    }

    func encode(_ value: Bool) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    func encode(_ value: Int) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    func encode(_ value: Int8) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    func encode(_ value: Int16) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    func encode(_ value: Int32) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    func encode(_ value: Int64) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    func encode(_ value: UInt) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    func encode(_ value: UInt8) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    func encode(_ value: UInt16) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    func encode(_ value: UInt32) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    func encode(_ value: UInt64) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    func encode(_ value: String) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    func encode(_ value: Float) throws {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value))
    }

    func encode(_ value: Double) throws {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value))
    }

    func encode<T : Encodable>(_ value: T) throws {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value))
    }
}

// MARK: - Concrete Value Representations
// swiftlint:disable force_cast
extension _ParseEncoder {
    /// Returns the given value boxed in a container appropriate for pushing onto the container stack.
    func box(_ value: Bool)   -> NSObject { return NSNumber(value: value) }
    func box(_ value: Int)    -> NSObject { return NSNumber(value: value) }
    func box(_ value: Int8)   -> NSObject { return NSNumber(value: value) }
    func box(_ value: Int16)  -> NSObject { return NSNumber(value: value) }
    func box(_ value: Int32)  -> NSObject { return NSNumber(value: value) }
    func box(_ value: Int64)  -> NSObject { return NSNumber(value: value) }
    func box(_ value: UInt)   -> NSObject { return NSNumber(value: value) }
    func box(_ value: UInt8)  -> NSObject { return NSNumber(value: value) }
    func box(_ value: UInt16) -> NSObject { return NSNumber(value: value) }
    func box(_ value: UInt32) -> NSObject { return NSNumber(value: value) }
    func box(_ value: UInt64) -> NSObject { return NSNumber(value: value) }
    func box(_ value: String) -> NSObject { return NSString(string: value) }

    func box(_ float: Float) throws -> NSObject {
        guard !float.isInfinite && !float.isNaN else {
            guard case let .convertToString(positiveInfinity: posInfString,
                                            negativeInfinity: negInfString,
                                            nan: nanString) = self.options.nonConformingFloatEncodingStrategy else {
                throw EncodingError._invalidFloatingPointValue(float, at: codingPath)
            }

            if float == Float.infinity {
                return NSString(string: posInfString)
            } else if float == -Float.infinity {
                return NSString(string: negInfString)
            } else {
                return NSString(string: nanString)
            }
        }

        return NSNumber(value: float)
    }

    func box(_ double: Double) throws -> NSObject {
        guard !double.isInfinite && !double.isNaN else {
            guard case let .convertToString(positiveInfinity: posInfString,
                                            negativeInfinity: negInfString,
                                            nan: nanString) = self.options.nonConformingFloatEncodingStrategy else {
                throw EncodingError._invalidFloatingPointValue(double, at: codingPath)
            }

            if double == Double.infinity {
                return NSString(string: posInfString)
            } else if double == -Double.infinity {
                return NSString(string: negInfString)
            } else {
                return NSString(string: nanString)
            }
        }

        return NSNumber(value: double)
    }

    func box(_ date: Date) throws -> NSObject {
        switch self.options.dateEncodingStrategy {
        case .deferredToDate:
            // Must be called with a surrounding with(pushedKey:) call.
            // Dates encode as single-value objects; this can't both throw and push a container, so no need to catch the error.
            try date.encode(to: self)
            return self.storage.popContainer()

        case .secondsSince1970:
            return NSNumber(value: date.timeIntervalSince1970)

        case .millisecondsSince1970:
            return NSNumber(value: 1000.0 * date.timeIntervalSince1970)

        case .iso8601:
            if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                return NSString(string: _iso8601Formatter.string(from: date))
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }

        case .formatted(let formatter):
            return NSString(string: formatter.string(from: date))

        case .custom(let closure):
            let depth = self.storage.count
            do {
                try closure(date, self)
            } catch {
                // If the value pushed a container before throwing, pop it back off to restore state.
                if self.storage.count > depth {
                    let _ = self.storage.popContainer()
                }

                throw error
            }

            guard self.storage.count > depth else {
                // The closure didn't encode anything. Return the default keyed container.
                return NSDictionary()
            }

            // We can pop because the closure encoded something.
            return self.storage.popContainer()
        @unknown default:
            fatalError("Unhandled")
        }
    }

    func box(_ data: Data) throws -> NSObject {
        switch self.options.dataEncodingStrategy {
        case .deferredToData:
            // Must be called with a surrounding with(pushedKey:) call.
            let depth = self.storage.count
            do {
                try data.encode(to: self)
            } catch {
                // If the value pushed a container before throwing, pop it back off to restore state.
                // This shouldn't be possible for Data (which encodes as an array of bytes), but it can't hurt to catch a failure.
                if self.storage.count > depth {
                    let _ = self.storage.popContainer()
                }

                throw error
            }

            return self.storage.popContainer()

        case .base64:
            return NSString(string: data.base64EncodedString())

        case .custom(let closure):
            let depth = self.storage.count
            do {
                try closure(data, self)
            } catch {
                // If the value pushed a container before throwing, pop it back off to restore state.
                if self.storage.count > depth {
                    let _ = self.storage.popContainer()
                }

                throw error
            }

            guard self.storage.count > depth else {
                // The closure didn't encode anything. Return the default keyed container.
                return NSDictionary()
            }

            // We can pop because the closure encoded something.
            return self.storage.popContainer()
        @unknown default:
            fatalError("Unhandled")
        }
    }

    func box(_ dict: [String : Encodable]) throws -> NSObject? {
        let depth = self.storage.count
        let result = self.storage.pushKeyedContainer()
        do {
            for (key, value) in dict {
                self.codingPath.append(_JSONKey(stringValue: key, intValue: nil))
                defer { self.codingPath.removeLast() }
                result[key] = try box(value)
            }
        } catch {
            // If the value pushed a container before throwing, pop it back off to restore state.
            if self.storage.count > depth {
                let _ = self.storage.popContainer()
            }

            throw error
        }

        // The top container should be a new container.
        guard self.storage.count > depth else {
            return nil
        }

        return self.storage.popContainer()
    }

    func box(_ value: Encodable) throws -> NSObject {
        return try self.box_(value) ?? NSDictionary()
    }

    // swiftlint:disable:next line_length
    // This method is called "box_" instead of "box" to disambiguate it from the overloads. Because the return type here is different from all of the "box" overloads (and is more general), any "box" calls in here would call back into "box" recursively instead of calling the appropriate overload, which is not what we want.
    func box_(_ value: Encodable) throws -> NSObject? {
        // Disambiguation between variable and function is required due to
        // issue tracked at: https://bugs.swift.org/browse/SR-1846
        let type = Swift.type(of: value)
        if type == Date.self || type == NSDate.self {
            // Respect Date encoding strategy
            return try self.box((value as! Date))
        } else if type == Data.self || type == NSData.self {
            // Respect Data encoding strategy
            // swiftlint:disable:next force_cast
            return try self.box((value as! Data))
        } else if type == URL.self || type == NSURL.self {
            // Encode URLs as single strings.
            // swiftlint:disable:next force_cast
            return self.box((value as! URL).absoluteString)
        } else if type == Decimal.self || type == NSDecimalNumber.self {
            // JSONSerialization can natively handle NSDecimalNumber.
            // swiftlint:disable:next force_cast
            return (value as! NSDecimalNumber)
        } else if value is _JSONStringDictionaryEncodableMarker {
            //COREY: DON'T remove the force unwrap, it will crash the app
            // swiftlint:disable:next force_cast
            return try self.box(value as! [String : Encodable])
        } else if value is ParsePointer {
            ignoreSkipKeys = true
        }

        // The value should request a container from the __JSONEncoder.
        let depth = self.storage.count
        do {
            try value.encode(to: self)
            ignoreSkipKeys = false
        } catch {
            // If the value pushed a container before throwing, pop it back off to restore state.
            if self.storage.count > depth {
                let _ = self.storage.popContainer()
            }

            throw error
        }

        // The top container should be a new container.
        guard self.storage.count > depth else {
            return nil
        }

        return self.storage.popContainer()
    }
}

// MARK: - _ParseReferencingEncoder
// swiftlint:disable line_length
/// __JSONReferencingEncoder is a special subclass of __JSONEncoder which has its own storage, but references the contents of a different encoder.
/// It's used in superEncoder(), which returns a new encoder for encoding a superclass -- the lifetime of the encoder should not escape the scope it's created in, but it doesn't necessarily know when it's done being used (to write to the original container).
private class _ParseReferencingEncoder: _ParseEncoder {
    // MARK: Reference types.

    /// The type of container we're referencing.
    private enum Reference {
        /// Referencing a specific index in an array container.
        case array(NSMutableArray, Int)

        /// Referencing a specific key in a dictionary container.
        case dictionary(NSMutableDictionary, String)
    }

    // MARK: - Properties

    /// The encoder we're referencing.
    let encoder: _ParseEncoder

    /// The container reference itself.
    private let reference: Reference

    // MARK: - Initialization

    /// Initializes `self` by referencing the given array container in the given encoder.
    init(referencing encoder: _ParseEncoder, at index: Int, wrapping array: NSMutableArray, skippingKeys: Set<String>, collectChildren: Bool, objectsSavedBeforeThisOne: [String: PointerType]?, filesSavedBeforeThisOne: [UUID: ParseFile]?) {
        self.encoder = encoder
        self.reference = .array(array, index)
        super.init(codingPath: encoder.codingPath, dictionary: NSMutableDictionary(), skippingKeys: skippingKeys)
        self.collectChildren = collectChildren
        self.objectsSavedBeforeThisOne = objectsSavedBeforeThisOne
        self.filesSavedBeforeThisOne = filesSavedBeforeThisOne
        self.codingPath.append(_JSONKey(index: index))
    }

    /// Initializes `self` by referencing the given dictionary container in the given encoder.
    init(referencing encoder: _ParseEncoder, key: CodingKey, wrapping dictionary: NSMutableDictionary, skippingKeys: Set<String>, collectChildren: Bool, objectsSavedBeforeThisOne: [String: PointerType]?, filesSavedBeforeThisOne: [UUID: ParseFile]?) {
        self.encoder = encoder
        self.reference = .dictionary(dictionary, key.stringValue)
        super.init(codingPath: encoder.codingPath, dictionary: dictionary, skippingKeys: skippingKeys)
        self.collectChildren = collectChildren
        self.objectsSavedBeforeThisOne = objectsSavedBeforeThisOne
        self.filesSavedBeforeThisOne = filesSavedBeforeThisOne
        self.codingPath.append(key)
    }

    // MARK: - Coding Path Operations

    override var canEncodeNewValue: Bool {
        // With a regular encoder, the storage and coding path grow together.
        // A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
        // We have to take this into account.
        return self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
    }

    // MARK: - Deinitialization

    // Finalizes `self` by writing the contents of our storage to the referenced encoder's storage.
    deinit {
        let value: Any
        switch self.storage.count {
        case 0: value = NSDictionary()
        case 1: value = self.storage.popContainer()
        default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
        }

        switch self.reference {
        case .array(let array, let index):
            array.insert(value, at: index)

        case .dictionary(let dictionary, let key):
            dictionary[NSString(string: key)] = value
        }
    }
}

// MARK: - Encoding Storage and Containers

internal struct _ParseEncodingStorage {
    // MARK: Properties

    /// The container stack.
    /// Elements may be any one of the JSON types (NSNull, NSNumber, NSString, NSArray, NSDictionary).
    private(set) var containers: [NSObject] = []

    // MARK: - Initialization

    /// Initializes `self` with no containers.
    init() {}

    // MARK: - Modifying the Stack

    var count: Int {
        return self.containers.count
    }

    mutating func pushKeyedContainer() -> NSMutableDictionary {
        let dictionary = NSMutableDictionary()
        self.containers.append(dictionary)
        return dictionary
    }

    mutating func pushUnkeyedContainer() -> NSMutableArray {
        let array = NSMutableArray()
        self.containers.append(array)
        return array
    }

    mutating func push(container: __owned NSObject) {
        self.containers.append(container)
    }

    mutating func popContainer() -> NSObject {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return self.containers.popLast()!
    }
}

//===----------------------------------------------------------------------===//
// Error Utilities
//===----------------------------------------------------------------------===//

extension EncodingError {
    /// Returns a `.invalidValue` error describing the given invalid floating-point value.
    ///
    ///
    /// - parameter value: The value that was invalid to encode.
    /// - parameter path: The path of `CodingKey`s taken to encode this value.
    /// - returns: An `EncodingError` with the appropriate path and debug description.
    fileprivate static func _invalidFloatingPointValue<T : FloatingPoint>(_ value: T, at codingPath: [CodingKey]) -> EncodingError {
        let valueDescription: String
        if value == T.infinity {
            valueDescription = "\(T.self).infinity"
        } else if value == -T.infinity {
            valueDescription = "-\(T.self).infinity"
        } else {
            valueDescription = "\(T.self).nan"
        }

        let debugDescription = "Unable to encode \(valueDescription) directly in JSON. Use JSONEncoder.NonConformingFloatEncodingStrategy.convertToString to specify how the value should be encoded."
        return .invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: debugDescription))
    }
}

//===----------------------------------------------------------------------===//
// Shared Key Types
//===----------------------------------------------------------------------===//

private struct _JSONKey : CodingKey {
    public var stringValue: String
    public var intValue: Int?

    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    public init(stringValue: String, intValue: Int?) {
        self.stringValue = stringValue
        self.intValue = intValue
    }

    init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }

    static let `super` = _JSONKey(stringValue: "super")!
}

//===----------------------------------------------------------------------===//
// Shared ISO8601 Date Formatter
//===----------------------------------------------------------------------===//
// swiftlint:disable:next line_length
// NOTE: This value is implicitly lazy and _must_ be lazy. We're compiled against the latest SDK (w/ ISO8601DateFormatter), but linked against whichever Foundation the user has. ISO8601DateFormatter might not exist, so we better not hit this code path on an older OS.
@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
private var _iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()
