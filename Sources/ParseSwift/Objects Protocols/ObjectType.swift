//
//  ParseObjectType.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

public struct NoBody: Codable {}

public protocol Saving: Codable {
    associatedtype SavingType
    func save(options: API.Options) throws -> SavingType
    func save() throws -> SavingType
}

extension Saving {
    public func save() throws -> SavingType {
        return try save(options: [])
    }
}

public protocol Fetching: Codable {
    associatedtype FetchingType
    func fetch(options: API.Options) throws -> FetchingType
    func fetch() throws -> FetchingType
}

extension Fetching {
    public func fetch() throws -> FetchingType {
        return try fetch(options: [])
    }
}

public protocol ObjectType: Fetching, Saving, CustomDebugStringConvertible, Equatable {
    static var className: String { get }
    var objectId: String? { get set }
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
    var ACL: ACL? { get set }
}

internal extension ObjectType {
    func getEncoder() -> ParseEncoder {
        return getParseEncoder()
    }

    func getTestDecoder() -> JSONDecoder {
        return getDecoder()
    }

    func getEncoderWithoutSkippingKeys() -> ParseEncoder {
        return getParseEncoderWithoutSkippingKeys()
    }
}

extension ObjectType {
    // Parse ClassName inference
    public static var className: String {
        let classType = "\(type(of: self))"
        return classType.components(separatedBy: ".").first! // strip .Type
    }
    public var className: String {
        return Self.className
    }
}

extension ObjectType {
    public var debugDescription: String {
        guard let descriptionData = try? getJSONEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "\(className) ()"
        }
        return "\(className) (\(descriptionString))"
    }
}

public extension ObjectType {
    func toPointer() -> Pointer<Self> {
        return Pointer(self)
    }
}

enum DateEncodingKeys: String, CodingKey {
    case iso
    case type = "__type"
}

let dateFormatter: DateFormatter = {
    var dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    return dateFormatter
}()

let parseDateEncodingStrategy: ParseEncoder.DateEncodingStrategy = .custom({ (date, enc) in
    var container = enc.container(keyedBy: DateEncodingKeys.self)
    try container.encode("Date", forKey: .type)
    let dateString = dateFormatter.string(from: date)
    try container.encode(dateString, forKey: .iso)
})

let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .custom({ (date, enc) in
    var container = enc.container(keyedBy: DateEncodingKeys.self)
    try container.encode("Date", forKey: .type)
    let dateString = dateFormatter.string(from: date)
    try container.encode(dateString, forKey: .iso)
})

internal extension Date {
    func parseFormatted() -> String {
        return dateFormatter.string(from: self)
    }
    var parseRepresentation: [String: String] {
        return ["__type": "Date", "iso": parseFormatted()]
    }
}

let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .custom({ (dec) -> Date in
    do {
        let container = try dec.singleValueContainer()
        let decodedString = try container.decode(String.self)
        return dateFormatter.date(from: decodedString)!
    } catch let error {
        let container = try dec.container(keyedBy: DateEncodingKeys.self)
        if let decoded = try container.decodeIfPresent(String.self, forKey: .iso) {
            return dateFormatter.date(from: decoded)!
        }
    }
    throw ParseError(code: .unknownError, message: "unable to decode")
})

func getJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = dateEncodingStrategy
    return encoder
}

private let forbiddenKeys = ["createdAt", "updatedAt", "objectId", "className"]

func getParseEncoder() -> ParseEncoder {
    return getParseEncoder(skipKeys: true)
}

func getParseEncoderWithoutSkippingKeys() -> ParseEncoder {
    return getParseEncoder(skipKeys: false)
}

internal func getParseEncoder(skipKeys: Bool) -> ParseEncoder {
    let encoder = ParseEncoder()
    encoder.dateEncodingStrategy = parseDateEncodingStrategy
    encoder.shouldEncodeKey = { (key, path) -> Bool in
        if path.count == 0 // top level
            && forbiddenKeys.firstIndex(of: key) != nil
            && skipKeys {
            return false
        }
        return true
    }
    return encoder
}

extension JSONEncoder {
    func encodeAsString<T>(_ value: T) throws -> String where T: Encodable {
        guard let string = String(data: try encode(value), encoding: .utf8) else {
            throw ParseError(code: .unknownError, message: "Unable to encode object...")
        }
        return string
    }
}

func getDecoder() -> JSONDecoder {
    let encoder = JSONDecoder()
    encoder.dateDecodingStrategy = dateDecodingStrategy
    return encoder
}

public extension ObjectType {
    func save(options: API.Options) throws -> Self {
        return try saveCommand().execute(options: options)
    }

    func save(options: API.Options, callbackQueue: DispatchQueue,
              completion: @escaping (Result<Self, ParseError>) -> Void) {
        saveCommand().executeAsync(options: options, callbackQueue: callbackQueue, completion: completion)
    }

    func fetch(options: API.Options) throws -> Self {
        return try fetchCommand().execute(options: options)
    }

    func fetch(options: API.Options, callbackQueue: DispatchQueue,
               completion: @escaping (Result<Self, ParseError>) -> Void) {
        do {
            try fetchCommand().executeAsync(options: options, callbackQueue: callbackQueue, completion: completion)
        } catch let error as ParseError {
            completion(.failure(error))
        } catch {
            completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
        }
    }

    internal func saveCommand() -> API.Command<Self, Self> {
        return API.Command<Self, Self>.saveCommand(self)
    }

    internal func fetchCommand() throws -> API.Command<Self, Self> {
        return try API.Command<Self, Self>.fetchCommand(self)
    }
}

extension ObjectType {
    var endpoint: API.Endpoint {
        if let objectId = objectId {
            return .object(className: className, objectId: objectId)
        }
        return .objects(className: className)
    }

    var isSaved: Bool {
        return objectId != nil
    }
}

internal struct FindResult<T>: Codable where T: ObjectType {
    let results: [T]
    let count: Int?
}

public extension ObjectType {
    var mutationContainer: ParseMutationContainer<Self> {
        return ParseMutationContainer(target: self)
    }
}
