//
//  RESTBatchCommand.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-19.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

typealias ParseObjectBatchCommand<T> = BatchCommand<T, T> where T: ParseObject
typealias ParseObjectBatchResponse<T> = [(T, ParseError?)]
// swiftlint:disable line_length
typealias RESTBatchCommandType<T> = API.Command<ParseObjectBatchCommand<T>, ParseObjectBatchResponse<T>> where T: ParseObject
// swiftlint:enable line_length

public struct BatchCommand<T, U>: Encodable where T: Encodable {
    let requests: [API.Command<T, U>]
}

public struct BatchResponseItem<T>: Decodable where T: Decodable {
    let success: T?
    let error: ParseError?
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

    func apply<T>(_ object: T) -> T where T: ParseObject {
        if isCreate {
            return asSaveResponse().apply(object)
        } else {
            return asUpdateResponse().apply(object)
        }
    }
}
