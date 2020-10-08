//
//  Responses.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

protocol ChildResponse: Codable {
    var objectId: String { get set }
    var className: String { get set }
}

internal struct PointerSaveResponse: ChildResponse {

    private let __type: String = "Pointer" // swiftlint:disable:this identifier_name
    public var objectId: String
    public var className: String

    public init?(_ target: Objectable) {
        guard let objectId = target.objectId else {
            return nil
        }
        self.objectId = objectId
        self.className = target.className
    }

    private enum CodingKeys: String, CodingKey {
        case __type, objectId, className // swiftlint:disable:this identifier_name
    }

    func apply<T>(to object: T) throws -> PointerType where T: Encodable {
        guard let object = object as? Objectable else {
            throw ParseError(code: .unknownError, message: "Should have converterted encoded object to Pointer")
        }
        var pointer = PointerType(object)
        pointer.objectId = objectId
        return pointer
    }
}

internal struct SaveResponse: Decodable {
    var objectId: String
    var createdAt: Date
    var updatedAt: Date {
        return createdAt
    }

    func apply<T>(to object: T) -> T where T: ParseObject {
        var object = object
        object.objectId = objectId
        object.createdAt = createdAt
        object.updatedAt = updatedAt
        return object
    }
}

internal struct UpdateResponse: Decodable {
    var updatedAt: Date

    func apply<T>(to object: T) -> T where T: ParseObject {
        var object = object
        object.updatedAt = updatedAt
        return object
    }
}

internal struct FetchResponse: Decodable {
    var createdAt: Date
    var updatedAt: Date

    func apply<T>(to object: T) -> T where T: ParseObject {
        var object = object
        object.createdAt = createdAt
        object.updatedAt = updatedAt
        return object
    }
}
