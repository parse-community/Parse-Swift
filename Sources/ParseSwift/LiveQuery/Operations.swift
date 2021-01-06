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
    case unsubscribe
}

enum OperationResponses: String, Decodable {
    case connected, subscribed, unsubscribed,
         create, enter, update, leave, delete
}

enum OperationErrorResponse: String, Decodable {
    case error
}

// An opaque placeholder structed used to ensure that we type-safely create request IDs and don't shoot ourself in
// the foot with array indexes.
struct RequestId: Hashable, Equatable, Codable {
    let value: Int

    init(value: Int) {
        self.value = value
    }
}
