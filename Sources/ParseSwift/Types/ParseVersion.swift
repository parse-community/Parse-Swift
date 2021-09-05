//
//  ParseVersion.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/1/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/// `ParseVersion` is used to determine the version of the SDK.
public struct ParseVersion: Encodable {

    var string: String

    /// Current version of the SDK.
    public internal(set) static var current: String? {
        get {
            guard let versionInMemory: String =
                try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentVersion) else {
                #if !os(Linux) && !os(Android)
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
            #if !os(Linux) && !os(Android)
            try? KeychainStore.shared.set(newValue, for: ParseStorage.Keys.currentVersion)
            #endif
        }
    }

    init(_ string: String?) throws {
        guard let newString = string else {
            throw ParseError(code: .unknownError,
                             message: "Can't initialize with nil value.")
        }
        self.string = newString
    }
}

// MARK: CustomDebugStringConvertible
extension ParseVersion: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
            return "ParseVersion ()"
        }
        return "ParseVersion (\(descriptionString))"
    }
}

// MARK: CustomStringConvertible
extension ParseVersion: CustomStringConvertible {
    public var description: String {
        debugDescription
    }
}

func > (left: ParseVersion, right: ParseVersion) -> Bool {
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

func >= (left: ParseVersion, right: ParseVersion) -> Bool {
    if left == right || left > right {
        return true
    } else {
        return false
    }
}

func < (left: ParseVersion, right: ParseVersion) -> Bool {
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

func <= (left: ParseVersion, right: ParseVersion) -> Bool {
    if left == right || left < right {
        return true
    } else {
        return false
    }
}

func == (left: ParseVersion, right: ParseVersion) -> Bool {
    left.string == right.string
}
