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
    /// An object from the hook call.
    public var object: T
    /// An array of objects from the hook call.
    public var objects: [T]?
    /// The original object from the hook call.
    public var original: T?
    /// The query from the hook call.
    public var query: Query<T>?
    /// The file from the hook call.
    public var file: ParseFile?
    /// The size of the file from the hook call.
    public var fileSize: Int?

    enum CodingKeys: String, CodingKey {
        case masterKey = "master"
        case ipAddress = "ip"
        case user, installationId, headers,
             object, objects, original,
             query, file, fileSize
    }
}
