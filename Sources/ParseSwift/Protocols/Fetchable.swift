//
//  Fetchable.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2020 Parse. All rights reserved.
//

public protocol Fetchable: Decodable {
    associatedtype FetchingType

    func fetch(includeKeys: [String]?, options: API.Options) throws -> FetchingType
    func fetch() throws -> FetchingType
}

extension Fetchable {
    public func fetch() throws -> FetchingType {
        try fetch(includeKeys: nil, options: [])
    }
}
