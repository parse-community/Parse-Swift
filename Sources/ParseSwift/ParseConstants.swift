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
    static let version = "4.14.2"
    static let fileManagementDirectory = "parse/"
    static let fileManagementPrivateDocumentsDirectory = "Private Documents/"
    static let fileManagementLibraryDirectory = "Library/"
    static let fileDownloadsDirectory = "Downloads"
    static let bundlePrefix = "com.parse.ParseSwift"
    static let batchLimit = 50
    static let includeAllKey = "*"
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

/**
 The types of Parse Hook Triggers available.
 */
public enum ParseHookTriggerType: String, Codable {
    /// Occurs before login of a `ParseUser`.
    case beforeLogin
    /// Occurs after login of a `ParseUser`.
    case afterLogin
    /// Occurs after logout of a `ParseUser`.
    case afterLogout
    /// Occurs before saving a `ParseObject` or `ParseFile`.
    case beforeSave
    /// Occurs after saving a `ParseObject` or `ParseFile`.
    case afterSave
    /// Occurs before deleting a `ParseObject` or `ParseFile`.
    case beforeDelete
    /// Occurs after deleting a `ParseObject` or `ParseFile`.
    case afterDelete
    /// Occurs before finding a `ParseObject`.
    case beforeFind
    /// Occurs after finding a `ParseObject`.
    case afterFind
    /// Occurs before a `ParseLiveQuery` connection is made.
    case beforeConnect
    /// Occurs before a `ParseLiveQuery` subscription is made.
    case beforeSubscribe
    /// Occurs after a `ParseLiveQuery` event.
    case afterEvent
}
