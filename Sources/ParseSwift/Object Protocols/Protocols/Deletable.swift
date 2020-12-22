//
//  Deletable.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/27/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

public protocol Deletable: Codable {
    associatedtype DeletingType

    func delete(options: API.Options) throws -> DeletingType
    func delete() throws -> DeletingType
}

extension Deletable {
    public func delete() throws -> DeletingType {
        try delete(options: [])
    }
}
