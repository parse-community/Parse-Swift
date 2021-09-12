//
//  API+BatchCommand.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/12/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

internal extension API {
    // MARK: API.BatchCommand
    struct BatchCommand<T, U>: Encodable where T: Encodable {
        typealias ReturnType = U // swiftlint:disable:this nesting
        let method: API.Method
        let path: API.Endpoint
        let body: T?
        let mapper: ((BaseObjectable) throws -> U)

        init(method: API.Method,
             path: API.Endpoint,
             body: T? = nil,
             mapper: @escaping ((BaseObjectable) throws -> U)) {
            self.method = method
            self.path = path
            self.body = body
            self.mapper = mapper
        }

        enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
            case method, body, path
        }
    }
}
