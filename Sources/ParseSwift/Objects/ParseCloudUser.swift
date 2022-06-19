//
//  ParseCloudUser.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public protocol ParseCloudUser: ParseUser {
    var sessionToken: String? { get set }
}
