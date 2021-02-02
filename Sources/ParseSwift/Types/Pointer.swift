import Foundation

private func getObjectId<T: ParseObject>(target: T) throws -> String {
    guard let objectId = target.objectId else {
        throw ParseError(code: .missingObjectId, message: "Cannot set a pointer to an unsaved object")
    }
    return objectId
}

private func getObjectId(target: Objectable) throws -> String {
    guard let objectId = target.objectId else {
        throw ParseError(code: .missingObjectId, message: "Cannot set a pointer to an unsaved object")
    }
    return objectId
}

public struct Pointer<T: ParseObject>: Fetchable, Encodable {
    public typealias FetchingType = T

    private let __type: String = "Pointer" // swiftlint:disable:this identifier_name
    public var objectId: String
    public var className: String

    public init(_ target: T) throws {
        self.objectId = try getObjectId(target: target)
        self.className = target.className
    }

    public init(objectId: String) {
        self.className = T.className
        self.objectId = objectId
    }

    private enum CodingKeys: String, CodingKey {
        case __type, objectId, className // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        objectId = try values.decode(String.self, forKey: .objectId)
        className = try values.decode(String.self, forKey: .className)
    }
}

extension Pointer {
    public func fetch(includeKeys: [String]? = nil, options: API.Options = []) throws -> T {
        let path = API.Endpoint.object(className: className, objectId: objectId)
        return try API.NonParseBodyCommand<NoBody, T>(method: .GET,
                                      path: path) { (data) -> T in
                    try ParseCoding.jsonDecoder().decode(T.self, from: data)
        }.execute(options: options)
    }

    public func fetch(options: API.Options = [], callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<T, ParseError>) -> Void) {
        let path = API.Endpoint.object(className: className, objectId: objectId)
        API.NonParseBodyCommand<NoBody, T>(method: .GET,
                                      path: path) { (data) -> T in
                    try ParseCoding.jsonDecoder().decode(T.self, from: data)
        }.executeAsync(options: options) { result in
            callbackQueue.async {
                completion(result)
            }
        }
    }
}

internal struct PointerType: Encodable {

    var __type: String = "Pointer" // swiftlint:disable:this identifier_name
    public var objectId: String
    public var className: String

    public init(_ target: Objectable) throws {
        self.objectId = try getObjectId(target: target)
        self.className = target.className
    }

    private enum CodingKeys: String, CodingKey {
        case __type, objectId, className // swiftlint:disable:this identifier_name
    }
}
