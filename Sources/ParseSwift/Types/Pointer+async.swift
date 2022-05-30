//
//  Pointer+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 11/1/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

// MARK: Async/Await
public extension Pointer {
    /**
     Fetches the `ParseObject` *aynchronously* with the current data from the server.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: The `ParseObject` with respect to the `Pointer`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetch(includeKeys: [String]? = nil,
               options: API.Options = []) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            self.fetch(includeKeys: includeKeys,
                       options: options,
                       completion: continuation.resume)
        }
    }
}

#endif
