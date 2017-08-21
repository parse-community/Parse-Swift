//
//  ParseObjectType.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public struct NoBody: Codable {}

internal protocol CommonEncoder {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

extension ParseEncoder: CommonEncoder {}
extension JSONEncoder: CommonEncoder {}

public protocol Saving: Codable {
    associatedtype SavingType
    func save(callback: @escaping ((Result<SavingType>) -> Void)) -> Cancellable
}

public protocol Fetching: Codable {
    associatedtype FetchingType
    func fetch(callback: @escaping ((Result<FetchingType>) -> Void)) -> Cancellable?
}

public protocol ObjectType: Fetching, Saving, CustomDebugStringConvertible, Equatable {
    static var className: String { get }
    var objectId: String? { get set }
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
    var ACL: ACL? { get set }
}

internal extension ObjectType {
    internal func getEncoder() -> CommonEncoder {
        return getParseEncoder()
    }
}

extension ObjectType {
    // Parse ClassName inference
    public static var className: String {
        let t = "\(type(of: self))"
        return t.components(separatedBy: ".").first! // strip .Type
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

public struct ParseError: Error, Decodable {
    let code: Int
    let error: String
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
    internal func parseFormatted() -> String {
        return dateFormatter.string(from: self)
    }
    internal var parseRepresentation: [String: String] {
        return ["__type": "Date", "iso": parseFormatted()]
    }
}

let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .custom({ (dec) -> Date in
    do {
        let container = try dec.singleValueContainer()
        let decodedString = try container.decode(String.self)
        return dateFormatter.date(from: decodedString)!
    } catch let e {
        let container = try dec.container(keyedBy: DateEncodingKeys.self)
        if let decoded = try container.decodeIfPresent(String.self, forKey: .iso) {
            return dateFormatter.date(from: decoded)!
        }
    }
    throw NSError(domain: "", code: -1, userInfo: nil)
})

func getJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = dateEncodingStrategy
    return encoder
}

private let forbiddenKeys = ["createdAt", "updatedAt", "objectId", "className"]

func getParseEncoder() -> ParseEncoder {
    let encoder = ParseEncoder()
    encoder.dateEncodingStrategy = parseDateEncodingStrategy
    encoder.shouldEncodeKey = { (key, path) -> Bool in
        if path.count == 0 // top level
            && forbiddenKeys.index(of: key) != nil {
            return false
        }
        return true
    }
    return encoder
}

extension JSONEncoder {
    func encodeAsString<T>(_ value: T) throws -> String where T: Encodable {
        guard let string = String(data: try encode(value), encoding: .utf8) else {
            throw ParseError(code: -1, error: "Unable to encode object...")
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
    typealias ObjectCallback = (Result<Self>) -> Void

    public func save(callback: @escaping ((Result<Self>) -> Void)) -> Cancellable {
        return saveCommand().execute(callback)
    }

    public func fetch(callback: @escaping ((Result<Self>) -> Void)) -> Cancellable? {
        do {
            return try fetchCommand().execute(callback)
        } catch let e {
            callback(.error(e))
        }
        return nil
    }

    internal func saveCommand() -> RESTCommand<Self, Self> {
        return RESTCommand<Self, Self>.save(self)
    }

    internal func fetchCommand() throws -> RESTCommand<Self, Self> {
        return try RESTCommand<Self, Self>.fetch(self)
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

public struct FindResult<T>: Decodable where T: ObjectType {
    let results: [T]
    let count: Int?
}

public extension ObjectType {
    var mutationContainer: ParseMutationContainer<Self> {
        return ParseMutationContainer(target: self)
    }
}
