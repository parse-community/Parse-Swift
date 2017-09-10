//
//  Fetching.swift
//  ParseSwift (iOS)
//
//  Created by Pranjal Satija on 9/10/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public protocol Fetching: Codable {
    associatedtype FetchingType
    func fetch(options: API.Option, callback: @escaping ((Result<FetchingType>) -> Void)) -> Cancellable?
    func fetch(callback: @escaping ((Result<FetchingType>) -> Void)) -> Cancellable?
}

extension Fetching {
    public func fetch(callback: @escaping ((Result<FetchingType>) -> Void)) -> Cancellable? {
        return fetch(options: [], callback: callback)
    }
}
