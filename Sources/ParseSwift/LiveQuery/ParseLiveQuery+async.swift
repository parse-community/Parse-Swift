//
//  ParseLiveQuery+async.swift
//  ParseLiveQuery+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency) && !os(Linux) && !os(Android) && !os(Windows)
import Foundation

extension ParseLiveQuery {
    // MARK: Connection - Async/Await

    /**
     Manually establish a connection to the `ParseLiveQuery` Server.
      - parameter isUserWantsToConnect: Specifies if the user is calling this function. Defaults to **true**.
      - returns: An instance of the logged in `ParseUser`.
      - throws: An error of type `ParseError`.
    */
    public func open(isUserWantsToConnect: Bool = true) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            self.open(isUserWantsToConnect: isUserWantsToConnect) { error in
                guard let error = error else {
                    continuation.resume(with: .success(()))
                    return
                }
                continuation.resume(with: .failure(error))
            }
        }
    }

    /**
     Sends a ping frame from the client side. Returns when a pong is received from the
     server endpoint.
     - throws: An error of type `ParseError`.
    */
    public func sendPing() async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            self.sendPing { error in
                guard let error = error else {
                    continuation.resume(with: .success(()))
                    return
                }
                continuation.resume(with: .failure(error))
            }
        }
    }
}

#endif
