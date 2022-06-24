//
//  ParsePushAppleSound.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/5/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 Use these keys to configure the sound for a critical alert.
 - warning: For Apple OS's only.
 */
public struct ParsePushAppleSound: ParseTypeable {
    /**
     The critical alert flag. Set to **true** to enable the critical alert.
     */
    var critical: Bool?
    /**
     The name of a sound file in your app’s main bundle or in the
     Library/Sounds folder of your app’s container directory. Specify the
     string “default” to play the system sound. For information about how
     to prepare sounds, see [UNNotificationSound](https://developer.apple.com/documentation/usernotifications/unnotificationsound).
     */
    var name: String?
    /**
     The volume for the critical alert’s sound. Set this to a value
     between 0 (silent) and 1 (full volume).
     */
    var volume: Double?
}
