//
//  ParseLiveQuery+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/24/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

extension ParseLiveQuery {
    // MARK: Connection - Combine

    /**
     Manually establish a connection to the `ParseLiveQuery` Server. Publishes when established.
      - parameter isUserWantsToConnect: Specifies if the user is calling this function. Defaults to **true**.
      - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    public func openPublisher(isUserWantsToConnect: Bool = true) -> Future<Void, Error> {
        Future { promise in
            self.open(isUserWantsToConnect: isUserWantsToConnect) { error in
                guard let error = error else {
                    promise(.success(()))
                    return
                }
                promise(.failure(error))
            }
        }
    }

    /**
     Sends a ping frame from the client side. Publishes when a pong is received from the
     server endpoint.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    public func sendPingPublisher() -> Future<Void, Error> {
        Future { promise in
            self.sendPing { error in
                guard let error = error else {
                    promise(.success(()))
                    return
                }
                promise(.failure(error))
            }
        }
    }
}
#endif
