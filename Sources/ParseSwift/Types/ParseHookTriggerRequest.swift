//
//  ParseHookTriggerRequest.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public struct ParseHookTriggerRequest<U: ParseCloudUser, T: ParseObject>: ParseHookRequestable {
    public typealias UserType = U
    public var masterKey: Bool
    public var user: U?
    public var installationId: String?
    public var ipAddress: String
    public var headers: [String: String]
    public var object: T
    public var objects: [T]?
    public var original: T?
    public var query: Query<T>?
    public var file: ParseFile?
    public var fileSize: Int?

    enum CodingKeys: String, CodingKey {
        case masterKey = "master"
        case ipAddress = "ip"
        case user, installationId, headers,
             object, objects, original,
             query, file, fileSize
    }
}
