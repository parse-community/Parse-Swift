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
     Calls a Cloud Code function *asynchronously* and returns a result of it's execution.
     Publishes when complete.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func hydrateUserPublisher() -> Future<Self, ParseError> {
        Future { promise in
            self.hydrateUser(completion: promise)
        }
    }
}
#endif
