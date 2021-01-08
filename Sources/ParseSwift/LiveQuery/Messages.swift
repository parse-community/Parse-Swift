//
//  Messages.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

// MARK: Sending
struct StandardMessage: LiveQueryable, Encodable {
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
            self.applicationId = ParseConfiguration.applicationId
            self.masterKey = ParseConfiguration.masterKey
            self.clientKey = ParseConfiguration.clientKey
            self.sessionToken = BaseParseUser.currentUserContainer?.sessionToken
            self.installationId = BaseParseInstallation.currentInstallationContainer.installationId
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
    let fields: [String]?
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
            self.query = SubscribeQuery(className: query.className, where: query.where, fields: query.fields)
        }
        self.sessionToken = BaseParseUser.currentUserContainer?.sessionToken
    }
}

// MARK: Receiving
struct RedirectResponse: LiveQueryable, Decodable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let url: URL
}

struct ConnectionResponse: LiveQueryable, Decodable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let clientId: String
    let installationId: String?
}

struct UnsubscribedResponse: LiveQueryable, Decodable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let requestId: Int
    let clientId: String
    let installationId: String?
}

struct EventResponse<T: ParseObject>: LiveQueryable, Decodable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let requestId: Int
    let object: T
    let clientId: String
    let installationId: String?
}

struct ErrorResponse: LiveQueryable, Decodable {
    let op: OperationErrorResponse // swiftlint:disable:this identifier_name
    let code: Int
    let error: String
    let reconnect: Bool
}

struct PreliminaryMessageResponse: LiveQueryable, Decodable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let requestId: Int
    let clientId: String
    let installationId: String?
}
