//
//  Responses.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

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

internal struct UpdateSessionTokenResponse: Decodable {
    var updatedAt: Date
    let sessionToken: String?
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
        case .PUT, .PATCH:
            return asUpdateResponse().apply(to: object)
        case .GET:
            fatalError("Parse-server doesn't support batch fetching like this. Try \"fetchAll\".")
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
internal struct AnyResultResponse<U: Decodable>: Decodable {
    let result: U
}

// MARK: AnyResultsResponse
internal struct AnyResultsResponse<U: Decodable>: Decodable {
    let results: [U]
}

// MARK: ConfigResponse
internal struct ConfigFetchResponse<T>: Codable where T: ParseConfig {
    let params: T
}

internal struct ConfigUpdateResponse: Codable {
    let result: Bool
}

// MARK: HealthResponse
internal struct HealthResponse: Codable {
    let status: String
}
