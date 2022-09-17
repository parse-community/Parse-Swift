//
//  API+NonParseBodyCommand+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/17/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension API.NonParseBodyCommand {
    // MARK: Asynchronous Execution
    func executeAsync(options: API.Options,
                      callbackQueue: DispatchQueue) async throws -> U {
        try await withCheckedThrowingContinuation { continuation in
            self.executeAsync(options: options,
                              callbackQueue: callbackQueue,
                              completion: continuation.resume)
        }
    }
}
#endif
