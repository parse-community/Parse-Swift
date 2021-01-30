//
//  ParseCloud+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if !os(Linux)
import Foundation
import Combine

// MARK: Combine
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseCloud {

    /**
     Calls a Cloud Code function *asynchronously* and returns a result of it's execution.
     Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func runFunctionPublisher(options: API.Options = []) -> Future<AnyCodable, ParseError> {
        Future { promise in
            runFunction(options: options,
                        completion: promise)
        }
    }

    /**
     Starts a Cloud Code job *asynchronously* and returns a result with the jobStatusId of the job.
     Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func startJobPublisher(options: API.Options = []) -> Future<AnyCodable, ParseError> {
        Future { promise in
            startJob(options: options,
                        completion: promise)
        }
    }
}

#endif
