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
        let parseCacheDirectory = "ParseCache"
        #if os(macOS) || os(Linux) || os(Android)
        let diskURL = cacheURL.appendingPathComponent(parseCacheDirectory, isDirectory: true)
        return URLCache(memoryCapacity: ParseSwift.configuration.cacheMemoryCapacity,
                     diskCapacity: ParseSwift.configuration.cacheDiskCapacity,
                     diskPath: diskURL.absoluteString)
        #else
        return URLCache(memoryCapacity: ParseSwift.configuration.cacheMemoryCapacity,
                     diskCapacity: ParseSwift.configuration.cacheDiskCapacity,
                     diskPath: parseCacheDirectory)
        #endif
    }()
}
