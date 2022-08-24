//
//  ParseKeychainAccessGroup.swift
//  ParseSwift
//
//  Created by Corey Baker on 8/23/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows)
import Foundation

struct ParseKeychainAccessGroup: ParseTypeable, Hashable {

    var accessGroup: String?
    var isSyncingKeychainAcrossDevices = false

    static var current: Self? {
        get {
            guard let versionInMemory: Self =
                try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentAccessGroup) else {
                    guard let versionFromKeyChain: Self =
                        try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentAccessGroup)
                         else {
                        return nil
                    }
                    return versionFromKeyChain
            }
            return versionInMemory
        }
        set {
            try? ParseStorage.shared.set(newValue, for: ParseStorage.Keys.currentAccessGroup)
            try? KeychainStore.shared.set(newValue, for: ParseStorage.Keys.currentAccessGroup)
            if let updatedKeychainAccessGroup = newValue {
                ParseSwift.configuration.keychainAccessGroup = updatedKeychainAccessGroup
            } else {
                ParseSwift.configuration.keychainAccessGroup = Self()
            }
        }
    }

    static func deleteCurrentContainerFromKeychain() {
        try? ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentAccessGroup)
        #if !os(Linux) && !os(Android) && !os(Windows)
        try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentAccessGroup)
        ParseSwift.configuration.keychainAccessGroup = Self()
        #endif
    }
}
#endif
