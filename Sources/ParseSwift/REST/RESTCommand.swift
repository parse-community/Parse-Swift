import Foundation

internal extension Dictionary where Key == String, Value == String? {
    func getQueryItems() -> [URLQueryItem] {
        return map { (key, value) -> URLQueryItem in
            return URLQueryItem(name: key, value: value)
        }
    }
}

public protocol Cancellable {
    func cancel()
}

private let commandQueue = DispatchQueue(label: "com.parse.ParseSwift.restCommandQueue")

internal class RESTCommand<T, U>: Cancellable, Encodable where T: Encodable {
    internal struct Empty: Encodable {}
    typealias ReturnType = U
    let method: API.Method
    let path: API.Endpoint
    let body: T?
    let mapper: ((Data) throws -> U)
    let params: [String: String?]?

    var task: URLSessionDataTask?

    init(method: API.Method,
         path: API.Endpoint,
         params: [String: String]? = nil,
         body: T? = nil,
         mapper: @escaping ((Data) throws -> U)) {
        self.method = method
        self.path = path
        self.body = body
        self.mapper = mapper
        self.params = params
    }

    public func execute(options: API.Option, _ callback: ((Result<U>) -> Void)? = nil) -> RESTCommand<T, U> {
        let data = try? getJSONEncoder().encode(body)
        let params = self.params?.getQueryItems()
        task = API.request(method: method,
                           path: path,
                           params: params,
                           body: data,
                           options: options) { (result) in
            callback?(result.map(self.mapper))
        }
        return self
    }

    public func cancel() {
        task?.cancel()
        task = nil
    }

    enum CodingKeys: String, CodingKey {
        case method, body, path
    }
}

internal extension RESTCommand where T: ObjectType {
    internal func execute(options: API.Option, _ callback: ((Result<U>) -> Void)? = nil) -> RESTCommand<T, U> {
        let data = try? body?.getEncoder().encode(body)
        let params = self.params?.getQueryItems()
        task = API.request(method: method,
                           path: path,
                           params: params,
                           body: data!,
                           options: options) { (result) in
            callback?(result.map(self.mapper))
        }
        return self
    }
}

internal extension RESTCommand {
    // MARK: Saving
    internal static func save<T>(_ object: T) -> RESTCommand<T, T> where T: ObjectType {
        if object.isSaved {
            return updateCommand(object)
        }
        return createCommand(object)
    }

    // MARK: Saving - private
    private static func createCommand<T>(_ object: T) -> RESTCommand<T, T> where T: ObjectType {
        return RESTCommand<T, T>(method: .POST,
                                 path: object.endpoint,
                                 body: object) { (data) -> T in
            try getDecoder().decode(SaveResponse.self, from: data).apply(object)
        }
    }

    private static func updateCommand<T>(_ object: T) -> RESTCommand<T, T> where T: ObjectType {
        return RESTCommand<T, T>(method: .PUT,
                                 path: object.endpoint,
                                 body: object) { (data: Data) -> T in
            try getDecoder().decode(UpdateResponse.self, from: data).apply(object)
        }
    }

    // MARK: Fetching
    internal static func fetch<T>(_ object: T) throws -> RESTCommand<T, T> where T: ObjectType {
        guard object.isSaved else {
            throw ParseError(code: -1, error: "Cannot Fetch an object without id")
        }
        return RESTCommand<T, T>(method: .GET,
                                 path: object.endpoint) { (data) -> T in
            try getDecoder().decode(T.self, from: data)
        }
    }
}
