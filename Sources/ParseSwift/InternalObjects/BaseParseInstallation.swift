//
//  BaseParseInstallation.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/7/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

internal struct BaseParseInstallation: ParseInstallation {
    var deviceType: String?
    var installationId: String?
    var deviceToken: String?
    var badge: Int?
    var timeZone: String?
    var channels: [String]?
    var appName: String?
    var appIdentifier: String?
    var appVersion: String?
    var parseVersion: String?
    var localeIdentifier: String?
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    static func createNewInstallationIfNeeded() {
        guard let installationId = Self.currentContainer.installationId,
              Self.currentContainer.currentInstallation?.installationId == installationId else {
            try? ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
            #if !os(Linux) && !os(Android) && !os(Windows)
            try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
            #endif
            _ = Self.currentContainer
            return
        }
    }
}
