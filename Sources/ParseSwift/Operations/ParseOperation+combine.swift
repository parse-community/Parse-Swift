//
//  ParseOperation+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseOperation {

    // MARK: Savable - Combine

    /**
     Saves the operations on the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func savePublisher(options: API.Options = []) -> Future<T, ParseError> {
        Future { promise in
            self.save(options: options,
                      completion: promise)
        }
    }
}

#endif
