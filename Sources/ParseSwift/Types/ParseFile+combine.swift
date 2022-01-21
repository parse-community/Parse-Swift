//
//  ParseFile+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Combine

public extension ParseFile {

    // MARK: Combine
    /**
     Fetches a file with given url *synchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetchPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.fetch(options: options,
                       completion: promise)
        }
    }

    /**
     Fetches a file with given url *synchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it's progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetchPublisher(options: API.Options = [],
                        progress: @escaping ((URLSessionDownloadTask,
                                              Int64, Int64, Int64) -> Void)) -> Future<Self, ParseError> {
        Future { promise in
            self.fetch(options: options,
                       progress: progress,
                       completion: promise)
        }
    }

    /**
     Creates a file with given data *asynchronously* and executes the given callback block.
     Publishes when complete.
     A name will be assigned to it by the server. If the file hasn't been downloaded, it will automatically
     be downloaded before saved.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func savePublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.save(options: options,
                      completion: promise)
        }
    }

    /**
     Creates a file with given data *asynchronously* and executes the given callback block.
     A name will be assigned to it by the server. If the file hasn't been downloaded, it will automatically
     be downloaded before saved. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it's progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func savePublisher(options: API.Options = [],
                       progress: ((URLSessionTask, Int64, Int64, Int64) -> Void)? = nil) -> Future<Self, ParseError> {
        Future { promise in
            self.save(options: options,
                      progress: progress,
                      completion: promise)
        }
    }

    /**
     Deletes the file from the Parse Server. Publishes when complete.
     - requires: `.useMasterKey` has to be available.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func deletePublisher(options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            self.delete(options: options, completion: promise)
        }
    }
}

#endif
