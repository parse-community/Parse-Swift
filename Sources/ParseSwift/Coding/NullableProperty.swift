//
//  NullableProperty.swift
//
//  Created by Steven Grosmark on 6/10/20.
//  Source: https://github.com/g-mark/NullCodable
//

import Foundation

/// Property wrapper that encodes `nil` optional values as a delete operation
/// when encoded using `JSONEncoder`.
///
/// For example, adding `@NullableProperty` like this:
/// ```swift
/// struct Test: Codable {
///     @NullableProperty var name: String? = nil
/// }
/// ```
///
@propertyWrapper
public struct NullableProperty<Wrapped> {

    public var wrappedValue: Wrapped?

    public init(wrappedValue: Wrapped?) {
        self.wrappedValue = wrappedValue
    }
}

extension NullableProperty: Encodable where Wrapped: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch wrappedValue {
        case .some(let value):
            try container.encode(value)

        case .none:
            try container.encode(Delete())
        }
    }
}

extension NullableProperty: Decodable where Wrapped: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            wrappedValue = try container.decode(Wrapped.self)
        }
    }
}

extension NullableProperty: Hashable where Wrapped: Hashable { }
extension NullableProperty: Equatable where Wrapped: Equatable { }

extension KeyedDecodingContainer {

    public func decode<Wrapped>(_ type: NullableProperty<Wrapped>.Type, forKey key: KeyedDecodingContainer<K>.Key)
    throws -> NullableProperty<Wrapped> where Wrapped: Decodable {
        return try decodeIfPresent(NullableProperty<Wrapped>.self, forKey: key) ??
        NullableProperty<Wrapped>(wrappedValue: nil)
    }
}
