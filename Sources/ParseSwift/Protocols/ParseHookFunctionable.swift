//
//  ParseHookFunction.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 `ParseHookFunction` is used for handeling your schemas.
 - requires: `.useMasterKey` has to be available. It is recommended to only
 use the master key in server-side applications where the key is kept secure and not
 exposed to the public.
 */
public protocol ParseHookFunctionable: ParseHookable {
    var functionName: String? { get set }
    var url: URL? { get set }
}

// MARK: Fetch
extension ParseHookFunctionable {
    /**
     Fetches the Parse Hook Function *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func fetch(options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<Self, ParseError>) -> Void) {
        guard let functionName = functionName else {
            let error = ParseError(code: .unknownError,
                                   message: "The \"functionName\" needs to be set")
            completion(.failure(error))
            return
        }
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        fetchCommand(functionName).executeAsync(options: options,
                                                      callbackQueue: callbackQueue) { result in
            completion(result)
        }
    }

    func fetchCommand(_ functionName: String) -> API.NonParseBodyCommand<Self, Self> {
        API.NonParseBodyCommand(method: .GET,
                                path: .hookFunction(name: functionName)) { (data) -> Self in
            if let decoded = try ParseCoding
                .jsonDecoder()
                .decode(AnyResultsResponse<Self>.self, from: data).results.first {
                return decoded
            }
            throw ParseError(code: .objectNotFound,
                             message: "Object not found on the server.")
        }
    }

    /**
     Fetches all of the Parse Hook Functions *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func fetchAll(options: API.Options = [],
                         callbackQueue: DispatchQueue = .main,
                         completion: @escaping (Result<[Self], ParseError>) -> Void) {
        Self.fetchAll(options: options,
                      callbackQueue: callbackQueue,
                      completion: completion)
    }

    /**
     Fetches all of the Parse Hook Functions *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public static func fetchAll(options: API.Options = [],
                                callbackQueue: DispatchQueue = .main,
                                completion: @escaping (Result<[Self], ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        fetchAllCommand().executeAsync(options: options,
                                       callbackQueue: callbackQueue) { result in
            completion(result)
        }
    }

    static func fetchAllCommand() -> API.NonParseBodyCommand<Self, [Self]> {
        API.NonParseBodyCommand(method: .GET,
                                path: .hookFunctions) { (data) -> [Self] in
            try ParseCoding.jsonDecoder().decode([Self].self, from: data)
        }
    }
}

// MARK: Create
extension ParseHookFunctionable {
    func createCommand(_ functionName: String) -> API.NonParseBodyCommand<Self, Self> {
        API.NonParseBodyCommand(method: .POST,
                                path: .hookFunction(name: functionName),
                                body: self) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }
}

// MARK: Update
extension ParseHookFunctionable {
    func updateCommand(_ functionName: String) -> API.NonParseBodyCommand<Self, Self> {
        API.NonParseBodyCommand(method: .PUT,
                                path: .hookFunction(name: functionName),
                                body: self) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }
}

// MARK: Delete
extension ParseHookFunctionable {
    func deleteCommand(functionName: String) -> API.NonParseBodyCommand<Delete, NoBody> {
        API.NonParseBodyCommand(method: .PUT,
                                path: .hookFunction(name: functionName),
                                body: Delete()) { (data) -> NoBody in
            try ParseCoding.jsonDecoder().decode(NoBody.self, from: data)
        }
    }
}
