//
//  ParseCloud+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseCloud {

    // MARK: Combine

    /**
     Calls a Cloud Code function *asynchronously* and returns a result of it's execution.
     Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func runFunctionPublisher(options: API.Options = []) -> Future<ReturnType, ParseError> {
        Future { promise in
            self.runFunction(options: options,
                             completion: promise)
        }
    }

    /**
     Starts a Cloud Code Job *asynchronously* and returns a result with the jobStatusId of the job.
     Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func startJobPublisher(options: API.Options = []) -> Future<ReturnType, ParseError> {
        Future { promise in
            self.startJob(options: options,
                          completion: promise)
        }
    }
}

#endif
