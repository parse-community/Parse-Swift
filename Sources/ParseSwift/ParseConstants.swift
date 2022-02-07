//
//  ParseConstants.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/7/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

enum ParseConstants {
    static let sdk = "swift"
    static let version = "4.1.0"
    static let fileManagementDirectory = "parse/"
    static let fileManagementPrivateDocumentsDirectory = "Private Documents/"
    static let fileManagementLibraryDirectory = "Library/"
    static let fileDownloadsDirectory = "Downloads"
    static let bundlePrefix = "com.parse.ParseSwift"
    static let batchLimit = 50
    #if os(iOS)
    static let deviceType = "ios"
    #elseif os(macOS)
    static let deviceType = "osx"
    #elseif os(tvOS)
    static let deviceType = "tvos"
    #elseif os(watchOS)
    static let deviceType = "applewatch"
    #elseif os(Linux)
    static let deviceType = "linux"
    #elseif os(Android)
    static let deviceType = "android"
    #elseif os(Windows)
    static let deviceType = "windows"
    #endif
}

enum Method: String {
    case save, create, replace, update
}
