//
//  ParseObject.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation

/**
 Objects that conform to the `ParseObject` protocol have a local representation of data persisted to the Parse cloud.
 This is the main protocol that is used to interact with objects in your app.

 If you plan to use custom encoding/decoding, be sure to add `objectId`, `createdAt`, `updatedAt`, and
 `ACL` to your `ParseObject` `CodingKeys`.
 
 - note: `ParseObject`s can be "value types" (structs) or reference types "classes". If you are using value types
 there isn't much else you need to do but to conform to ParseObject. If you are using reference types, see the warning.
 - warning: If you plan to use "reference types" (classes), you will need to implement your own `==` method to conform
 to `Equatable` along with with the `hash` method to conform to `Hashable`. It is important to note that for unsaved
`ParseObject`s, you won't be able to rely on `objectId` for `Equatable` and `Hashable` as your unsaved objects
 won't have this value yet and is nil. A possible way to address this is by creating a `UUID` for your objects locally
 and relying on that for `Equatable` and `Hashable`, otherwise it's possible you will get "circular dependency errors"
 depending on your implementation.
*/
public protocol ParseObject: Objectable,
                             Fetchable,
                             Savable,
                             Deletable,
                             Hashable,
                             CustomDebugStringConvertible {}

// MARK: Default Implementations
extension ParseObject {

    /**
     Determines if two objects have the same objectId.

     - parameter as: Object to compare.

     - returns: Returns a `true` if the other object has the same `objectId` or `false` if unsuccessful.
    */
    public func hasSameObjectId<T: ParseObject>(as other: T) -> Bool {
        return other.className == className && other.objectId == objectId && objectId != nil
    }

    /**
       Gets a Pointer referencing this Object.
       - returns: Pointer<Self>
    */
    public func toPointer() throws -> Pointer<Self> {
        return try Pointer(self)
    }
}

// MARK: Batch Support
public extension Sequence where Element: ParseObject {

    /**
     Saves a collection of objects *synchronously* all at once and throws an error if necessary.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a save was successful or a `ParseError` if it failed.
     - throws: `ParseError`
    */
    func saveAll(batchLimit limit: Int? = nil, // swiftlint:disable:this function_body_length
                 options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        var childObjects = [String: PointerType]()
        var childFiles = [UUID: ParseFile]()
        var error: ParseError?

        let objects = map { $0 }
        for object in objects {
            let group = DispatchGroup()
            group.enter()
            object.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, parseError) -> Void in
                //If an error occurs, everything should be skipped
                if parseError != nil {
                    error = parseError
                }
                savedChildObjects.forEach {(key, value) in
                    if error != nil {
                        return
                    }
                    if childObjects[key] == nil {
                        childObjects[key] = value
                    } else {
                        error = ParseError(code: .unknownError, message: "circular dependency")
                        return
                    }
                }
                savedChildFiles.forEach {(key, value) in
                    if error != nil {
                        return
                    }
                    if childFiles[key] == nil {
                        childFiles[key] = value
                    } else {
                        error = ParseError(code: .unknownError, message: "circular dependency")
                        return
                    }
                }
                group.leave()
            }
            group.wait()
            if let error = error {
                throw error
            }
        }

        var returnBatch = [(Result<Self.Element, ParseError>)]()
        let commands = map { $0.saveCommand() }
        let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
        try batches.forEach {
            let currentBatch = try API.Command<Self.Element, Self.Element>
                .batch(commands: $0)
                .execute(options: options,
                         callbackQueue: .main,
                         childObjects: childObjects,
                         childFiles: childFiles)
            returnBatch.append(contentsOf: currentBatch)
        }
        return returnBatch
    }

    /**
     Saves a collection of objects all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
    */
    func saveAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let queue = DispatchQueue(label: "com.parse.saveAll", qos: .default,
                                  attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        queue.sync {

            let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
            var childObjects = [String: PointerType]()
            var childFiles = [UUID: ParseFile]()
            var error: ParseError?

            let objects = map { $0 }
            for object in objects {
                let group = DispatchGroup()
                group.enter()
                object.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, parseError) -> Void in
                    //If an error occurs, everything should be skipped
                    if parseError != nil {
                        error = parseError
                    }
                    savedChildObjects.forEach {(key, value) in
                        if error != nil {
                            return
                        }
                        if childObjects[key] == nil {
                            childObjects[key] = value
                        } else {
                            error = ParseError(code: .unknownError, message: "circular dependency")
                            return
                        }
                    }
                    savedChildFiles.forEach {(key, value) in
                        if error != nil {
                            return
                        }
                        if childFiles[key] == nil {
                            childFiles[key] = value
                        } else {
                            error = ParseError(code: .unknownError, message: "circular dependency")
                            return
                        }
                    }
                    group.leave()
                }
                group.wait()
                if let error = error {
                    callbackQueue.async {
                        completion(.failure(error))
                    }
                    return
                }
            }

            var returnBatch = [(Result<Self.Element, ParseError>)]()
            let commands = map { $0.saveCommand() }
            let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
            var completed = 0
            for batch in batches {
                API.Command<Self.Element, Self.Element>
                        .batch(commands: batch)
                        .executeAsync(options: options,
                                      callbackQueue: callbackQueue,
                                      childObjects: childObjects,
                                      childFiles: childFiles) { results in
                    switch results {

                    case .success(let saved):
                        returnBatch.append(contentsOf: saved)
                        if completed == (batches.count - 1) {
                            callbackQueue.async {
                                completion(.success(returnBatch))
                            }
                        }
                        completed += 1
                    case .failure(let error):
                        callbackQueue.async {
                            completion(.failure(error))
                        }
                        return
                    }
                }
            }
        }
    }

    /**
     Fetches a collection of objects *synchronously* all at once and throws an error if necessary.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a fetch was successful or a `ParseError` if it failed.
     - throws: `ParseError`
     - warning: The order in which objects are returned are not guarenteed. You shouldn't expect results in
     any particular order.
    */
    func fetchAll(includeKeys: [String]? = nil,
                  options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {

        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(compactMap { $0.objectId })
            var query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
                .limit(uniqueObjectIds.count)
            if let include = includeKeys {
                query = query.include(include)
            }
            let fetchedObjects = try query.find(options: options)
            var fetchedObjectsToReturn = [(Result<Self.Element, ParseError>)]()

            uniqueObjectIds.forEach {
                let uniqueObjectId = $0
                if let fetchedObject = fetchedObjects.first(where: {$0.objectId == uniqueObjectId}) {
                    fetchedObjectsToReturn.append(.success(fetchedObject))
                } else {
                    fetchedObjectsToReturn.append(.failure(ParseError(code: .objectNotFound,
                                                                      // swiftlint:disable:next line_length
                                                                      message: "objectId \"\(uniqueObjectId)\" was not found in className \"\(Self.Element.className)\"")))
                }
            }
            return fetchedObjectsToReturn
        } else {
            throw ParseError(code: .unknownError, message: "all items to fetch must be of the same class")
        }
    }

    /**
     Fetches a collection of objects all at once *asynchronously* and executes the completion block when done.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - warning: The order in which objects are returned are not guarenteed. You shouldn't expect results in
     any particular order.
    */
    func fetchAll(
        includeKeys: [String]? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(compactMap { $0.objectId })
            var query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
            if let include = includeKeys {
                query = query.include(include)
            }
            query.find(options: options, callbackQueue: callbackQueue) { result in
                switch result {

                case .success(let fetchedObjects):
                    var fetchedObjectsToReturn = [(Result<Self.Element, ParseError>)]()

                    uniqueObjectIds.forEach {
                        let uniqueObjectId = $0
                        if let fetchedObject = fetchedObjects.first(where: {$0.objectId == uniqueObjectId}) {
                            fetchedObjectsToReturn.append(.success(fetchedObject))
                        } else {
                            fetchedObjectsToReturn.append(.failure(ParseError(code: .objectNotFound,
                                                                              // swiftlint:disable:next line_length
                                                                              message: "objectId \"\(uniqueObjectId)\" was not found in className \"\(Self.Element.className)\"")))
                        }
                    }
                    callbackQueue.async {
                        completion(.success(fetchedObjectsToReturn))
                    }
                case .failure(let error):
                    callbackQueue.async {
                        completion(.failure(error))
                    }
                }
            }
        } else {
            callbackQueue.async {
                completion(.failure(ParseError(code: .unknownError,
                                               message: "all items to fetch must be of the same class")))
            }
        }
    }

    /**
     Deletes a collection of objects *synchronously* all at once and throws an error if necessary.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns `nil` if the delete successful or a `ParseError` if it failed.
        1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
        array of other Parse.Error objects. Each error object in this array
        has an "object" property that references the object that could not be
        deleted (for instance, because that object could not be found).
        2. A non-aggregate Parse.Error. This indicates a serious error that
        caused the delete operation to be aborted partway through (for
        instance, a connection failure in the middle of the delete).
     - throws: `ParseError`
    */
    func deleteAll(batchLimit limit: Int? = nil,
                   options: API.Options = []) throws -> [(Result<Void, ParseError>)] {
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        var returnBatch = [(Result<Void, ParseError>)]()
        let commands = try map { try $0.deleteCommand() }
        let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
        try batches.forEach {
            let currentBatch = try API.Command<Self.Element, (Result<Void, ParseError>)>
                .batch(commands: $0)
                .execute(options: options)
            returnBatch.append(contentsOf: currentBatch)
        }
        return returnBatch
    }

    /**
     Deletes a collection of objects all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[ParseError?], ParseError>)`.
     Each element in the array is `nil` if the delete successful or a `ParseError` if it failed.
     1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
     array of other Parse.Error objects. Each error object in this array
     has an "object" property that references the object that could not be
     deleted (for instance, because that object could not be found).
     2. A non-aggregate Parse.Error. This indicates a serious error that
     caused the delete operation to be aborted partway through (for
     instance, a connection failure in the middle of the delete).
    */
    func deleteAll(
        batchLimit limit: Int? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Void, ParseError>)], ParseError>) -> Void
    ) {
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        do {
            var returnBatch = [(Result<Void, ParseError>)]()
            let commands = try map({ try $0.deleteCommand() })
            let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
            var completed = 0
            for batch in batches {
                API.Command<Self.Element, ParseError?>
                        .batch(commands: batch)
                        .executeAsync(options: options) { results in
                    switch results {

                    case .success(let saved):
                        returnBatch.append(contentsOf: saved)
                        if completed == (batches.count - 1) {
                            callbackQueue.async {
                                completion(.success(returnBatch))
                            }
                        }
                        completed += 1
                    case .failure(let error):
                        callbackQueue.async {
                            completion(.failure(error))
                        }
                        return
                    }
                }
            }
        } catch {
            callbackQueue.async {
                guard let parseError = error as? ParseError else {
                    completion(.failure(ParseError(code: .unknownError,
                                                   message: error.localizedDescription)))
                    return
                }
                completion(.failure(parseError))
            }
        }
    }
}

// MARK: Batch Support
/*internal extension Sequence where Element: ParseType {

    /**
     Saves a collection of objects *synchronously* all at once and throws an error if necessary.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a save was successful or a `ParseError` if it failed.
     - throws: `ParseError`
    */
    func saveAll(options: API.Options = []) throws -> [(Result<PointerType, ParseError>)] {
        let commands = try map { try $0.saveCommand() }
        return try API.Command<Self.Element, PointerType>
                .batch(commands: commands)
                .execute(options: options)
    }
}*/

// MARK: CustomDebugStringConvertible
extension ParseObject {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "\(className) ()"
        }

        return "\(className) (\(descriptionString))"
    }
}

// MARK: Fetchable
extension ParseObject {

    /**
     Fetches the `ParseObject` *synchronously* with the current data from the server and sets an error if one occurs.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of `ParseError` type.
    */
    public func fetch(includeKeys: [String]? = nil,
                      options: API.Options = []) throws -> Self {
        try fetchCommand(include: includeKeys).execute(options: options,
                                   callbackQueue: .main)
    }

    /**
     Fetches the `ParseObject` *asynchronously* and executes the given callback block.
     - parameter includeKeys: The name(s) of the key(s) to include. Use `["*"]` to include
     all keys.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func fetch(
        includeKeys: [String]? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
         do {
            try fetchCommand(include: includeKeys)
                .executeAsync(options: options,
                              callbackQueue: callbackQueue) { result in
                callbackQueue.async {
                    completion(result)
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

    internal func fetchCommand(include: [String]?) throws -> API.Command<Self, Self> {
        try API.Command<Self, Self>.fetchCommand(self, include: include)
    }
}

// MARK: Operations
public extension ParseObject {
    var operation: ParseOperation<Self> {
        return ParseOperation(target: self)
    }
}

// MARK: Queryable
public extension ParseObject {

    static func query() -> Query<Self> {
        Query<Self>()
    }

    static func query(_ constraints: QueryConstraint...) -> Query<Self> {
        Query<Self>(constraints)
    }

    static func query(_ constraints: [QueryConstraint]) -> Query<Self> {
        Query<Self>(constraints)
    }
}

// MARK: Savable
extension ParseObject {

    /**
     Saves the `ParseObject` *synchronously* and throws an error if there's an issue.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.

     - returns: Returns saved `ParseObject`.
    */
    public func save(options: API.Options = []) throws -> Self {
        var childObjects: [String: PointerType]?
        var childFiles: [UUID: ParseFile]?
        var error: ParseError?
        let group = DispatchGroup()
        group.enter()
        self.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, parseError) in
            childObjects = savedChildObjects
            childFiles = savedChildFiles
            error = parseError
            group.leave()
        }
        group.wait()

        if let error = error {
            throw error
        }

        return try saveCommand()
            .execute(options: options,
                     callbackQueue: .main,
                     childObjects: childObjects,
                     childFiles: childFiles)
    }

    /**
     Saves the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func save(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        self.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, error) in
            guard let parseError = error else {
                self.saveCommand().executeAsync(options: options,
                                                callbackQueue: callbackQueue,
                                                childObjects: savedChildObjects,
                                                childFiles: savedChildFiles) { result in
                    callbackQueue.async {
                        completion(result)
                    }
                }
                return
            }
            callbackQueue.async {
                completion(.failure(parseError))
            }
        }
    }

    internal func saveCommand() -> API.Command<Self, Self> {
        return API.Command<Self, Self>.saveCommand(self)
    }

    // swiftlint:disable:next function_body_length
    internal func ensureDeepSave(options: API.Options = [],
                                 completion: @escaping ([String: PointerType],
                                                        [UUID: ParseFile], ParseError?) -> Void) {

        let queue = DispatchQueue(label: "com.parse.deepSave", qos: .default,
                                  attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)

        queue.sync {
            var objectsFinishedSaving = [String: PointerType]()
            var filesFinishedSaving = [UUID: ParseFile]()

            do {
                let object = try ParseCoding.parseEncoder()
                    .encode(self,
                            objectsSavedBeforeThisOne: nil,
                            filesSavedBeforeThisOne: nil)

                var waitingToBeSaved = object.unsavedChildren

                while waitingToBeSaved.count > 0 {
                    var savableObjects = [Encodable]()
                    var savableFiles = [ParseFile]()
                    var nextBatch = [ParseType]()
                    try waitingToBeSaved.forEach { parseType in

                        if let parseFile = parseType as? ParseFile {
                            //ParseFiles can be saved now
                            savableFiles.append(parseFile)
                        } else if let parseObject = parseType as? Objectable {
                            //This is a ParseObject
                            let waitingObjectInfo = try ParseCoding
                                .parseEncoder()
                                .encode(parseObject,
                                        collectChildren: true,
                                        objectsSavedBeforeThisOne: objectsFinishedSaving,
                                        filesSavedBeforeThisOne: filesFinishedSaving)

                            if waitingObjectInfo.unsavedChildren.count == 0 {
                                //If this ParseObject has no additional children, it can be saved now
                                savableObjects.append(parseObject)
                            } else {
                                //Else this ParseObject needs to wait until it's children are saved
                                nextBatch.append(parseObject)
                            }
                        }
                    }
                    waitingToBeSaved = nextBatch

                    if savableObjects.count == 0 && savableFiles.count == 0 {
                        completion(objectsFinishedSaving,
                                   filesFinishedSaving,
                                   ParseError(code: .unknownError,
                                              message: "Found a circular dependency in ParseObject."))
                        return
                    }

                    //Currently, batch isn't working for Encodable
                    /*if let parseTypes = savableObjects as? [ParseType] {
                        let savedChildObjects = try self.saveAll(options: options, objects: parseTypes)
                    }*/
                    try savableObjects.forEach {
                        let hash = try BaseObjectable.createHash($0)
                        if let parseType = $0 as? ParseType {
                            objectsFinishedSaving[hash] = try parseType.save(options: options)
                        }
                    }

                    try savableFiles.forEach {
                        let file = $0
                        filesFinishedSaving[file.localId] = try $0.save(options: options)
                    }
                }
                completion(objectsFinishedSaving, filesFinishedSaving, nil)
            } catch {
                guard let parseError = error as? ParseError else {
                    completion(objectsFinishedSaving, filesFinishedSaving,
                               ParseError(code: .unknownError,
                                          message: error.localizedDescription))
                    return
                }
                completion(objectsFinishedSaving, filesFinishedSaving, parseError)
            }
        }
    }
}

// MARK: Savable Encodable Version
internal extension ParseType {
    func save(options: API.Options = []) throws -> PointerType {
        try saveCommand()
            .execute(options: options,
                     callbackQueue: .main)
    }

    func saveCommand() throws -> API.Command<Self, PointerType> {
        try API.Command<Self, PointerType>.saveCommand(self)
    }
/*
    func saveAll<T: ParseType>(options: API.Options = [], objects: [T]) throws -> [(Result<PointerType, ParseError>)] {
        let commands = try objects.map { try API.Command<T, PointerType>.saveCommand($0) }
        return try API.Command<T, PointerType>
                .batch(commands: commands)
                .execute(options: options)
    }*/
}

// MARK: Deletable
extension ParseObject {
    /**
     Deletes the `ParseObject` *synchronously* with the current data from the server and sets an error if one occurs.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of `ParseError` type.
    */
    public func delete(options: API.Options = []) throws {
        _ = try deleteCommand().execute(options: options)
    }

    /**
     Deletes the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
    */
    public func delete(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Void, ParseError>) -> Void
    ) {
         do {
            try deleteCommand().executeAsync(options: options) { result in
                callbackQueue.async {
                    switch result {

                    case .success:
                        completion(.success(()))
                    case .failure(let error):
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

    internal func deleteCommand() throws -> API.NonParseBodyCommand<NoBody, NoBody> {
        try API.NonParseBodyCommand<NoBody, NoBody>.deleteCommand(self)
    }
}// swiftlint:disable:this file_length
