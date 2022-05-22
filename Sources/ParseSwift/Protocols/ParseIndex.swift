//
//  ParseIndex.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 `ParseIndex` is used to create/update an index on a field of `ParseSchema`.
 The "property name" should match the "field name" the index should be added to.
 The "property value" should be the "type" of index to add which is usually a **String** or **Int*.
*/
public protocol ParseIndex: Codable { }
