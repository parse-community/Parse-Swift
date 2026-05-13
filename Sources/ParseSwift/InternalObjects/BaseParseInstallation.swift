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

#if !os(Linux) && !os(Android) && !os(Windows)
extension BaseParseInstallation {
    private static let objectiveCCurrentInstallationKey = "currentInstallation"
    private static let objectiveCInstallationIdKey = "installationId"
    private static let objectiveCParseDirectoryName = "Parse"

    private struct ObjectiveCInstallationFile: Decodable {
        let classname: String?
        let className: String?
        let objectId: String?
        let createdAt: Date?
        let updatedAt: Date?
        var installation: BaseParseInstallation?

        enum CodingKeys: String, CodingKey {
            case classname
            case className
            case objectId = "id"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case installation = "data"
        }

        var parseInstallation: BaseParseInstallation? {
            guard (classname ?? className) == BaseParseInstallation.className,
                  var installation = installation else {
                return nil
            }
            installation.objectId = installation.objectId ?? objectId
            installation.createdAt = installation.createdAt ?? createdAt
            installation.updatedAt = installation.updatedAt ?? updatedAt
            return installation
        }
    }

    static func migrateFromObjectiveCSDKIfNeeded() {
        guard let objcParseKeychain = KeychainStore.objectiveC else {
            return
        }

        let objcInstallation = objectiveCCurrentInstallation(from: objcParseKeychain)
            ?? objectiveCCurrentInstallationFromDisk()
        let objcInstallationId = objcInstallation?.installationId
            ?? objectiveCInstallationId(from: objcParseKeychain)

        guard let installationId = objcInstallationId else {
            return
        }

        var updatedInstallation = objcInstallation ?? current ?? BaseParseInstallation()
        updatedInstallation.installationId = installationId

        guard current?.installationId != installationId ||
              current?.objectId != updatedInstallation.objectId else {
            return
        }

        if objcInstallation == nil {
            updatedInstallation.updateAutomaticInfo()
        }
        currentContainer.installationId = installationId
        currentContainer.currentInstallation = updatedInstallation
        saveCurrentContainerToKeychain()
    }

    private static func objectiveCCurrentInstallation(from keychain: KeychainStore) -> BaseParseInstallation? {
        guard let object = keychain.unarchivedObjectiveCObject(forKey: objectiveCCurrentInstallationKey),
              let dictionary = object as? [String: Any],
              JSONSerialization.isValidJSONObject(dictionary),
              let data = try? JSONSerialization.data(withJSONObject: dictionary) else {
            return nil
        }
        return objectiveCCurrentInstallation(from: data)
    }

    private static func objectiveCCurrentInstallationFromDisk() -> BaseParseInstallation? {
        guard let fileURL = objectiveCParseDirectoryURL()?.appendingPathComponent(objectiveCCurrentInstallationKey),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return objectiveCCurrentInstallation(from: data)
    }

    private static func objectiveCCurrentInstallation(from data: Data) -> BaseParseInstallation? {
        (try? ParseCoding.jsonDecoder().decode(ObjectiveCInstallationFile.self, from: data))?.parseInstallation
    }

    private static func objectiveCInstallationId(from keychain: KeychainStore) -> String? {
        if let installationId: String = keychain.objectObjectiveC(forKey: objectiveCInstallationIdKey) {
            return installationId
        }
        guard let fileURL = objectiveCParseDirectoryURL()?.appendingPathComponent(objectiveCInstallationIdKey),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private static func objectiveCParseDirectoryURL() -> URL? {
        #if os(macOS)
        guard let directory = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory,
                                                                  .userDomainMask,
                                                                  true).first else {
            return nil
        }
        return URL(fileURLWithPath: directory, isDirectory: true)
            .appendingPathComponent(objectiveCParseDirectoryName, isDirectory: true)
            .appendingPathComponent(Parse.configuration.applicationId, isDirectory: true)
        #else
        return URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Private Documents", isDirectory: true)
            .appendingPathComponent(objectiveCParseDirectoryName, isDirectory: true)
        #endif
    }
}
#endif
