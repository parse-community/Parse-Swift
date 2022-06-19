//
//  ParseHookRequestable+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseHookRequestable {

    // MARK: Combine

    /**
     Fetches the complete `ParseUser`. Publishes when complete.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func hydrateUserPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.hydrateUser(options: options, completion: promise)
        }
    }
}
#endif
