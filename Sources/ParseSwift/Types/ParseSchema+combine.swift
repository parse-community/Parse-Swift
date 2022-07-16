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
     Fetches the `ParseSchema` *aynchronously* from the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func fetchPublisher(includeKeys: [String]? = nil,
                        options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.fetch(options: options,
                       completion: promise)
        }
    }

    /**
     Creates the `ParseSchema` *aynchronously* on the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func createPublisher(includeKeys: [String]? = nil,
                         options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.create(options: options,
                        completion: promise)
        }
    }

    /**
     Updates the `ParseSchema` *aynchronously* on the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func updatePublisher(includeKeys: [String]? = nil,
                         options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.update(options: options,
                        completion: promise)
        }
    }

    /**
     Deletes all objects in the `ParseSchema` *aynchronously* from the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: This will delete all objects for this `ParseSchema` and cannot be reversed.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func purgePublisher(includeKeys: [String]? = nil,
                        options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            self.purge(options: options,
                       completion: promise)
        }
    }

    /**
     Deletes the `ParseSchema` *aynchronously* from the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: This can only be used on a `ParseSchema` without objects. If the `ParseSchema`
     currently contains objects, run `purge()` first.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
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
