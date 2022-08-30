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
            guard let updatedKeychainAccessGroup = newValue else {
                let defaultKeychainAccessGroup = Self()
                try? ParseStorage.shared.set(defaultKeychainAccessGroup, for: ParseStorage.Keys.currentAccessGroup)
                try? KeychainStore.shared.set(defaultKeychainAccessGroup, for: ParseStorage.Keys.currentAccessGroup)
                Parse.configuration.keychainAccessGroup = defaultKeychainAccessGroup
                return
            }
            try? ParseStorage.shared.set(updatedKeychainAccessGroup, for: ParseStorage.Keys.currentAccessGroup)
            try? KeychainStore.shared.set(updatedKeychainAccessGroup, for: ParseStorage.Keys.currentAccessGroup)
            Parse.configuration.keychainAccessGroup = updatedKeychainAccessGroup
        }
    }

    static func deleteCurrentContainerFromKeychain() {
        try? ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentAccessGroup)
        try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentAccessGroup)
        Parse.configuration.keychainAccessGroup = Self()
    }
}
#endif
