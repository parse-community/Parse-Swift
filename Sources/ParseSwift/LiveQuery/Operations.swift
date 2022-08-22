//
//  Operations.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

enum ClientOperation: String, Codable {
    case connect
    case subscribe
    case unsubscribe
    case update
}

enum ServerResponse: String, Codable {
    case connected, subscribed, unsubscribed, redirect,
         create, enter, update, leave, delete
}

enum OperationErrorResponse: String, Codable {
    case error
}

// An opaque placeholder structed used to ensure that we type-safely create request IDs and do not shoot ourself in
// the foot with array indexes.
struct RequestId: Hashable, Equatable, Codable {
    let value: Int
}
