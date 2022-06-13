//
//  ParsePush+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/5/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParsePush {
    /**
     Sends a Parse push notification *aynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func sendPublisher(options: API.Options = []) -> Future<String, ParseError> {
        Future { promise in
            self.send(options: options,
                      completion: promise)
        }
    }

    /**
     Fetches the `ParsePushStatus` *aynchronously* from the server. Publishes when complete.
     - parameter statusId: The `objectId` of the `ParsePushStatus`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func fetchStatusPublisher(_ statusId: String,
                              options: API.Options = []) -> Future<ParsePushStatus<V>, ParseError> {
        Future { promise in
            self.fetchStatus(statusId,
                             options: options,
                             completion: promise)
        }
    }
}
#endif
