//
//  ParseHookFunction.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 Conforming to `ParseHookFunctionable` allows the creation of hooks
 which are Cloud Code functions.
 - requires: `.useMasterKey` has to be available. It is recommended to only
 use the master key in server-side applications where the key is kept secure and not
 exposed to the public.
 */
public protocol ParseHookFunctionable: ParseHookable {
    /**
     The name of the function.
    */
    var functionName: String? { get set }
}

// MARK: Default Implementation
public extension ParseHookFunctionable {
    /**
     Creates a new Parse hook function.
     - parameter name: The name of the function.
     - parameter url: The endpoint of the hook.
     */
    init(name: String, url: URL?) {
        self.init()
        functionName = name
        self.url = url
    }
}

internal struct FunctionRequest: Encodable {
    let functionName: String
    let url: URL?

    init<F>(hookFunction: F) throws where F: ParseHookFunctionable {
        guard let functionName = hookFunction.functionName else {
            throw ParseError(code: .unknownError,
                             message: "The \"functionName\" needs to be set: \(hookFunction)")
        }
        self.functionName = functionName
        self.url = hookFunction.url
    }
}

// MARK: Fetch
extension ParseHookFunctionable {
    /**
     Fetches the Parse hook function *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func fetch(options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<Self, ParseError>) -> Void) {
        var options = options
        options.insert(.useMasterKey)
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        do {
            try fetchCommand().executeAsync(options: options,
                                            callbackQueue: callbackQueue) { result in
                completion(result)
            }
        } catch {
            let defaultError = ParseError(code: .unknownError,
                                          message: error.localizedDescription)
            let parseError = error as? ParseError ?? defaultError
            completion(.failure(parseError))
        }
    }

    func fetchCommand() throws -> API.NonParseBodyCommand<Self, Self> {
        let request = try FunctionRequest(hookFunction: self)
        return API.NonParseBodyCommand(method: .GET,
                                       path: .hookFunction(request: request)) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }

    /**
     Fetches all of the Parse hook functions *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
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
     Fetches all of the Parse hook functions *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public static func fetchAll(options: API.Options = [],
                                callbackQueue: DispatchQueue = .main,
                                completion: @escaping (Result<[Self], ParseError>) -> Void) {
        var options = options
        options.insert(.useMasterKey)
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
    /**
     Creates the Parse hook function *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func create(options: API.Options = [],
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Self, ParseError>) -> Void) {
        var options = options
        options.insert(.useMasterKey)
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        do {
            try createCommand().executeAsync(options: options,
                                             callbackQueue: callbackQueue) { result in
                completion(result)
            }
        } catch {
            let defaultError = ParseError(code: .unknownError,
                                          message: error.localizedDescription)
            let parseError = error as? ParseError ?? defaultError
            completion(.failure(parseError))
        }
    }

    func createCommand() throws -> API.NonParseBodyCommand<FunctionRequest, Self> {
        let request = try FunctionRequest(hookFunction: self)
        return API.NonParseBodyCommand(method: .POST,
                                       path: .hookFunctions,
                                       body: request) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }
}

// MARK: Update
extension ParseHookFunctionable {
    /**
     Fetches the Parse hook function *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: Do not use on Parse Server 5.3.0 and below. Instead, delete and create.
    */
    public func update(options: API.Options = [],
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Self, ParseError>) -> Void) {
        var options = options
        options.insert(.useMasterKey)
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        do {
            try updateCommand().executeAsync(options: options,
                                             callbackQueue: callbackQueue) { result in
                completion(result)
            }
        } catch {
            let defaultError = ParseError(code: .unknownError,
                                          message: error.localizedDescription)
            let parseError = error as? ParseError ?? defaultError
            completion(.failure(parseError))
        }
    }

    func updateCommand() throws -> API.NonParseBodyCommand<FunctionRequest, Self> {
        let request = try FunctionRequest(hookFunction: self)
        return API.NonParseBodyCommand(method: .PUT,
                                       path: .hookFunction(request: request),
                                       body: request) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }
}

// MARK: Delete
extension ParseHookFunctionable {
    /**
     Deletes the Parse hook function *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func delete(options: API.Options = [],
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Void, ParseError>) -> Void) {
        var options = options
        options.insert(.useMasterKey)
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        do {
            try deleteCommand().executeAsync(options: options,
                                             callbackQueue: callbackQueue) { result in
                switch result {

                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            let defaultError = ParseError(code: .unknownError,
                                          message: error.localizedDescription)
            let parseError = error as? ParseError ?? defaultError
            completion(.failure(parseError))
        }
    }

    func deleteCommand() throws -> API.NonParseBodyCommand<Delete, NoBody> {
        let request = try FunctionRequest(hookFunction: self)
        return API.NonParseBodyCommand(method: .PUT,
                                       path: .hookFunction(request: request),
                                       body: Delete()) { (data) -> NoBody in
            try ParseCoding.jsonDecoder().decode(NoBody.self, from: data)
        }
    }
}
