//
//  ParseCloudable.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/29/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

public protocol ParseCloudTypeable: ParseEncodable {}

/**
 Objects that conform to the `ParseCloud` protocol are able to call Parse Cloud Functions and Jobs.
 An object should be instantiated for each function and job type. When conforming to
 `ParseCloud`, any properties added will be passed as parameters to your Cloud Function or Job.
*/
@available(*, deprecated, renamed: "ParseCloudable")
public typealias ParseCloud = ParseCloudable

/**
 Objects that conform to the `ParseCloudable` protocol are able to call Parse Cloud Functions and Jobs.
 An object should be instantiated for each function and job type. When conforming to
 `ParseCloudable`, any properties added will be passed as parameters to your Cloud Function or Job.
*/
public protocol ParseCloudable: ParseCloudTypeable, Hashable {

    associatedtype ReturnType: Decodable
    /**
     The name of the function or job.
    */
    var functionJobName: String { get set }

}

// MARK: Functions
extension ParseCloudable {

    /**
     Calls a Cloud Code function *synchronously* and returns a result of it is execution.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - returns: Returns a `Decodable` type.
        - throws: An error of type `ParseError`.
    */
    public func runFunction(options: API.Options = []) throws -> ReturnType {
        try runFunctionCommand().execute(options: options)
    }

    /**
     Calls a Cloud Code function *asynchronously* and returns a result of it is execution.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of .main.
        - parameter completion: A block that will be called when the Cloud Code completes or fails.
        It should have the following argument signature: `(Result<ReturnType, ParseError>)`.
    */
    public func runFunction(options: API.Options = [],
                            callbackQueue: DispatchQueue = .main,
                            completion: @escaping (Result<ReturnType, ParseError>) -> Void) {
        runFunctionCommand()
            .executeAsync(options: options, callbackQueue: callbackQueue) { result in
                completion(result)
            }
    }

    internal func runFunctionCommand() -> API.Command<Self, ReturnType> {
        API.Command(method: .POST,
                    path: .functions(name: functionJobName),
                    body: self) { (data) -> ReturnType in
            let response = try ParseCoding.jsonDecoder().decode(AnyResultResponse<ReturnType>.self, from: data)
            return response.result
        }
    }
}

// MARK: Jobs
extension ParseCloudable {
    /**
     Starts a Cloud Code Job *synchronously* and returns a result with the jobStatusId of the job.
          - parameter options: A set of header options sent to the server. Defaults to an empty set.
          - returns: Returns a `Decodable` type.
    */
    public func startJob(options: API.Options = []) throws -> ReturnType {
        try startJobCommand().execute(options: options)
    }

    /**
     Starts a Cloud Code Job *asynchronously* and returns a result with the jobStatusId of the job.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of .main.
        - parameter completion: A block that will be called when the Cloud Code Job completes or fails.
        It should have the following argument signature: `(Result<ReturnType, ParseError>)`.
    */
    public func startJob(options: API.Options = [],
                         callbackQueue: DispatchQueue = .main,
                         completion: @escaping (Result<ReturnType, ParseError>) -> Void) {
        startJobCommand()
            .executeAsync(options: options, callbackQueue: callbackQueue) { result in
                completion(result)
            }
    }

    internal func startJobCommand() -> API.Command<Self, ReturnType> {
        API.Command(method: .POST,
                    path: .jobs(name: functionJobName),
                    body: self) { (data) -> ReturnType in
            let response = try ParseCoding.jsonDecoder().decode(AnyResultResponse<ReturnType>.self, from: data)
            return response.result
        }
    }
}
