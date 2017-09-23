//
//  ObjectType+Batch.swift
//  ParseSwift (iOS)
//
//  Created by Florent Vilmart on 17-08-20.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

/*public typealias BatchResultCallback<T> = (Result<[(T, ParseError?)]>) -> Void where T: ObjectType
public extension ObjectType {
    public static func saveAll(_ objects: Self...,
                               callback: BatchResultCallback<Self>?) -> Cancellable {
        return objects.saveAll(callback: callback)
    }
}

extension Sequence where Element: ObjectType {
    public func saveAll(options: API.Option = [], callback: BatchResultCallback<Element>?) -> Cancellable {
        return RESTBatchCommand(commands: map { $0.saveCommand() }).execute(options: options, callback)
    }

    private func saveAllCommand() -> RESTBatchCommand<Element> {
        return RESTBatchCommand(commands: map { $0.saveCommand() })
    }
}
*/
