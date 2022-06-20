//
//  ParseHookTriggerable+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/19/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

// MARK: Fetch
extension ParseHookTriggerable {
    /**
     Fetches the Parse hook trigger *asynchronously*. Publishes when complete.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func fetchPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.fetch(options: options, completion: promise)
        }
    }
}

// MARK: Create
extension ParseHookTriggerable {
    /**
     Creates the Parse hook trigger *asynchronously*. Publishes when complete.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func createPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.create(options: options, completion: promise)
        }
    }
}

// MARK: Update
extension ParseHookTriggerable {
    /**
     Updates the Parse hook trigger *asynchronously*. Publishes when complete.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func updatePublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.update(options: options, completion: promise)
        }
    }
}

// MARK: Delete
extension ParseHookTriggerable {
    /**
     Deletes the Parse hook trigger *asynchronously*. Publishes when complete.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func deletePublisher(options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            self.delete(options: options, completion: promise)
        }
    }
}
#endif
