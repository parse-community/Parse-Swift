//
//  ParseCloudUser.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/*
 A `ParseUser` that contains additional attributes
 needed for Parse hook calls.
 */
public protocol ParseCloudUser: ParseUser {
    /// The session token of the `ParseUser`.
    var sessionToken: String? { get set }
}
