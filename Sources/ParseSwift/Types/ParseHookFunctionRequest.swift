//
//  ParseHookRequest.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public struct ParseHookFunctionRequest<U: ParseCloudUser, P: ParseHookParametable>: ParseHookRequestable {
    public typealias UsertType = U
    public var masterKey: Bool
    public var user: U?
    public var installationId: String?
    public var parameters: P
    public var ipAddress: String
    public var headers: [String: String]
    var log: AnyCodable?
    var context: AnyCodable?

    enum CodingKeys: String, CodingKey {
        case masterKey = "master"
        case parameters = "params"
        case ipAddress = "ip"
        case user, installationId,
             headers, log, context
    }
}

extension ParseHookFunctionRequest {
    /**
     Get the log using any type that conforms to `Codable`.
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
