//
//  ParseObject.swift
//  ParseSwift
//
//  Created by Pranjal Satija on 7/18/20.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation

// MARK: ParseObject
public protocol ParseObject: Fetchable, Saveable, CustomDebugStringConvertible, Equatable {
    static var className: String { get }

    var objectId: String? { get set }
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
    var ACL: ACL? { get set }
}

// MARK: Default Implementations
extension ParseObject {
    public static var className: String {
        let classType = "\(type(of: self))"
        return classType.components(separatedBy: ".").first! // strip .Type
    }

    public var className: String {
        return Self.className
    }
}

// MARK: Batch Support
public extension ParseObject {
    static func saveAll(_ objects: Self...) throws -> [(Self, ParseError?)] {
        return try objects.saveAll()
    }
}

extension Sequence where Element: ParseObject {
    public func saveAll(options: API.Options = []) throws -> [(Self.Element, ParseError?)] {
        let commands = map { $0.saveCommand() }
        return try API.Command<Self.Element, Self.Element>
                .batch(commands: commands)
                .execute(options: options)
    }
}

// MARK: Convenience
extension ParseObject {
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

// MARK: CustomDebugStringConvertible
extension ParseObject {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "\(className) ()"
        }

        return "\(className) (\(descriptionString))"
    }
}

// MARK: Equatable
public func == <T>(lhs: T?, rhs: T?) -> Bool where T: ParseObject {
    guard let lhs = lhs, let rhs = rhs else { return false }
    return lhs == rhs
}

public func == <T>(lhs: T, rhs: T) -> Bool where T: ParseObject {
    return lhs.className == rhs.className && rhs.objectId == lhs.objectId
}

// MARK: Fetchable
extension ParseObject {
    public func fetch(options: API.Options) throws -> Self {
        return try fetchCommand().execute(options: options)
    }

    internal func fetchCommand() throws -> API.Command<Self, Self> {
        return try API.Command<Self, Self>.fetchCommand(self)
    }
}

// MARK: Mutations
public extension ParseObject {
    var mutationContainer: ParseMutationContainer<Self> {
        return ParseMutationContainer(target: self)
    }
}

// MARK: Queryable
public extension ParseObject {
    static func find() throws -> [Self] {
        return try query().find()
    }

    static func query() -> Query<Self> {
        return Query<Self>()
    }

    static func query(_ constraints: QueryConstraint...) -> Query<Self> {
        return Query(constraints)
    }
}

// MARK: Saveable
extension ParseObject {
    public func save(options: API.Options) throws -> Self {
        return try saveCommand().execute(options: options)
    }

    internal func saveCommand() -> API.Command<Self, Self> {
        return API.Command<Self, Self>.saveCommand(self)
    }
}

public extension ParseObject {
    func toPointer() -> Pointer<Self> {
        return Pointer(self)
    }
}
