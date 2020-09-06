//
//  ParseInstallation.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/6/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

/**
 A Parse Framework Installation Object that is a local representation of an
 installation persisted to the Parse cloud. This class is a subclass of a
 `ParseObject`, and retains the same functionality of a ParseObject, but also extends
 it with installation-specific fields and related immutability and validity
 checks.
 
 A valid `ParseInstallation` can only be instantiated via
 `+currentInstallation` because the required identifier fields
 are readonly. The `timeZone` and `badge` fields are also readonly properties which
 are automatically updated to match the device's time zone and application badge
 when the `ParseInstallation` is saved, thus these fields might not reflect the
 latest device state if the installation has not recently been saved.
 
 `ParseInstallation` objects which have a valid `deviceToken` and are saved to
 the Parse cloud can be used to target push notifications.
**/
struct ParseIntallation: ParseObject {

    /**
    The device type for the `ParseInstallation`.
    */
    var deviceType: String?

    /**
    The installationId for the `ParseInstallation`.
    */
    var installationId: String?

    /**
    The device token for the `ParseInstallation`.
    */
    var deviceToken: String?

    /**
    The badge for the `ParseInstallation`.
    */
    var badge: Int

    /**
    The name of the time zone for the `ParseInstallation`.
    */
    var timeZone: String?

    /**
    The channels for the `ParseInstallation`.
    */
    var channels: [String]?

    var objectId: String?

    var createdAt: Date?

    var updatedAt: Date?

    var ACL: ACL?
}
