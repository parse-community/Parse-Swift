//
//  ParseConstants.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/7/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

let kParseVersion = "0.0.1"

#if os(iOS)
let kPFDeviceType = "ios"
#elseif os(macOS)
let kPFDeviceType = "osx"
#elseif os(tvOS)
let kPFDeviceType = "tvos"
#elseif os(watchOS)
let kParseDeviceType = "applewatch"
#endif
