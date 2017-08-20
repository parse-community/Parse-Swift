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
        case GET, POST, PUT, DELETE
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
                return "/\(className)"
            case .object(let className, let objectId):
                return "/\(className)/\(objectId)"
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

    private static func getHeaders(useMasterKey: Bool = false) -> [String: String] {
        var headers: [String: String] = ["X-Parse-Application-Id": _applicationId,
                                         "Content-Type": "application/json"]
        if let clientKey = _clientKey {
            headers["X-Parse-Client-Key"] = clientKey
        }
        if useMasterKey,
            let masterKey = _masterKey {
            headers["X-Parse-Master-Key"] = masterKey
        }

        if let token = CurrentUserInfo.currentSessionToken {
            headers["X-Parse-Session-Token"] = token
        }

        return headers
    }

    public typealias Response = (Result<Data>)->()

    internal static func request(method: Method,
                               path: Endpoint,
                               params: [URLQueryItem]? = nil,
                               body: Data? = nil,
                               useMasterKey: Bool = false,
                               callback: Response? = nil) -> URLSessionDataTask {

        let headers = getHeaders(useMasterKey: useMasterKey)
        let url = _serverURL.appendingPathComponent(path.urlComponent)

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = params

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.allHTTPHeaderFields = headers
        if let body = body {
            urlRequest.httpBody = body
        }
        urlRequest.httpMethod = method.rawValue
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            callback?(Result(data, error))
        }
        task.resume()
        return task
    }
}
