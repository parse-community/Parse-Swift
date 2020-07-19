//
//  Fetchable.swift
//  ParseSwift
//
//  Created by Pranjal Satija on 7/18/20.
//  Copyright © 2020 Parse. All rights reserved.
//

public protocol Fetching: Codable {
    associatedtype FetchingType

    func fetch(options: API.Options) throws -> FetchingType
    func fetch() throws -> FetchingType
}

extension Fetching {
    public func fetch() throws -> FetchingType {
        return try fetch(options: [])
    }
}
