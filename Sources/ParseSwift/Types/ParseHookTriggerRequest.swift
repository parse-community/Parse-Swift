//
//  ParseHookTriggerRequest.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 A type that can decode requests when `ParseHookTriggerable` triggers are called.
 - requires: `.useMasterKey` has to be available. It is recommended to only
 use the master key in server-side applications where the key is kept secure and not
 exposed to the public.
 */
public struct ParseHookTriggerRequest<U: ParseCloudUser, T: ParseObject>: ParseHookRequestable {
    public typealias UserType = U
    public var masterKey: Bool?
    public var user: U?
    public var installationId: String?
    public var ipAddress: String?
    public var headers: [String: String]?
    /// An object from the hook call.
    public var object: T?
    /// The results the query yielded..
    public var objects: [T]?
    /// If set, the object, as currently stored.
    public var original: T?
    /// The query from the hook call.
    public var query: Query<T>?
    /// Whether the query a **get** or a **find**.
    public var isGet: Bool?
    /// The  from the hook call.
    public var file: ParseFile?
    /// The size of the file in bytes.
    public var fileSize: Int?
    /// The value from Content-Length header.
    public var contentLength: Int?
    /// The number of clients connected.
    public var clients: Int?
    /// The number of subscriptions connected.
    public var subscriptions: Int?
    /**
     If the LiveQuery event should be sent to the client. Set to false to prevent
     LiveQuery from pushing to the client.
     */
    public var sendEvent: Bool?
    /// The live query event that triggered the request.
    public var event: String?
    var log: AnyCodable?
    var context: AnyCodable?

    enum CodingKeys: String, CodingKey {
        case masterKey = "master"
        case ipAddress = "ip"
        case user, installationId, headers,
             log, context, object, objects,
             original, query, file, fileSize,
             isGet, contentLength, clients,
             subscriptions, sendEvent
    }
}

extension ParseHookTriggerRequest {

    /**
     Get the Parse Server logger using any type that conforms to `Codable`.
     - returns: The sound casted to the inferred type.
     - throws: An error of type `ParseError`.
     */
    public func getLog<V>() throws -> V where V: Codable {
        guard let log = log?.value as? V else {
            throw ParseError(code: .unknownError,
                             message: "Cannot be casted to the inferred type")
        }
        return log
    }

    /**
     Get the context using any type that conforms to `Codable`.
     - returns: The sound casted to the inferred type.
     - throws: An error of type `ParseError`.
     */
    public func getContext<V>() throws -> V where V: Codable {
        guard let context = context?.value as? V else {
            throw ParseError(code: .unknownError,
                             message: "Cannot be casted to the inferred type")
        }
        return context
    }
}
