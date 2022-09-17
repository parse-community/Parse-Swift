//
//  ParseCloudable+async.swift
//  ParseCloudable+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParseCloudable {

    // MARK: Aysnc/Await

    /**
     Calls a Cloud Code function *asynchronously* and returns a result of it is execution.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: The return type.
     - throws: An error of type `ParseError`.
    */
    func runFunction(options: API.Options = []) async throws -> ReturnType {
        try await withCheckedThrowingContinuation { continuation in
            self.runFunction(options: options,
                             completion: continuation.resume)
        }
    }

    /**
     Starts a Cloud Code Job *asynchronously* and returns a result with the jobStatusId of the job.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: The return type.
     - throws: An error of type `ParseError`.
    */
    func startJob(options: API.Options = []) async throws -> ReturnType {
        try await withCheckedThrowingContinuation { continuation in
            self.startJob(options: options,
                          completion: continuation.resume)
        }
    }
}
#endif
