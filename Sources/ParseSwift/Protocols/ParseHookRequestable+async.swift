//
//  ParseHookRequestable+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

#if compiler(>=5.5.2) && canImport(_Concurrency)
public extension ParseHookRequestable {
    /**

     */
    func hydrateUser() async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.hydrateUser(completion: continuation.resume)
        }
    }
}
#endif
