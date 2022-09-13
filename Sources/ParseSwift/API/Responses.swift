//
//  Responses.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

internal struct CreateResponse: Decodable {
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

internal struct ReplaceResponse: Decodable {
    var createdAt: Date?
    var updatedAt: Date?

    func apply<T>(to object: T) throws -> T where T: ParseObject {
        guard let objectId = object.objectId else {
            throw ParseError(code: .missingObjectId,
                             message: "Response from server should not have an objectId of nil")
        }
        guard let createdAt = createdAt else {
            guard let updatedAt = updatedAt else {
                throw ParseError(code: .unknownError,
                                 message: "Response from server should not have an updatedAt of nil")
            }
            return UpdateResponse(updatedAt: updatedAt).apply(to: object)
        }
        return CreateResponse(objectId: objectId,
                              createdAt: createdAt).apply(to: object)
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

internal struct UpdateSessionTokenResponse: Decodable {
    var updatedAt: Date
    let sessionToken: String?
}

// MARK: ParseObject Batch
internal struct BatchResponseItem<T>: Codable where T: Codable {
    let success: T?
    let error: ParseError?
}

internal struct BatchResponse: Codable {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?

    func asCreateResponse() throws -> CreateResponse {
        guard let objectId = objectId else {
            throw ParseError(code: .missingObjectId,
                             message: "Response from server should not have an objectId of nil")
        }
        guard let createdAt = createdAt else {
            throw ParseError(code: .unknownError,
                             message: "Response from server should not have an createdAt of nil")
        }
        return CreateResponse(objectId: objectId, createdAt: createdAt)
    }

    func asReplaceResponse() -> ReplaceResponse {
        ReplaceResponse(createdAt: createdAt, updatedAt: updatedAt)
    }

    func asUpdateResponse() throws -> UpdateResponse {
        guard let updatedAt = updatedAt else {
            throw ParseError(code: .unknownError,
                             message: "Response from server should not have an updatedAt of nil")
        }
        return UpdateResponse(updatedAt: updatedAt)
    }

    func apply<T>(to object: T, method: API.Method) throws -> T where T: ParseObject {
        switch method {
        case .POST:
            return try asCreateResponse().apply(to: object)
        case .PUT:
            return try asReplaceResponse().apply(to: object)
        case .PATCH:
            return try asUpdateResponse().apply(to: object)
        case .GET:
            fatalError("Parse-server does not support batch fetching like this. Try \"fetchAll\".")
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

    func applySignup<T>(to object: T) -> T where T: ParseUser {
        var object = object
        object.objectId = objectId
        object.createdAt = createdAt
        object.updatedAt = createdAt
        object.password = nil // password should be removed

        return object
    }
}

// MARK: ParseFile
internal struct FileUploadResponse: Codable {
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
internal struct AnyResultResponse<U: Decodable>: Decodable {
    let result: U
}

// MARK: AnyResultsResponse
internal struct AnyResultsResponse<U: Decodable>: Decodable {
    let results: [U]
}

internal struct AnyResultsMongoResponse<U: Decodable>: Decodable {
    let results: U
}

// MARK: ConfigResponse
internal struct ConfigFetchResponse<T>: Codable where T: ParseConfig {
    let params: T
}

internal struct BooleanResponse: Codable {
    let result: Bool
}

// MARK: HealthResponse
internal struct HealthResponse: Codable {
    let status: String
}

// MARK: PushResponse
internal struct PushResponse: Codable {
    let data: Data
    let statusId: String
}
