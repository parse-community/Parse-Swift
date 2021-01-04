//
//  Operations.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

enum Operation: String, Encodable {
    case connect
    case subscribe
    case create
    case enter
    case update
    case leave
    case delete
    case unsubscribe
}

enum OperationResponses: String, Decodable {
    case connected, subscribed, unsubscribed, error
}
