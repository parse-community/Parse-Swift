//
//  RESTBatchCommand.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-19.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

typealias ParseObjectBatchCommand<T> = BatchCommand<T, T> where T: ParseObject
typealias ParseObjectBatchResponse<T> = [(Result<T, ParseError>)]
// swiftlint:disable line_length
typealias RESTBatchCommandType<T> = API.Command<ParseObjectBatchCommand<T>, ParseObjectBatchResponse<T>> where T: ParseObject

typealias ParseObjectBatchCommandEncodable<T> = BatchCommand<T, PointerType> where T: Encodable
typealias ParseObjectBatchResponseEncodable<U> = [(Result<PointerType, ParseError>)]
// swiftlint:disable line_length
typealias RESTBatchCommandTypeEncodable<T> = API.Command<ParseObjectBatchCommandEncodable<T>, ParseObjectBatchResponseEncodable<PointerType>> where T: Encodable

// swiftlint:enable line_length

internal struct BatchCommand<T, U>: Encodable where T: Encodable {
    let requests: [API.Command<T, U>]
}

internal struct BatchResponseItem<T>: Codable where T: Codable {
    let success: T?
    let error: ParseError?
}

internal struct WriteResponse: Codable {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    func asSaveResponse() -> SaveResponse {
        guard let objectId = objectId, let createdAt = createdAt else {
            fatalError("Cannot create a SaveResponse without objectId")
        }
        return SaveResponse(objectId: objectId, createdAt: createdAt, ACL: ACL)
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
            // swiftlint:disable:next line_length
            fatalError("Cannot fetch in batches for a mixed batch. The whole batch must consist of fetch for a batch fetch to succeed.")
        default:
            fatalError("There is no configured way to apply for method: \(method)")
        }
    }
}
