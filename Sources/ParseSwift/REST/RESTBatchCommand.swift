//
//  RESTBatchCommand.swift
//  Parse (iOS)
//
//  Created by Florent Vilmart on 17-08-19.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

typealias ParseObjectBatchCommand<T> = BatchCommand<T, T> where T: ObjectType
typealias ParseObjectBatchResponse<T> = [(T, ParseError?)]
// swiftlint:disable line_length
typealias RESTBatchCommandType<T> = RESTCommand<ParseObjectBatchCommand<T>, ParseObjectBatchResponse<T>> where T: ObjectType
// swiftlint:enable line_length

public struct BatchCommand<T, U>: Encodable where T: Encodable {
    let requests: [RESTCommand<T, U>]
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

    func apply<T>(_ object: T) -> T where T: ObjectType {
        if isCreate {
            return asSaveResponse().apply(object)
        } else {
            return asUpdateResponse().apply(object)
        }
    }
}

public class RESTBatchCommand<T>: RESTBatchCommandType<T> where T: ObjectType {
    typealias ParseObjectCommand = RESTCommand<T, T>
    typealias ParseObjectBatchCommand = BatchCommand<T, T>

    init(commands: [ParseObjectCommand]) {
        let commands = commands.flatMap { (command) -> RESTCommand<T, T>? in
            let path = ParseConfiguration.mountPath + command.path.urlComponent
            guard let body = command.body else {
                return nil
            }
            return RESTCommand<T, T>(method: command.method, path: .any(path),
                                     body: body, mapper: command.mapper)
        }
        let bodies = commands.flatMap { (command) -> T? in
            return command.body
        }
        let mapper = { (data: Data) -> [(T, ParseError?)] in
            let decodingType = [BatchResponseItem<SaveOrUpdateResponse>].self
            let responses = try getDecoder().decode(decodingType, from: data)
            return bodies.enumerated().map({ (object) -> (T, ParseError?) in
                let response = responses[object.0]
                if let success = response.success {
                    return (success.apply(object.1), nil)
                } else {
                    return (object.1, response.error)
                }
            })
        }
        let batchCommand = BatchCommand(requests: commands)
        super.init(method: .post, path: .batch, body: batchCommand, mapper: mapper)
    }
}
