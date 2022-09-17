//
//  ParseFile+async.swift
//  ParseFile+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension ParseFile {

    // MARK: Async/Await
    /**
     Fetches a file with given url *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A fetched `ParseFile`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetch(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.fetch(options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Fetches a file with given url *asynchronously*.
     Fetches a file with given url *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it is progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - returns: A fetched `ParseFile`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetch(options: API.Options = [],
               progress: @escaping ((URLSessionDownloadTask,
                                     Int64, Int64, Int64) -> Void)) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.fetch(options: options,
                       progress: progress,
                       completion: continuation.resume)
        }
    }

    /**
     Creates a file with given data *asynchronously* and executes the given callback block.
     A name will be assigned to it by the server. If the file has not been downloaded, it will automatically
     be downloaded before saved.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A saved `ParseFile`.
     - throws: An error of type `ParseError`.
    */
    func save(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.save(options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Creates a file with given data *asynchronously* and executes the given callback block.
     A name will be assigned to it by the server. If the file has not been downloaded, it will automatically
     be downloaded before saved.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it is progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - returns: A ParsFile.
     - throws: An error of type `ParseError`.
     */
    func save(options: API.Options = [],
              progress: ((URLSessionTask,
                          Int64,
                          Int64,
                          Int64) -> Void)? = nil) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.save(options: options,
                      progress: progress,
                      completion: continuation.resume)
        }
    }

    /**
     Deletes the file from the Parse Server.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     */
    func delete(options: API.Options = []) async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            self.delete(options: options, completion: continuation.resume)
        }
        if case let .failure(error) = result {
            throw error
        }
    }
}

#endif
