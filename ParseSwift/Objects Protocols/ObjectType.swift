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
    func encode<T : Encodable>(_ value: T) throws -> Data
}

extension ParseEncoder: CommonEncoder {}
extension JSONEncoder: CommonEncoder {}

public protocol Saving: Codable {
    func save(callback: ((Result<Self>) -> ())?) -> Cancellable
}

public protocol Fetching: Codable {
    associatedtype T
    func fetch(callback: ((Result<T>) -> ())?) -> Cancellable?
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

public func ==<T>(lhs: T?, rhs: T?) -> Bool where T: ObjectType {
    guard let lhs = lhs, let rhs = rhs else { return false }
    return lhs == rhs
}

public func ==<T>(lhs: T, rhs: T) -> Bool where T: ObjectType {
    return lhs.className == rhs.className && rhs.objectId == lhs.objectId
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

public struct SaveResponse: Decodable {
    var objectId: String
    var createdAt: Date
    var updatedAt: Date {
        return createdAt
    }

    func apply<T>(_ object: T) -> T where T: ObjectType {
        var object = object
        object.objectId = objectId
        object.createdAt = createdAt
        object.updatedAt = updatedAt
        return object
    }
}

struct UpdateResponse: Decodable {
    var updatedAt: Date

    func apply<T>(_ object: T) -> T where T: ObjectType {
        var object = object
        object.updatedAt = updatedAt
        return object
    }
}

struct SaveOrUpdateResponse: Decodable {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?

    var isCreate: Bool {
        return objectId != nil && createdAt != nil
    }

    func asSaveResponse() -> SaveResponse {
        guard let objectId = objectId, let createdAt = createdAt else {
            fatalError("Cannot create a SaveResponse without objectId")
        }
        return SaveResponse(objectId: objectId, createdAt: createdAt)
    }

    func asUpdateResponse() -> UpdateResponse {
        guard let updatedAt = updatedAt else {
            fatalError("Cannot create an UpdateResponse without updatedAt")
        }
        return UpdateResponse(updatedAt: updatedAt)
    }

    func apply<T>(_ object: T) -> T where T: ObjectType {
        if isCreate {
            return asSaveResponse().apply(object)
        } else {
            return asUpdateResponse().apply(object)
        }
    }
}

public struct ParseError: Error, Decodable {
    let code: Int
    let error: String
}

enum DateEncodingKeys: String, CodingKey {
    case iso
    case __type
}

let dateFormatter: DateFormatter = {
    var dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    return dateFormatter
}()

let parseDateEncodingStrategy: ParseEncoder.DateEncodingStrategy = .custom({ (date, enc) in
    var container = enc.container(keyedBy: DateEncodingKeys.self)
    try container.encode("Date", forKey: .__type)
    let dateString = dateFormatter.string(from: date)
    try container.encode(dateString, forKey: .iso)
})

let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .custom({ (date, enc) in
    var container = enc.container(keyedBy: DateEncodingKeys.self)
    try container.encode("Date", forKey: .__type)
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
    typealias ObjectCallback = (Result<Self>) -> ()

    public func save(callback: ((Result<Self>) -> ())? = nil) -> Cancellable {
        return saveCommand().execute(callback)
    }

    public func fetch(callback: ((Result<Self>) -> ())? = nil) -> Cancellable? {
        do {
            return try fetchCommand().execute(callback)
        } catch let e {
            callback?(.error(e))
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
    var remotePath: API.Endpoint {
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

public typealias BatchResultCallback<T> = (Result<[(T, ParseError?)]>) -> () where T: ObjectType
public extension ObjectType {
    public static func saveAll(_ objects: Self..., callback: BatchResultCallback<Self>?) -> Cancellable {
        return objects.saveAll(callback: callback)
    }
}

extension Sequence where Element: ObjectType {
    public func saveAll(callback: BatchResultCallback<Element>?) -> Cancellable {
        return RESTBatchCommand(commands: map { $0.saveCommand() }).execute(callback)
    }

    private func saveAllCommand() -> RESTBatchCommand<Element> {
        return RESTBatchCommand(commands: map { $0.saveCommand() })
    }
}
