//
//  ParseSchema+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/22/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseSchema {
    /**
     Fetches the `ParseObject` *aynchronously* from the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetchPublisher(includeKeys: [String]? = nil,
                        options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.fetch(options: options,
                       completion: promise)
        }
    }

    /**
     Creates the `ParseObject` *aynchronously* on the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func createPublisher(includeKeys: [String]? = nil,
                         options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.create(options: options,
                        completion: promise)
        }
    }

    /**
     Updates the `ParseObject` *aynchronously* on the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func updatePublisher(includeKeys: [String]? = nil,
                         options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.update(options: options,
                        completion: promise)
        }
    }

    /**
     Deletes all objects in the `ParseObject` *aynchronously* from the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: This will delete all objects for this `ParseSchema` and cannot be reversed.
    */
    func purgePublisher(includeKeys: [String]? = nil,
                        options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            self.purge(options: options,
                       completion: promise)
        }
    }

    /**
     Deletes the `ParseObject` *aynchronously* from the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: This can only be used on a `ParseSchema` without objects. If the `ParseSchema`
     currently contains objects, run `purge()` first.
    */
    func deletePublisher(includeKeys: [String]? = nil,
                         options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            self.delete(options: options,
                        completion: promise)
        }
    }
}

#endif
