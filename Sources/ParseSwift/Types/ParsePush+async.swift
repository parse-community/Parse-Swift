//
//  ParsePush+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/5/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParsePush {
    /**
     Sends the `ParsePush` *aynchronously* to the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the `ParsePushStatus` `objectId`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func send(options: API.Options = []) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.send(options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Fetches the `ParsePushStatus` *aynchronously* from the server.
     - parameter statusId: The `objectId` of the `ParsePushStatus`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the fetched `ParsePushStatus`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func fetchStatus(_ statusId: String,
                     options: API.Options = []) async throws -> ParsePushStatus<V> {
        try await withCheckedThrowingContinuation { continuation in
            self.fetchStatus(statusId,
                             options: options,
                             completion: continuation.resume)
        }
    }
}
#endif
