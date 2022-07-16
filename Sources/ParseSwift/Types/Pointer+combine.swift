//
//  Pointer+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 11/1/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

// MARK: Combine
public extension Pointer {
    /**
     Fetches the `ParseObject` *aynchronously* with the current data from the server.
     Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetchPublisher(includeKeys: [String]? = nil,
                        options: API.Options = []) -> Future<T, ParseError> {
        Future { promise in
            self.fetch(includeKeys: includeKeys,
                       options: options,
                       completion: promise)
        }
    }
}
#endif
