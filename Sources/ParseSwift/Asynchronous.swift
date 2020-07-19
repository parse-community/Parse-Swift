//
//  Asynchronous.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-20.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

private let queue = DispatchQueue(label: "com.parse.ParseSwift.async")

private func runAsync<T>(options: API.Options,
                         function: @escaping (API.Options) throws -> T?,
                         callback: @escaping (T?, Error?) -> Void) {
    queue.async {
        do {
            callback(try function(options), nil)
        } catch let error {
            callback(nil, error)
        }
    }
}

extension Saveable {
    public func save(options: API.Options = [], callback: @escaping (Self.SavingType?, Error?) -> Void) {
        runAsync(options: options, function: self.save, callback: callback)
    }
}

extension Fetchable {
    public func fetch(options: API.Options = [], callback: @escaping (Self.FetchingType?, Error?) -> Void) {
        runAsync(options: options, function: self.fetch, callback: callback)
    }
}

extension Queryable {
    public func find(options: API.Options = [], callback: @escaping ([ResultType]?, Error?) -> Void) {
        runAsync(options: options, function: self.find, callback: callback)
    }
    public func first(options: API.Options = [], callback: @escaping (ResultType?, Error?) -> Void) {
        runAsync(options: options, function: self.first, callback: callback)
    }
    public func count(options: API.Options = [], callback: @escaping (Int?, Error?) -> Void) {
        runAsync(options: options, function: self.count, callback: callback)
    }
}

public extension ParseObject {
    static func saveAll(options: API.Options = [],
                        _ objects: Self...,
                        callback: @escaping ([(Self, ParseError?)]?, Error?) -> Void) {
        objects.saveAll(options: options, callback: callback)
    }
}

public extension Sequence where Element: ParseObject {
    func saveAll(options: API.Options = [],
                 callback: @escaping ([(Element, ParseError?)]?, Error?) -> Void) {
        runAsync(options: options, function: self.saveAll, callback: callback)
    }
}
