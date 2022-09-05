//
//  ParseVersion.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/1/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/// `ParseVersion` is used to determine the version of the SDK. The current
/// version of the SDK is persisted to the Keychain.
public struct ParseVersion: ParseTypeable, Comparable {

    var string: String

    /// Current version of the SDK.
    public internal(set) static var current: String? {
        get {
            guard let versionInMemory: String =
                try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentVersion) else {
                #if !os(Linux) && !os(Android) && !os(Windows)
                    guard let versionFromKeyChain: String =
                        try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentVersion)
                         else {
                        guard let versionFromKeyChain: String =
                            try? KeychainStore.old.get(valueFor: ParseStorage.Keys.currentVersion)
                             else {
                            return nil
                        }
                        try? KeychainStore.shared.set(versionFromKeyChain, for: ParseStorage.Keys.currentVersion)
                        return versionFromKeyChain
                    }
                    return versionFromKeyChain
                #else
                    return nil
                #endif
            }
            return versionInMemory
        }
        set {
            try? ParseStorage.shared.set(newValue, for: ParseStorage.Keys.currentVersion)
            #if !os(Linux) && !os(Android) && !os(Windows)
            try? KeychainStore.shared.set(newValue, for: ParseStorage.Keys.currentVersion)
            #endif
        }
    }

    init(_ string: String?) throws {
        guard let newString = string else {
            throw ParseError(code: .unknownError,
                             message: "Cannot initialize with nil value.")
        }
        self.string = newString
    }

    static func deleteCurrentContainerFromKeychain() {
        try? ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentVersion)
        #if !os(Linux) && !os(Android) && !os(Windows)
        try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentVersion)
        #endif
    }
}

public extension ParseVersion {

    static func > (left: ParseVersion, right: ParseVersion) -> Bool {
        let left = left.string.split(separator: ".").compactMap { Int($0) }
        assert(left.count == 3, "Left version must have 3 values, \"1.1.1\".")
        let right = right.string.split(separator: ".").compactMap { Int($0) }
        assert(right.count == 3, "Right version must have 3 values, \"1.1.1\".")
        if left[0] > right[0] {
            return true
        } else if left[0] < right[0] {
            return false
        } else if left[1] > right[1] {
            return true
        } else if left[1] < right[1] {
            return false
        } else if left[2] > right[2] {
            return true
        } else {
            return false
        }
    }

    static func >= (left: ParseVersion, right: ParseVersion) -> Bool {
        if left == right || left > right {
            return true
        } else {
            return false
        }
    }

    static func < (left: ParseVersion, right: ParseVersion) -> Bool {
        let left = left.string.split(separator: ".").compactMap { Int($0) }
        assert(left.count == 3, "Left version must have 3 values, \"1.1.1\".")
        let right = right.string.split(separator: ".").compactMap { Int($0) }
        assert(right.count == 3, "Right version must have 3 values, \"1.1.1\".")
        if left[0] < right[0] {
            return true
        } else if left[0] > right[0] {
            return false
        } else if left[1] < right[1] {
            return true
        } else if left[1] > right[1] {
            return false
        } else if left[2] < right[2] {
            return true
        } else {
            return false
        }
    }

    static func <= (left: ParseVersion, right: ParseVersion) -> Bool {
        if left == right || left < right {
            return true
        } else {
            return false
        }
    }

    static func == (left: ParseVersion, right: ParseVersion) -> Bool {
        left.string == right.string
    }
}
