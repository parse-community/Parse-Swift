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

    init() {
        //Force installation in keychain to be created if it hasn't already
        Self.current = self
    }
}
