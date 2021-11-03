//
//  API.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-19.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// swiftlint:disable line_length

/// The REST API for communicating with a Parse Server.
public struct API {

    internal enum Method: String, Encodable {
        case GET, POST, PUT, PATCH, DELETE
    }

    internal enum Endpoint: Encodable {
        case batch
        case objects(className: String)
        case object(className: String, objectId: String)
        case users
        case user(objectId: String)
        case installations
        case installation(objectId: String)
        case sessions
        case session(objectId: String)
        case event(event: String)
        case roles
        case role(objectId: String)
        case login
        case logout
        case file(fileName: String)
        case passwordReset
        case verificationEmail
        case functions(name: String)
        case jobs(name: String)
        case aggregate(className: String)
        case config
        case health
        case any(String)

        var urlComponent: String {
            switch self {
            case .batch:
                return "/batch"
            case .objects(let className):
                return "/classes/\(className)"
            case .object(let className, let objectId):
                return "/classes/\(className)/\(objectId)"
            case .users:
                return "/users"
            case .user(let objectId):
                return "/users/\(objectId)"
            case .installations:
                return "/installations"
            case .installation(let objectId):
                return "/installations/\(objectId)"
            case .sessions:
                return "/sessions"
            case .session(let objectId):
                return "/sessions/\(objectId)"
            case .event(let event):
                return "/events/\(event)"
            case .aggregate(let className):
                return "/aggregate/\(className)"
            case .roles:
                return "/roles"
            case .role(let objectId):
                return "/roles/\(objectId)"
            case .login:
                return "/login"
            case .logout:
                return "/logout"
            case .file(let fileName):
                return "/files/\(fileName)"
            case .passwordReset:
                return "/requestPasswordReset"
            case .verificationEmail:
                return "/verificationEmailRequest"
            case .functions(name: let name):
                return "/functions/\(name)"
            case .jobs(name: let name):
                return "/jobs/\(name)"
            case .config:
                return "/config"
            case .health:
                return "/health"
            case .any(let path):
                return path
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(urlComponent)
        }
    }

    /// A type alias for the set of options.
    public typealias Options = Set<API.Option>

    /// Options available to send to Parse Server.
    public enum Option: Hashable {

        /// Use the masterKey if it was provided during initial configuraration.
        case useMasterKey // swiftlint:disable:this inclusive_language
        /// Use a specific session token.
        /// - note: The session token of the current user is provided by default.
        case sessionToken(String)
        /// Use a specific installationId.
        /// - note: The installationId of the current user is provided by default.
        case installationId(String)
        /// Specify mimeType.
        case mimeType(String)
        /// Specify fileSize.
        case fileSize(String)
        /// Remove mimeType.
        /// - note: This is typically used indirectly by `ParseFile`.
        case removeMimeType
        /// Specify metadata.
        /// - note: This is typically used indirectly by `ParseFile`.
        case metadata([String: String])
        /// Specify tags.
        /// - note: This is typically used indirectly by `ParseFile`.
        case tags([String: String])
        /// Add context.
        /// - warning: Requires Parse Server > 4.5.0.
        case context(Encodable)
        /// The caching policy to use for a specific http request. Determines when to
        /// return a response from the cache. See Apple's
        /// [documentation](https://developer.apple.com/documentation/foundation/url_loading_system/accessing_cached_data)
        /// for more info.
        case cachePolicy(URLRequest.CachePolicy)

        public func hash(into hasher: inout Hasher) {
            switch self {
            case .useMasterKey:
                hasher.combine(1)
            case .sessionToken:
                hasher.combine(2)
            case .installationId:
                hasher.combine(3)
            case .mimeType:
                hasher.combine(4)
            case .fileSize:
                hasher.combine(5)
            case .removeMimeType:
                hasher.combine(6)
            case .metadata:
                hasher.combine(7)
            case .tags:
                hasher.combine(8)
            case .context:
                hasher.combine(9)
            case .cachePolicy:
                hasher.combine(10)
            }
        }

        public static func == (lhs: API.Option, rhs: API.Option) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    internal static func getHeaders(options: API.Options) -> [String: String] {
        var headers: [String: String] = ["X-Parse-Application-Id": ParseSwift.configuration.applicationId,
                                         "Content-Type": "application/json"]
        if let clientKey = ParseSwift.configuration.clientKey {
            headers["X-Parse-Client-Key"] = clientKey
        }

        if let token = BaseParseUser.currentContainer?.sessionToken {
            headers["X-Parse-Session-Token"] = token
        }

        if let installationId = BaseParseInstallation.currentContainer.installationId {
            headers["X-Parse-Installation-Id"] = installationId
        }

        headers["X-Parse-Client-Version"] = clientVersion()
        headers["X-Parse-Request-Id"] = UUID().uuidString.lowercased()

        options.forEach { (option) in
            switch option {
            case .useMasterKey:
                headers["X-Parse-Master-Key"] = ParseSwift.configuration.masterKey
            case .sessionToken(let sessionToken):
                headers["X-Parse-Session-Token"] = sessionToken
            case .installationId(let installationId):
                headers["X-Parse-Installation-Id"] = installationId
            case .mimeType(let mimeType):
                headers["Content-Type"] = mimeType
            case .fileSize(let fileSize):
                headers["Content-Length"] = fileSize
            case .removeMimeType:
                headers.removeValue(forKey: "Content-Type")
            case .metadata(let metadata):
                metadata.forEach {(key, value) -> Void in
                    headers[key] = value
                }
            case .tags(let tags):
                tags.forEach {(key, value) -> Void in
                    headers[key] = value
                }
            case .context(let context):
                let context = AnyEncodable(context)
                if let encoded = try? ParseCoding.jsonEncoder().encode(context),
                   let encodedString = String(data: encoded, encoding: .utf8) {
                    headers["X-Parse-Cloud-Context"] = encodedString
                }
            default:
                break
            }
        }

        return headers
    }

    internal static func clientVersion() -> String {
        ParseConstants.sdk+ParseConstants.version
    }
}

internal extension Dictionary where Key == String, Value == String? {
    func getQueryItems() -> [URLQueryItem] {
        return map { (key, value) -> URLQueryItem in
            return URLQueryItem(name: key, value: value)
        }
    }
}
