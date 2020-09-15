//
//  ParseConstants.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/7/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

enum ParseConstants {
    static let parseVersion = "0.0.1"
    #if os(iOS)
    static let deviceType = "ios"
    #elseif os(macOS)
    static let deviceType = "osx"
    #elseif os(tvOS)
    static let deviceType = "tvos"
    #elseif os(watchOS)
    static let deviceType = "applewatch"
    #endif
}
