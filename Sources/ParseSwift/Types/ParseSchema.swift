//
//  ParseSchema.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 `ParseSchema` is used for handeling your schemas.
 - requires: `.useMasterKey` has to be available. It is recommended to only
 use the master key in server-side applications where the key is kept secure and not
 exposed to the public.
 */
public struct ParseSchema<SchemaObject: ParseObject>: ParseType, Decodable {

    /// The class name of the `ParseSchema`.
    public var className: String
    /// The CLPs of this `ParseSchema`.
    public var classLevelPermissions: ParseCLP?
    internal var fields: [String: ParseField]?
    internal var indexes: [String: [String: AnyCodable]]?
    internal var pendingIndexes = [String: [String: AnyCodable]]()

    enum CodingKeys: String, CodingKey {
        case className, classLevelPermissions, fields, indexes
    }

    /**
     Get the current fields for this `ParseSchema`.
     - returns: The current fields.
     */
    public func getFields() -> [String: String] {
        var currentFields = [String: String]()
        fields?.forEach { (key, value) in
            currentFields[key] = value.description
        }
        return currentFields
    }

    /**
     Get the current indexes for this `ParseSchema`.
     - returns: The current indexes.
     */
    public func getIndexes() -> [String: String] {
        var currentIndexes = [String: String]()
        indexes?.forEach { (key, value) in
            currentIndexes[key] = value.description
        }
        return currentIndexes
    }
}

// MARK: Default Implementations
public extension ParseSchema {
    static var className: String {
        SchemaObject.className
    }

    /// Create an empty instance of `ParseSchema` type.
    init() {
        self.init(className: SchemaObject.className)
    }

    /**
     Create an empty instance of ParseSchema type with a specific CLP.
     - parameter classLevelPermissions: The CLP access for this `ParseSchema`.
    */
    init(classLevelPermissions: ParseCLP) {
        self.init(className: SchemaObject.className)
        self.classLevelPermissions = classLevelPermissions
    }

    /**
     Add an index to create/update a `ParseSchema`.
     
     - parameter name: Name of the index that will be created/updated in the schema on Parse Server.
     - parameter field: The **field** to apply the `ParseIndex` to.
     - parameter index: The **index** to create.
     - returns: A mutated instance of `ParseSchema` for easy chaining.
    */
    func addIndex(_ name: String,
                  field: String,
                  index: Encodable) -> Self {
        var mutableSchema = self
        mutableSchema.pendingIndexes[name] = [field: AnyCodable(index)]
        return mutableSchema
    }

    /**
     Add a Field to create/update a `ParseSchema`.
     
     - parameter name: Name of the field that will be created/updated in the schema on Parse Server.
     - parameter type: The `ParseFieldType` of the field that will be created/updated in the schema on Parse Server.
     - parameter target: The  target `ParseObject` of the field that will be created/updated in
     the schema on Parse Server.
     - parameter options: The `ParseFieldOptions` of the field that will be created/updated in
     the schema on Parse Server.
     - returns: A mutated instance of `ParseSchema` for easy chaining.
     - throws: An error of type `ParseError`.
     - warning: The use of `options` requires Parse Server 3.7.0+.
    */
    func addField<T, V>(_ name: String,
                        type: ParseFieldType,
                        target: T,
                        options: ParseFieldOptions<V>) throws -> Self where T: ParseObject {
        switch type {
        case .pointer:
            return try addPointer(name, target: target, options: options)
        case .relation:
            return try addRelation(name, target: target)
        default:
            return addField(name, type: type, options: options)
        }
    }

    /**
     Add a Field to create/update a `ParseSchema`.
     
     - parameter name: Name of the field that will be created/updated in the schema on Parse Server.
     - parameter type: The `ParseFieldType` of the field that will be created/updated in the schema on Parse Server.
     - parameter options: The `ParseFieldOptions` of the field that will be created/updated in
     the schema on Parse Server.
     - returns: A mutated instance of `ParseSchema` for easy chaining.
     - warning: The use of `options` requires Parse Server 3.7.0+.
    */
    func addField<V>(_ name: String,
                     type: ParseFieldType,
                     options: ParseFieldOptions<V>) -> Self {
        var mutableSchema = self
        let field = ParseField(type: type, options: options)
        if mutableSchema.fields != nil {
            mutableSchema.fields?[name] = field
        } else {
            mutableSchema.fields = [name: field]
        }

        return mutableSchema
    }

    /**
     Add a Pointer field to create/update a `ParseSchema`.
     
     - parameter name: Name of the field that will be created/updated in the schema on Parse Server.
     - parameter target: The  target `ParseObject` of the field that will be created/updated in
     the schema on Parse Server.
     Defaults to **nil**.
     - parameter options: The `ParseFieldOptions` of the field that will be created/updated in
     the schema on Parse Server.
     - returns: A mutated instance of `ParseSchema` for easy chaining.
     - throws: An error of type `ParseError`.
     - warning: The use of `options` requires Parse Server 3.7.0+.
    */
    func addPointer<T, V>(_ name: String,
                          target: T?,
                          options: ParseFieldOptions<V>) throws -> Self where T: ParseObject {
        guard let target = target else {
            throw ParseError(code: .unknownError, message: "Target must not be nil")
        }

        let field = ParseField(type: .pointer, target: target, options: options)
        var mutableSchema = self
        if mutableSchema.fields != nil {
            mutableSchema.fields?[name] = field
        } else {
            mutableSchema.fields = [name: field]
        }

        return mutableSchema
    }

    /**
     Add a Relation field to create/update a `ParseSchema`.
     
     - parameter name: Name of the field that will be created/updated in the schema on Parse Server.
     - parameter target: The  target `ParseObject` of the field that will be created/updated in
     the schema on Parse Server.
     Defaults to **nil**.
     - returns: A mutated instance of `ParseSchema` for easy chaining.
     - throws: An error of type `ParseError`.
    */
    func addRelation<T>(_ name: String,
                        target: T?) throws -> Self where T: ParseObject {
        guard let target = target else {
            throw ParseError(code: .unknownError, message: "Target must not be nil")
        }

        let field = ParseField(type: .relation, target: target)
        var mutableSchema = self
        if mutableSchema.fields != nil {
            mutableSchema.fields?[name] = field
        } else {
            mutableSchema.fields = [name: field]
        }

        return mutableSchema
    }

    /**
     Delete a field in the `ParseSchema`.
     
     - parameter name: Name of the field that will be deleted in the schema on Parse Server.
     - returns: A mutated instance of `ParseSchema` for easy chaining.
    */
    func deleteField(_ name: String) -> Self {
        let field = ParseField(operation: .delete)
        var mutableSchema = self
        if mutableSchema.fields != nil {
            mutableSchema.fields?[name] = field
        } else {
            mutableSchema.fields = [name: field]
        }

        return mutableSchema
    }

    /**
     Delete an index in the `ParseSchema`.
     
     - parameter name: Name of the index that will be deleted in the schema on Parse Server.
     - returns: A mutated instance of `ParseSchema` for easy chaining.
    */
    func deleteIndex(_ name: String, field: String) -> Self {
        let index = AnyCodable(Delete())
        var mutableSchema = self
        mutableSchema.pendingIndexes[name] = [field: index]
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
     Fetches the `ParseSchema` *asynchronously* from the server and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    public func fetch(options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<Self, ParseError>) -> Void) {
        var options = options
        options.insert(.useMasterKey)
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
     Creates the `ParseSchema` *asynchronously* on the server and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    public func create(options: API.Options = [],
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Self, ParseError>) -> Void) {
        var options = options
        options.insert(.useMasterKey)
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
     Updates the `ParseSchema` *asynchronously* on the server and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    public func update(options: API.Options = [],
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Self, ParseError>) -> Void) {
        var mutableSchema = self
        if !mutableSchema.pendingIndexes.isEmpty {
            mutableSchema.indexes = pendingIndexes
        } else {
            mutableSchema.indexes = nil
        }
        var options = options
        options.insert(.useMasterKey)
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        do {
            try mutableSchema.updateCommand()
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
     Deletes all objects in the `ParseSchema` *asynchronously* from the server and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - warning: This will delete all objects for this `ParseSchema` and cannot be reversed.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    public func purge(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Void, ParseError>) -> Void
    ) {
        var options = options
        options.insert(.useMasterKey)
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
         do {
            try purgeCommand().executeAsync(options: options,
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
     Deletes the `ParseSchema` *asynchronously* from the server and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - warning: This can only be used on a `ParseSchema` without objects. If the `ParseSchema`
     currently contains objects, run `purge()` first.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    public func delete(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Void, ParseError>) -> Void
    ) {
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

// MARK: CustomDebugStringConvertible
extension ParseSchema: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
            return "ParseSchema ()"
        }
        return "ParseSchema (\(descriptionString))"
    }
}

// MARK: CustomStringConvertible
extension ParseSchema: CustomStringConvertible {
    public var description: String {
        debugDescription
    }
}
