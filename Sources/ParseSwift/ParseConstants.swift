//
//  ParseConstants.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/7/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

let kParseVersion = "0.0.1"

//Append this string using an internal method if a protocol requires `set`,
//but you want to detect if only an internal method made the change.
//the string will be stripped before sending to the parseServer
let kParseInternalModificationSuffix = "_ModifiedByParseInternalMethod"
