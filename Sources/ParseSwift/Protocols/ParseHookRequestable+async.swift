//
//  ParseHookRequestable+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

#if compiler(>=5.5.2) && canImport(_Concurrency)
public extension ParseHookRequestable {
   /**
    Fetches the complete `ParseUser` *aynchronously*  from the server.
    - parameter options: A set of header options sent to the server. Defaults to an empty set.
    - returns: Returns the `ParseHookRequestable` with the hydrated `ParseCloudUser`.
    - throws: An error of type `ParseError`.
    - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
    desires a different policy, it should be inserted in `options`.
    */
    func hydrateUser(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.hydrateUser(options: options,
                             completion: continuation.resume)
        }
    }
}
#endif
