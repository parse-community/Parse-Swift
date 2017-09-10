//
//  API.swift
//  Parse (iOS)
//
//  Created by Florent Vilmart on 17-08-19.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public struct API {

    public enum Method: String, Encodable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    public enum Endpoint: Encodable {
        case batch
        case objects(className: String)
        case object(className: String, objectId: String)
        case login
        case signup
        case logout
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
            case .any(let path):
                return path
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(urlComponent)
        }
    }

    public struct Option: OptionSet {
        public let rawValue: UInt
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        static let useMasterKey = Option(rawValue: 1 << 0)
    }

    private static func getHeaders(useMasterKey: Bool = false) -> [String: String] {
        var headers: [String: String] = ["X-Parse-Application-Id": ParseConfiguration.applicationId,
                                         "Content-Type": "application/json"]
        if let clientKey = ParseConfiguration.clientKey {
            headers["X-Parse-Client-Key"] = clientKey
        }
        if useMasterKey,
            let masterKey = ParseConfiguration.masterKey {
            headers["X-Parse-Master-Key"] = masterKey
        }

        if let token = CurrentUserInfo.currentSessionToken {
            headers["X-Parse-Session-Token"] = token
        }

        return headers
    }

    public typealias Response = (Result<Data>) -> Void

    internal static func request(method: Method,
                                 path: Endpoint,
                                 params: [URLQueryItem]? = nil,
                                 body: Data? = nil,
                                 options: Option,
                                 callback: Response? = nil) -> URLSessionDataTask {

        let headers = getHeaders(useMasterKey: options.contains(.useMasterKey))
        let url = ParseConfiguration.serverURL.appendingPathComponent(path.urlComponent)

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = params

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.allHTTPHeaderFields = headers
        if let body = body {
            urlRequest.httpBody = body
        }
        urlRequest.httpMethod = method.rawValue
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, _, error) in
            callback?(Result(data, error))
        }
        task.resume()
        return task
    }
}
