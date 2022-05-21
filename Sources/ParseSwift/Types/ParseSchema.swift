//
//  ParseSchema.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 `ParseSchema` is a local representation of a session.
 This protocol conforms to `ParseObject` and retains the
 same functionality.
 */
public struct ParseSchema<T: ParseObject>: ParseType, Decodable {
    /* associatedtype SchemaObject: ParseObject

    /// The session token for this session.
    var className: String { get set }
    /// The session token for this session.
    var fields: [String: ParseField]? { get set }
    /// The session token for this session.
    var indexes: [String: [String: Int] ]? { get set }
    /// The session token for this session.
    var classLevelPermissions: [String: Codable]? { get set }

    init(className: String) */
    var className: String
    /// The session token for this session.
    internal var fields: [String: ParseField]?
    /// The session token for this session.
    internal var indexes: [String: [String: Int]]?
    /// The session token for this session.
    // internal var classLevelPermissions: [String: Codable]?
}

// MARK: Default Implementations
public extension ParseSchema {
    static var className: String {
        T.className
    }

    init() {
        self.init(className: T.className)
    }

    func addField<V>(_ name: String,
                     type: ParseFieldType,
                     options: ParseFieldOptions<V>) -> Self {
        var mutableSchema = self
        /* switch type {
        case .string:
            <#code#>
        case .number:
            <#code#>
        case .boolean:
            <#code#>
        case .date:
            <#code#>
        case .file:
            <#code#>
        case .geoPoint:
            <#code#>
        case .polygon:
            <#code#>
        case .array:
            <#code#>
        case .object:
            <#code#>
        case .pointer:
            <#code#>
        case .relation:
            <#code#>
        case .bytes:
            <#code#>
        case .acl:
            <#code#>
        } */
        mutableSchema.fields
        
        return mutableSchema
    }

    func addPointer<T, V>(_ name: String,
                          target: T,
                          options: ParseFieldOptions<V>) -> Self where T: ParseObject {
        let field = ParseField(type: .pointer, target: target, options: options)
        var mutableSchema = self
        mutableSchema.fields[name] = field
        
        return mutableSchema
    }
}

// MARK: Convenience
extension ParseSchema {
    static var endpoint: API.Endpoint {
        .schema(className: className)
    }

    static var endpointPurge: API.Endpoint {
        .purge(className: className)
    }

    var endpoint: API.Endpoint {
        .schema(className: className)
    }

    var endpointPurge: API.Endpoint {
        .purge(className: className)
    }
}

// MARK: Fetchable
extension ParseSchema {

    /**
     Fetches the `ParseSchema` *asynchronously* and executes the given callback block.
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
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        do {
            try fetchCommand()
                .executeAsync(options: options,
                              callbackQueue: callbackQueue,
                              completion: completion)
         } catch {
            callbackQueue.async {
                if let error = error as? ParseError {
                    completion(.failure(error))
                } else {
                    completion(.failure(ParseError(code: .unknownError,
                                                   message: error.localizedDescription)))
                }
            }
         }
    }

    func fetchCommand() throws -> API.Command<Self, Self> {

        return API.Command(method: .GET,
                           path: endpoint) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }
}

// MARK: Savable
extension ParseSchema {

    /**
     Creates the `ParseSchema` *asynchronously* and executes the given callback block.
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
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        do {
            try createCommand()
                .executeAsync(options: options,
                              callbackQueue: callbackQueue,
                              completion: completion)
         } catch {
            callbackQueue.async {
                if let error = error as? ParseError {
                    completion(.failure(error))
                } else {
                    completion(.failure(ParseError(code: .unknownError,
                                                   message: error.localizedDescription)))
                }
            }
         }
    }

    /**
     Updates the `ParseSchema` *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func update(options: API.Options = [],
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Self, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        do {
            try updateCommand()
                .executeAsync(options: options,
                              callbackQueue: callbackQueue,
                              completion: completion)
         } catch {
            callbackQueue.async {
                if let error = error as? ParseError {
                    completion(.failure(error))
                } else {
                    completion(.failure(ParseError(code: .unknownError,
                                                   message: error.localizedDescription)))
                }
            }
         }
    }

    func createCommand() throws -> API.Command<Self, Self> {

        return API.Command(method: .POST,
                           path: endpoint,
                           body: self) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }

    func updateCommand() throws -> API.Command<Self, Self> {

        API.Command(method: .PUT,
                    path: endpoint,
                    body: self) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }
}

// MARK: Deletable
extension ParseSchema {

    /**
     Deletes all objects in the `ParseSchema` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - warning: This will delete all objects for this `ParseSchema` and cannot be reversed.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func purge(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Void, ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
         do {
            try deleteCommand().executeAsync(options: options,
                                             callbackQueue: callbackQueue) { result in
                switch result {

                case .success:
                    completion(.success(()))
                case .failure(let error):
                    callbackQueue.async {
                        completion(.failure(error))
                    }
                }
            }
         } catch let error as ParseError {
            callbackQueue.async {
                completion(.failure(error))
            }
         } catch {
            callbackQueue.async {
                completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
            }
         }
    }

    /**
     Deletes the `ParseSchema` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - warning: This can only be used on a `ParseSchema` without objects. If the `ParseSchema`
     currently contains objects, run `purge()` first.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func delete(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Void, ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
         do {
            try deleteCommand().executeAsync(options: options,
                                             callbackQueue: callbackQueue) { result in
                switch result {

                case .success:
                    completion(.success(()))
                case .failure(let error):
                    callbackQueue.async {
                        completion(.failure(error))
                    }
                }
            }
         } catch let error as ParseError {
            callbackQueue.async {
                completion(.failure(error))
            }
         } catch {
            callbackQueue.async {
                completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
            }
         }
    }

    func purgeCommand() throws -> API.Command<Self, NoBody> {

        API.Command(method: .DELETE,
                    path: endpointPurge) { (data) -> NoBody in
            let error = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
            if let error = error {
                throw error
            } else {
                return NoBody()
            }
        }
    }

    func deleteCommand() throws -> API.Command<Self, NoBody> {

        API.Command(method: .DELETE,
                    path: endpoint,
                    body: self) { (data) -> NoBody in
            let error = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
            if let error = error {
                throw error
            } else {
                return NoBody()
            }
        }
    }
}
