//
//  Saving.swift
//  ParseSwift (iOS)
//
//  Created by Pranjal Satija on 9/10/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public protocol Saving: Codable {
    associatedtype SavingType
    func save(options: API.Option, callback: @escaping ((Result<SavingType>) -> Void)) -> Cancellable
    func save(callback: @escaping ((Result<SavingType>) -> Void)) -> Cancellable
}

extension Saving {
    public func save(callback: @escaping ((Result<SavingType>) -> Void)) -> Cancellable {
        return save(options: [], callback: callback)
    }
}
