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

internal class RESTCommand<T, U>: Cancellable, Encodable where T: Encodable {
    typealias ReturnType = U
    let method: API.Method
    let path: API.Endpoint
    let body: T?
    let mapper: ((Data) throws -> U)
    let params: [String: String?]?

    var task: URLSessionDataTask?
    private var _useMasterKey: Bool = false
    private var _onSuccess: ((U)->())?
    private var _onError: ((Error)->())?

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

    public func execute(_ cb: ((Result<U>) -> Void)? = nil) -> RESTCommand<T, U> {
        let data = try? getJSONEncoder().encode(body)
        let params = self.params?.getQueryItems()
        task = API.request(method: method,
                           path: path,
                           params: params,
                           body: data,
                           useMasterKey: _useMasterKey) { (result) in
            self.runContinuations(result.map(self.mapper), cb)
        }
        return self
    }

    public func cancel() {
        task?.cancel()
        task = nil
    }

    public func success(_ onSuccess: @escaping (U) -> ()) -> RESTCommand<T, U> {
        _onSuccess = onSuccess
        return self
    }

    public func error(_ onError: @escaping (Error) -> ()) -> RESTCommand<T, U> {
        _onError = onError
        return self
    }

    public func useMasterKey() -> RESTCommand<T, U> {
        _useMasterKey = true
        return self
    }

    private func runContinuations(_ result: Result<U>, _ cb: ((Result<U>) -> Void)?) {
        switch result {
        case .success(let obj):
            _onSuccess?(obj)
        case .error(let err):
            _onError?(err)
        default: break
        }
        cb?(result)
    }

    enum CodingKeys: String, CodingKey {
        case method, body, path
    }
}

internal extension RESTCommand where T: ObjectType {
    internal func execute(_ cb: ((Result<U>) -> Void)? = nil) -> RESTCommand<T, U> {
        let data = try? body?.getEncoder().encode(body)
        let params = self.params?.getQueryItems()
        task = API.request(method: method,
                           path: path,
                           params: params,
                           body: data!,
                           useMasterKey: _useMasterKey) { (result) in
            self.runContinuations(result.map(self.mapper), cb)
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
                                 path: object.remotePath,
                                 body: object) { (data) -> T in
            try getDecoder().decode(SaveResponse.self, from: data).apply(object)
        }
    }

    private static func updateCommand<T>(_ object: T) -> RESTCommand<T, T> where T: ObjectType {
        return RESTCommand<T, T>(method: .PUT,
                                 path: object.remotePath,
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
                                 path: object.remotePath) { (data) -> T in
            try getDecoder().decode(T.self, from: data)
        }
    }
}
