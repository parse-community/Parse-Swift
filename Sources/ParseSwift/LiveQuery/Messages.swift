//
//  Messages.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

// MARK: Sending
struct StandardMessage: LiveQueryable, Codable {
    var op: ClientOperation // swiftlint:disable:this identifier_name
    var applicationId: String?
    var clientKey: String?
    var masterKey: String? // swiftlint:disable:this inclusive_language
    var sessionToken: String?
    var installationId: String?
    var requestId: Int?

    init(operation: ClientOperation, additionalProperties: Bool = false) {
        self.op = operation
        if additionalProperties {
            self.applicationId = Parse.configuration.applicationId
            self.masterKey = Parse.configuration.masterKey
            self.clientKey = Parse.configuration.clientKey
            self.sessionToken = BaseParseUser.currentContainer?.sessionToken
            self.installationId = BaseParseInstallation.currentContainer.installationId
        }
    }

    init(operation: ClientOperation, requestId: RequestId) {
        self.init(operation: operation)
        self.requestId = requestId.value
    }
}

struct SubscribeQuery: Encodable {
    let className: String
    let `where`: QueryWhere
    let fields: Set<String>?
}

struct SubscribeMessage<T: ParseObject>: LiveQueryable, Encodable {
    var op: ClientOperation // swiftlint:disable:this identifier_name
    var applicationId: String?
    var clientKey: String?
    var sessionToken: String?
    var installationId: String?
    var requestId: Int?
    var query: SubscribeQuery?

    init(operation: ClientOperation,
         requestId: RequestId,
         query: Query<T>? = nil,
         additionalProperties: Bool = false) {
        self.op = operation
        self.requestId = requestId.value
        if let query = query {
            self.query = SubscribeQuery(className: query.className,
                                        where: query.where,
                                        fields: query.fields ?? query.keys)
        }
        self.sessionToken = BaseParseUser.currentContainer?.sessionToken
    }
}

// MARK: Receiving
struct RedirectResponse: LiveQueryable, Codable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let url: URL
}

struct ConnectionResponse: LiveQueryable, Codable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let clientId: String
    let installationId: String?
}

struct UnsubscribedResponse: LiveQueryable, Codable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let requestId: Int
    let clientId: String
    let installationId: String?
}

struct EventResponse<T: ParseObject>: LiveQueryable, Codable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let requestId: Int
    let object: T
    let clientId: String
    let installationId: String?
}

struct ErrorResponse: LiveQueryable, Codable {
    let op: OperationErrorResponse // swiftlint:disable:this identifier_name
    let code: Int
    let message: String
    let reconnect: Bool

    enum CodingKeys: String, CodingKey {
        case op // swiftlint:disable:this identifier_name
        case code
        case message = "error"
        case reconnect
    }
}

struct PreliminaryMessageResponse: LiveQueryable, Codable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let requestId: Int
    let clientId: String
    let installationId: String?
}
