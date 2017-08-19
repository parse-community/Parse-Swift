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

        return headers
    }

    public typealias Response = (Result<Data>)->()

    public static func request(method: Method,
                               path: String,
                               params: [URLQueryItem]? = nil,
                               body: Data? = nil,
                               useMasterKey: Bool = false,
                               callback: Response? = nil) -> URLSessionDataTask {

        let headers = getHeaders(useMasterKey: useMasterKey)
        let url = _serverURL.appendingPathComponent(path)

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

    public static func get(path: String, callback: Response? = nil) -> URLSessionDataTask {
        return request(method: .GET, path: path, callback: callback)
    }

    public static func post(path: String, body: Data?, callback: Response? = nil) -> URLSessionDataTask {
        return request(method: .POST, path: path, body: body, callback: callback)
    }

    public static func put(path: String, body: Data?, callback: Response? = nil) -> URLSessionDataTask {
        return request(method: .PUT, path: path, body: body, callback: callback)
    }

    public static func get(className: String, objectId: String, callback: Response? = nil) -> URLSessionDataTask {
        return get(path: "/classes/\(className)/\(objectId)", callback: callback)
    }

    public static func get(className: String, callback: Response? = nil) -> URLSessionDataTask {
        return get(path: "/classes/\(className)", callback: callback)
    }
}
