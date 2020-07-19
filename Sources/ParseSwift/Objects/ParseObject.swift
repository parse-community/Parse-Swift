//
//  ParseObject.swift
//  ParseSwift
//
//  Created by Pranjal Satija on 7/18/20.
//  Copyright © 2020 Parse. All rights reserved.
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

public extension ObjectType {
    func save(options: API.Options) throws -> Self {
        return try saveCommand().execute(options: options)
    }

    func fetch(options: API.Options) throws -> Self {
        return try fetchCommand().execute(options: options)
    }

    internal func saveCommand() -> API.Command<Self, Self> {
        return API.Command<Self, Self>.saveCommand(self)
    }

    internal func fetchCommand() throws -> API.Command<Self, Self> {
        return try API.Command<Self, Self>.fetchCommand(self)
    }
}

public extension ObjectType {
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

public extension ObjectType {
    var mutationContainer: ParseMutationContainer<Self> {
        return ParseMutationContainer(target: self)
    }
}

public func == <T>(lhs: T?, rhs: T?) -> Bool where T: ObjectType {
    guard let lhs = lhs, let rhs = rhs else { return false }
    return lhs == rhs
}

public func == <T>(lhs: T, rhs: T) -> Bool where T: ObjectType {
    return lhs.className == rhs.className && rhs.objectId == lhs.objectId
}
