//
//  ParseCloud.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/29/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

/**
 Objects that conform to the `ParseCloud` protocol are able to call Parse Cloud Functions and Jobs.
 An object should be should be instantiated for each function and job type. When conforming to
 `ParseCloud`, any properties added will be passed as parameters to your Cloud Function or Job.
*/
public protocol ParseCloud: Encodable, CustomDebugStringConvertible {
    /**
    The name of the function or job.
    */
    var functionJobName: String { get set }

}

// MARK: Functions
extension ParseCloud {
    public typealias AnyResultType = [String: AnyCodable]

    /**
     *Synchronously* Calls a Cloud Code function and returns a result of it's execution.
     *     - parameter options: A set of header options sent to the server. Defaults to an empty set.
    */
    public func callFunction(options: API.Options = []) throws -> AnyResultType {
        try callFunctionCommand().execute(options: options)
    }

    /**
     *Asynchronously* Calls a Cloud Code function and returns a result of it's execution.
     *     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     *     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     *     - parameter completion: A block that will be called when logging out, completes or fails.
    */
    public func callFunction(options: API.Options = [],
                             callbackQueue: DispatchQueue = .main,
                             completion: @escaping (Result<AnyResultType, ParseError>) -> Void) {
        callFunctionCommand()
            .executeAsync(options: options,
                          callbackQueue: callbackQueue, completion: completion)
    }

    internal func callFunctionCommand() -> API.Command<Self, AnyResultType> {

        return API.Command(method: .POST,
                           path: .functions(name: functionJobName),
                           body: self) { (data) -> AnyResultType in
            try ParseCoding.jsonDecoder().decode(AnyResultType.self, from: data)
        }
    }
}

// MARK: Jobs
extension ParseCloud {
    /**
     *Synchronously* Calls a Cloud Code job and returns a result of it's execution.
     *     - parameter options: A set of header options sent to the server. Defaults to an empty set.
    */
    public func callJob(options: API.Options = []) throws -> AnyResultType {
        try callJobCommand().execute(options: options)
    }

    /**
     *Asynchronously* Calls a Cloud Code job and returns a result of it's execution.
     *     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     *     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     *     - parameter completion: A block that will be called when logging out, completes or fails.
    */
    public func callJob(options: API.Options = [],
                        callbackQueue: DispatchQueue = .main,
                        completion: @escaping (Result<AnyResultType, ParseError>) -> Void) {
        callJobCommand()
            .executeAsync(options: options,
                          callbackQueue: callbackQueue, completion: completion)
    }

    internal func callJobCommand() -> API.Command<Self, AnyResultType> {
        return API.Command(method: .POST,
                           path: .jobs(name: functionJobName),
                           body: self) { (data) -> AnyResultType in
            try ParseCoding.jsonDecoder().decode(AnyResultType.self, from: data)
        }
    }
}

// MARK: CustomDebugStringConvertible
extension ParseCloud {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.parseEncoder(skipKeys: false).encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "\(functionJobName)"
        }

        return "\(descriptionString)"
    }
}
