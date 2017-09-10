//
//  ParseObjectType.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public protocol ObjectType: Fetching, Saving, CustomDebugStringConvertible, Equatable {
    static var className: String { get }

    var objectId: String? { get set }
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
    var ACL: ACL? { get set }
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

extension ObjectType {
    func getEncoder() -> ParseEncoder {
        return getParseEncoder()
    }

    func toPointer() -> Pointer<Self> {
        return Pointer(self)
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
    internal func saveCommand() -> RESTCommand<Self, Self> {
        return RESTCommand<Self, Self>.save(self)
    }

    public func save(options: API.Option, callback: @escaping ((Result<Self>) -> Void)) -> Cancellable {
        return saveCommand().execute(options: options, callback)
    }
}

public extension ObjectType {
    internal func fetchCommand() throws -> RESTCommand<Self, Self> {
        return try RESTCommand<Self, Self>.fetch(self)
    }

    public func fetch(options: API.Option, callback: @escaping ((Result<Self>) -> Void)) -> Cancellable? {
        do {
            return try fetchCommand().execute(options: options, callback)
        } catch let e {
            callback(.error(e))
        }
        return nil
    }
}

public extension ObjectType {
    typealias ObjectCallback = (Result<Self>) -> Void
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
