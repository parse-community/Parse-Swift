//
//  ParseSession.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/17/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
 `ParseSession` is a local representation of a session.
 This protocol conforms to `ParseObject` and retains the
 same functionality.
 */
public protocol ParseSession: ParseObject {
    associatedtype SessionUser: ParseUser

    /// The session token for this session.
    var sessionToken: String { get }

    /// The user the session is for.
    var user: SessionUser { get }

    /// Whether the session is restricted.
    /// - warning: This will be deprecated in newer versions of Parse Server.
    var restricted: Bool? { get }

    /// Information about how the session was created.
    var createdWith: [String: String] { get }

    /// Referrs to the `ParseInstallation` where the
    /// session logged in from.
    var installationId: String { get }

    /// Approximate date when this session will automatically
    /// expire.
    var expiresAt: Date { get }
}

// MARK: Default Implementations
public extension ParseSession {
    static var className: String {
        "_Session"
    }
}

// MARK: Convenience
extension ParseSession {
    var endpoint: API.Endpoint {
        if let objectId = objectId {
            return .session(objectId: objectId)
        }
        return .sessions
    }
}
