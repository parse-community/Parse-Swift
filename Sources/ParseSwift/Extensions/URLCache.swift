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
            return URLCache(memoryCapacity: ParseSwift.configuration.cacheMemoryCapacity,
                            diskCapacity: ParseSwift.configuration.cacheDiskCapacity,
                            diskPath: "/")
        }
        let parseCacheDirectory = "ParseCache"
        let diskURL = cacheURL.appendingPathComponent(parseCacheDirectory, isDirectory: true)
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            #if !os(Linux) && !os(Android)
            return URLCache(memoryCapacity: ParseSwift.configuration.cacheMemoryCapacity,
                         diskCapacity: ParseSwift.configuration.cacheDiskCapacity,
                         directory: diskURL)
            #else
            return URLCache(memoryCapacity: ParseSwift.configuration.cacheMemoryCapacity,
                         diskCapacity: ParseSwift.configuration.cacheDiskCapacity,
                         diskPath: diskURL.absoluteString)
            #endif
        } else {
            #if os(macOS)
            return URLCache(memoryCapacity: ParseSwift.configuration.cacheMemoryCapacity,
                         diskCapacity: ParseSwift.configuration.cacheDiskCapacity,
                         diskPath: diskURL.absoluteString)
            #else
            return URLCache(memoryCapacity: ParseSwift.configuration.cacheMemoryCapacity,
                         diskCapacity: ParseSwift.configuration.cacheDiskCapacity,
                         diskPath: parseCacheDirectory)
            #endif
        }
    }()
}
