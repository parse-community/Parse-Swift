import Foundation

// public struct Parse {
var _applicationId: String!
var _masterKey: String?
var _clientKey: String?
var _serverURL: URL!

public func initialize(applicationId: String, clientKey: String? = nil, masterKey: String? = nil, serverURL: URL) {
    _applicationId = applicationId
    _clientKey = clientKey
    _masterKey = masterKey
    _serverURL = serverURL
}

extension String {

    /// Percent escapes values to be added to a URL query as specified in RFC 3986
    ///
    /// This percent-escapes all characters besides the alphanumeric character set and "-", ".", "_", and "~".
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// :returns: Returns percent-escaped string.

    func addingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")

        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }

}

/// Build string representation of HTTP parameter dictionary of keys and objects
///
/// This percent escapes in compliance with RFC 3986
///
/// http://www.ietf.org/rfc/rfc3986.txt
///
/// :returns: String representation in the form of key1=value1&key2=value2 where the keys and values are percent escaped
func stringFromHttpParameters<T>(_ params: [String: T]) -> String where T: Encodable {
    return params.flatMap { (key, value) -> String? in
        let percentEscapedKey = key.addingPercentEncodingForURLQueryValue()!
        if let percentEscapedValue = try? getEncoder().encode(value) {
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        return nil
    }.joined(separator: "&")
}

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
        print(url)
        print(urlRequest.url!.query)
        urlRequest.httpMethod = method.rawValue
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let data = data {
                print(String(data: data, encoding: .utf8))
            }
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
//}

