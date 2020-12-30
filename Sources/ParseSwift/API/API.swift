//
//  API.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-19.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public struct API {

    internal enum Method: String, Encodable {
        case GET, POST, PUT, DELETE
    }

    internal enum Endpoint: Encodable {
        case batch
        case objects(className: String)
        case object(className: String, objectId: String)
        case login
        case signup
        case logout
        case file(fileName: String)
        case passwordReset
        case functions(name: String)
        case jobs(name: String)
        case any(String)

        var urlComponent: String {
            switch self {
            case .batch:
                return "/batch"
            case .objects(let className):
                return "/classes/\(className)"
            case .object(let className, let objectId):
                return "/classes/\(className)/\(objectId)"
            case .login:
                return "/login"
            case .signup:
                return "/users"
            case .logout:
                return "/users/logout"
            case .file(let fileName):
                return "/files/\(fileName)"
            case .passwordReset:
                return "/requestPasswordReset"
            case .functions(name: let name):
                return "/functions/\(name)"
            case .jobs(name: let name):
                return "/jobs/\(name)"
            case .any(let path):
                return path
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(urlComponent)
        }
    }

    public typealias Options = Set<API.Option>

    public enum Option: Hashable {
        case useMasterKey // swiftlint:disable:this inclusive_language
        case sessionToken(String)
        case installationId(String)
        case mimeType(String)
        case fileSize(String)
        case removeMimeType
        case metadata([String: String])
        case tags([String: String])

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
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    internal static func getHeaders(options: API.Options) -> [String: String] {
        var headers: [String: String] = ["X-Parse-Application-Id": ParseConfiguration.applicationId,
                                         "Content-Type": "application/json"]
        if let clientKey = ParseConfiguration.clientKey {
            headers["X-Parse-Client-Key"] = clientKey
        }

        if let token = BaseParseUser.currentUserContainer?.sessionToken {
            headers["X-Parse-Session-Token"] = token
        }

        if let installationId = BaseParseInstallation.currentInstallationContainer.installationId {
            headers["X-Parse-Installation-Id"] = installationId
        }

        options.forEach { (option) in
            switch option {
            case .useMasterKey:
                headers["X-Parse-Master-Key"] = ParseConfiguration.masterKey
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
            }
        }

        return headers
    }
}

internal extension Dictionary where Key == String, Value == String? {
    func getQueryItems() -> [URLQueryItem] {
        return map { (key, value) -> URLQueryItem in
            return URLQueryItem(name: key, value: value)
        }
    }
}
