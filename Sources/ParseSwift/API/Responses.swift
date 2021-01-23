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

// MARK: ParseObject
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
            throw ParseError(code: .unknownError, message: "Should have converted encoded object to Pointer")
        }
        var pointer = try PointerType(object)
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

// MARK: ParseObject Batch
internal struct BatchResponseItem<T>: Codable where T: Codable {
    let success: T?
    let error: ParseError?
}

internal struct WriteResponse: Codable {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?

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

    func apply<T>(to object: T, method: API.Method) -> T where T: ParseObject {
        switch method {
        case .POST:
            return asSaveResponse().apply(to: object)
        case .PUT:
            return asUpdateResponse().apply(to: object)
        case .GET:
            fatalError("Parse-server doesn't support batch fetching like this. Look at \"fetchAll\".")
        default:
            fatalError("There is no configured way to apply for method: \(method)")
        }
    }
}

// MARK: Query
internal struct QueryResponse<T>: Codable where T: ParseObject {
    let results: [T]
    let count: Int?
}

// MARK: ParseUser
internal struct LoginSignupResponse: Codable {
    let createdAt: Date
    let objectId: String
    let sessionToken: String
    var updatedAt: Date?
    let username: String?
}

// MARK: ParseFile
internal struct FileUploadResponse: Decodable {
    let name: String
    let url: URL

    func apply(to file: ParseFile) -> ParseFile {
        var file = file
        file.name = name
        file.url = url
        return file
    }
}

// MARK: AnyResultResponse
internal struct AnyResultResponse: Codable {
    let result: AnyCodable?
}

// MARK: AnyResultsResponse
internal struct AnyResultsResponse: Codable {
    let results: AnyCodable?
}

// MARK: ConfigResponse
internal struct ConfigFetchResponse<T>: Codable where T: ParseConfig {
    let params: T
}

internal struct ConfigUpdateResponse: Codable {
    let result: Bool
}
