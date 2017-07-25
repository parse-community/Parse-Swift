import Foundation

public class RESTCommand<T, U>: Encodable where T: Encodable {
    typealias ReturnType = U
    let method: API.Method
    let path: String
    let body: T?
    let mapper: ((Data) throws -> U)

    var task: URLSessionDataTask?
    private var _useMasterKey: Bool = false
    private var _onSuccess: ((U)->())?
    private var _onError: ((Error)->())?

    init(method: API.Method, path: String, body: T? = nil, mapper: @escaping ((Data) throws -> U)) {
        self.method = method
        self.path = path
        self.body = body
        self.mapper = mapper
    }

    public func execute(_ cb: ((Result<U>) -> Void)? = nil) throws -> RESTCommand<T, U> {
        let data = try getEncoder().encode(body)
        task = API.request(method: method, path: path, body: data, useMasterKey: _useMasterKey, callback: { (result) in
            self.runContinuations(result.map(self.mapper), cb)
        })
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

typealias ParseObjectBatchCommand<T> = BatchCommand<T, T> where T: ParseObjectType
typealias ParseObjectBatchResponse<T> = [(T, ParseError?)]
typealias RESTBatchCommandType<T> = RESTCommand<ParseObjectBatchCommand<T>, ParseObjectBatchResponse<T>> where T: ParseObjectType

public class RESTBatchCommand<T>: RESTBatchCommandType<T> where T: ParseObjectType {
    typealias ParseObjectCommand = RESTCommand<T, T>
    typealias ParseObjectBatchCommand = BatchCommand<T, T>

    init(commands: [ParseObjectCommand]) {
        let commands = commands.flatMap { (command) -> RESTCommand<T, T>? in
            let path = "/1" + command.path
            guard let body = command.body else {
                return nil
            }
            return RESTCommand<T, T>(method: command.method, path: path, body: body, mapper: command.mapper)
        }
        let bodies = commands.flatMap { (command) -> T? in
            return command.body
        }
        let mapper = { (data: Data) -> [(T, ParseError?)] in
            let responses = try getDecoder().decode([BatchResponseItem<SaveOrUpdateResponse>].self, from: data)
            return bodies.enumerated().map({ (object) -> (T, ParseError?) in
                let response = responses[object.0]
                if let success = response.success {
                    return (success.apply(object.1), nil)
                } else {
                    return (object.1, response.error)
                }
            })
        }
        super.init(method: .POST, path: "/batch", body: BatchCommand(requests: commands), mapper: mapper)
    }
}

internal extension RESTCommand {
    // MARK: Saving
    internal static func save<T>(_ object: T) -> RESTCommand<T, T> where T: ParseObjectType {
        if object.isSaved {
            return updateCommand(object)
        }
        return createCommand(object)
    }

    // MARK: Saving - private
    private static func createCommand<T>(_ object: T) -> RESTCommand<T, T> where T: ParseObjectType {
        return RESTCommand<T, T>(method: .POST, path: object.remotePath, body: object, mapper: { (data) -> T in
            return try getDecoder().decode(SaveResponse.self, from: data)
                .apply(object)
        })
    }

    private static func updateCommand<T>(_ object: T) -> RESTCommand<T, T> where T: ParseObjectType {
        return RESTCommand<T, T>(method: .PUT, path: object.remotePath, body: object, mapper: { (data: Data) -> T in
            return try getDecoder().decode(UpdateResponse.self, from: data)
                .apply(object)
        })
    }

    // MARK: Fetching
    internal static func fetch<T>(_ object: T) throws -> RESTCommand<T, T> where T: ParseObjectType {
        guard object.isSaved else {
            throw ParseError(code: -1, error: "Cannot Fetch an object without id")
        }
        return RESTCommand<T, T>(method: .GET, path: object.remotePath, body: nil, mapper: { (data) -> T in
            return try getDecoder().decode(T.self, from: data)
        })
    }
}

public struct BatchCommand<T, U>: Encodable where T: Encodable {
    let requests: [RESTCommand<T, U>]
}

public struct BatchResponseItem<T>: Decodable where T: Decodable {
    let success: T?
    let error: ParseError?
}
