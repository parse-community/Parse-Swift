//
//  URLCache.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/17/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

internal extension URLCache {
    static let parse: URLCache = {
        guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return URLCache(memoryCapacity: Parse.configuration.cacheMemoryCapacity,
                            diskCapacity: Parse.configuration.cacheDiskCapacity,
                            diskPath: nil)
        }
        let parseCacheDirectory = "ParseCache"
        let diskURL = cacheURL.appendingPathComponent(parseCacheDirectory, isDirectory: true)
        #if !os(Linux) && !os(Android) && !os(Windows)
        return URLCache(memoryCapacity: Parse.configuration.cacheMemoryCapacity,
                        diskCapacity: Parse.configuration.cacheDiskCapacity,
                        directory: diskURL)
        #else
        return URLCache(memoryCapacity: Parse.configuration.cacheMemoryCapacity,
                        diskCapacity: Parse.configuration.cacheDiskCapacity,
                        diskPath: diskURL.absoluteString)
        #endif
    }()
}
