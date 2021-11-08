//
//  ParseFile+async.swift
//  ParseFile+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension ParseFile {

    // MARK: Async/Await
    /**
     Fetches a file with given url *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
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
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it's progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
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
     A name will be assigned to it by the server. If the file hasn't been downloaded, it will automatically
     be downloaded before saved.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
    */
    func save(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.save(options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Creates a file with given data *asynchronously* and executes the given callback block.
     A name will be assigned to it by the server. If the file hasn't been downloaded, it will automatically
     be downloaded before saved.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it's progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - returns: A ParsFile.
     - throws: `ParseError`.
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
     Deletes the file from the Parse Server. Publishes when complete.
     - requires: `.useMasterKey` has to be available.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: `ParseError`.
     */
    func delete(options: API.Options = []) async throws {
        _ = try await withCheckedThrowingContinuation { continuation in
            self.delete(options: options, completion: continuation.resume)
        }
    }
}

#endif
