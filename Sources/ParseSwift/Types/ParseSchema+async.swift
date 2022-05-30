//
//  ParseSchema+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension ParseSchema {
    /**
     Fetches the `ParseSchema` *aynchronously* from the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the fetched `ParseSchema`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func fetch(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.fetch(options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Creates the `ParseSchema` *aynchronously* on the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the fetched `ParseSchema`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func create(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.create(options: options,
                        completion: continuation.resume)
        }
    }

    /**
     Updates the `ParseSchema` *aynchronously* on the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the fetched `ParseSchema`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func update(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.update(options: options,
                        completion: continuation.resume)
        }
    }

    /**
     Deletes all objects in the `ParseSchema` *aynchronously* from the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the fetched `ParseSchema`.
     - throws: An error of type `ParseError`.
     - warning: This will delete all objects for this `ParseSchema` and cannot be reversed.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func purge(options: API.Options = []) async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            self.purge(options: options,
                        completion: continuation.resume)
        }
        if case let .failure(error) = result {
            throw error
        }
    }

    /**
     Deletes the `ParseSchema` *aynchronously*  from the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the fetched `ParseSchema`.
     - throws: An error of type `ParseError`.
     - warning: This can only be used on a `ParseSchema` without objects. If the `ParseSchema`
     currently contains objects, run `purge()` first.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func delete(options: API.Options = []) async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            self.delete(options: options,
                        completion: continuation.resume)
        }
        if case let .failure(error) = result {
            throw error
        }
    }
}

#endif
