//
//  ParseLiveQuery+async.swift
//  ParseLiveQuery+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency) && !os(Linux) && !os(Android)
import Foundation

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension ParseLiveQuery {
    // MARK: Async/Await

    /**
     Manually establish a connection to the `ParseLiveQuery` Server. Publishes when established.
      - parameter isUserWantsToConnect: Specifies if the user is calling this function. Defaults to `true`.
      - returns: An instance of the logged in `ParseUser`.
      - throws: `ParseError`.
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
     Sends a ping frame from the client side. Publishes when a pong is received from the
     server endpoint.
     - throws: `ParseError`.
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
