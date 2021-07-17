//
//  URLCache+extensions.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/17/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLCache {
    static let parse: URLCache = {
        guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return URLCache(memoryCapacity: ParseSwift.configuration.cacheMemoryCapacity,
                            diskCapacity: ParseSwift.configuration.cacheDiskCapacity,
                            diskPath: "/")
        }
        let diskURL = cacheURL.appendingPathComponent("ParseCache/")
        return .init(memoryCapacity: ParseSwift.configuration.cacheMemoryCapacity,
                     diskCapacity: ParseSwift.configuration.cacheDiskCapacity,
                     diskPath: diskURL.absoluteString)
    }()
}
