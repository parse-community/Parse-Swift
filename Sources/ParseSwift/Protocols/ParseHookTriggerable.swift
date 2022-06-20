//
//  ParseHookTriggerable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public protocol ParseHookTriggerable: ParseHookable {
    /// The name of the `ParseObject` the trigger should act on.
    var className: String? { get set }
    /// The `ParseHookTriggerType` type.
    var triggerName: ParseHookTriggerType? { get set }
}

// MARK: Default Implementation
public extension ParseHookTriggerable {
    /**
     Creates a new Parse hook trigger.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter url: The endpoint of the hook.
     */
    init(className: String, triggerName: ParseHookTriggerType, url: URL? = nil) {
        self.init()
        self.className = className
        self.triggerName = triggerName
        self.url = url
    }

    /**
     Creates a new Parse hook trigger.
     - parameter object: The `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter url: The endpoint of the hook.
     */
    init<T>(object: T, triggerName: ParseHookTriggerType, url: URL?) where T: ParseObject {
        self.init(className: T.className, triggerName: triggerName, url: url)
    }
}

internal struct TriggerRequest: Encodable {
    let className: String
    let triggerName: ParseHookTriggerType
    let url: URL?

    init<T>(trigger: T) throws where T: ParseHookTriggerable {
        guard let className = trigger.className,
              let triggerName = trigger.triggerName else {
            throw ParseError(code: .unknownError,
                             message: "The \"className\" and \"triggerName\" needs to be set: \(trigger)")
        }
        self.className = className
        self.triggerName = triggerName
        self.url = trigger.url
    }
}

// MARK: Fetch
extension ParseHookTriggerable {
    /**
     Fetches the Parse hook trigger *asynchronously* and executes the given callback block.
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
        var options = options
        options.insert(.useMasterKey)
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        do {
            try fetchCommand().executeAsync(options: options,
                                            callbackQueue: callbackQueue) { result in
                completion(result)
            }
        } catch {
            let parseError = error as? ParseError ?? ParseError(code: .unknownError,
                                                                message: error.localizedDescription)
            completion(.failure(parseError))
        }
    }

    func fetchCommand() throws -> API.NonParseBodyCommand<Self, Self> {
        let request = try TriggerRequest(trigger: self)
        return API.NonParseBodyCommand(method: .GET,
                                       path: .hookTrigger(request: request)) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: try Self.checkHookKey(data))
        }
    }

    /**
     Fetches all of the Parse hook triggers *asynchronously* and executes the given callback block.
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
     Fetches all of the Parse hook triggers *asynchronously* and executes the given callback block.
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
        options.insert(.useMasterKey)
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        fetchAllCommand().executeAsync(options: options,
                                       callbackQueue: callbackQueue) { result in
            completion(result)
        }
    }

    static func fetchAllCommand() -> API.NonParseBodyCommand<Self, [Self]> {
        API.NonParseBodyCommand(method: .GET,
                                path: .hookTriggers) { (data) -> [Self] in
            try ParseCoding.jsonDecoder().decode([Self].self, from: try checkHookKey(data))
        }
    }
}

// MARK: Create
extension ParseHookTriggerable {
    /**
     Creates the Parse hook trigger *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
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
            let parseError = error as? ParseError ?? ParseError(code: .unknownError,
                                                                message: error.localizedDescription)
            completion(.failure(parseError))
        }
    }

    func createCommand() throws -> API.NonParseBodyCommand<TriggerRequest, Self> {
        let request = try TriggerRequest(trigger: self)
        return API.NonParseBodyCommand(method: .POST,
                                       path: .hookTriggers,
                                       body: request) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: try Self.checkHookKey(data))
        }
    }
}

// MARK: Update
extension ParseHookTriggerable {
    /**
     Fetches the Parse hook trigger *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
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
            let parseError = error as? ParseError ?? ParseError(code: .unknownError,
                                                                message: error.localizedDescription)
            completion(.failure(parseError))
        }
    }

    func updateCommand() throws -> API.NonParseBodyCommand<TriggerRequest, Self> {
        let request = try TriggerRequest(trigger: self)
        return API.NonParseBodyCommand(method: .PUT,
                                       path: .hookTrigger(request: request),
                                       body: request) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: try Self.checkHookKey(data))
        }
    }
}

// MARK: Delete
extension ParseHookTriggerable {
    /**
     Deletes the Parse hook trigger *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
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
            let parseError = error as? ParseError ?? ParseError(code: .unknownError,
                                                                message: error.localizedDescription)
            completion(.failure(parseError))
        }
    }

    func deleteCommand() throws -> API.NonParseBodyCommand<Delete, NoBody> {
        let request = try TriggerRequest(trigger: self)
        return API.NonParseBodyCommand(method: .PUT,
                                       path: .hookTrigger(request: request),
                                       body: Delete()) { (data) -> NoBody in
            try ParseCoding.jsonDecoder().decode(NoBody.self, from: try Self.checkHookKey(data))
        }
    }
}
