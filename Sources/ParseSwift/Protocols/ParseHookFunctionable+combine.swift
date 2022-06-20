//
//  ParseHookFunctionable+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/19/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

// MARK: Fetch
extension ParseHookFunctionable {
    /**
     Fetches the Parse hook function *asynchronously*. Publishes when complete.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func fetchPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.fetch(options: options, completion: promise)
        }
    }
}

// MARK: Create
extension ParseHookFunctionable {
    /**
     Creates the Parse hook function *asynchronously*. Publishes when complete.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func createPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.create(options: options, completion: promise)
        }
    }
}

// MARK: Update
extension ParseHookFunctionable {
    /**
     Updates the Parse hook function *asynchronously*. Publishes when complete.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func updatePublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.update(options: options, completion: promise)
        }
    }
}

// MARK: Delete
extension ParseHookFunctionable {
    /**
     Deletes the Parse hook function *asynchronously*. Publishes when complete.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func deletePublisher(options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            self.delete(options: options, completion: promise)
        }
    }
}

#endif
