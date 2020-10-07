import Foundation

private func getObjectId<T: ParseObject>(target: T) -> String {
    guard let objectId = target.objectId else {
        fatalError("Cannot set a pointer to an unsaved object")
    }
    return objectId
}

private func getObjectId(target: Objectable) -> String {
    guard let objectId = target.objectId else {
        fatalError("Cannot set a pointer to an unsaved object")
    }
    return objectId
}

public struct Pointer<T: ParseObject>: Fetchable, Codable {
    public typealias FetchingType = T

    private let __type: String = "Pointer" // swiftlint:disable:this identifier_name
    public var objectId: String
    public var className: String

    public init(_ target: T) {
        self.objectId = getObjectId(target: target)
        self.className = target.className
    }

    public init(objectId: String) {
        self.className = T.className
        self.objectId = objectId
    }

    private enum CodingKeys: String, CodingKey {
        case __type, objectId, className // swiftlint:disable:this identifier_name
    }
}

extension Pointer {
    public func fetch(options: API.Options = []) throws -> T {
        let path = API.Endpoint.object(className: className, objectId: objectId)
        return try API.Command<NoBody, T>(method: .GET,
                                      path: path) { (data) -> T in
                    try ParseCoding.jsonDecoder().decode(T.self, from: data)
        }.execute(options: options)
    }

    public func fetch(options: API.Options = [], callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<T, ParseError>) -> Void) {
        let path = API.Endpoint.object(className: className, objectId: objectId)
        API.Command<NoBody, T>(method: .GET,
                                      path: path) { (data) -> T in
                    try ParseCoding.jsonDecoder().decode(T.self, from: data)
        }.executeAsync(options: options, callbackQueue: callbackQueue, completion: completion)
    }
}

internal struct PointerType: Codable {

    private let __type: String = "Pointer" // swiftlint:disable:this identifier_name
    public var objectId: String
    public var className: String

    public init(_ target: Objectable) {
        self.objectId = getObjectId(target: target)
        self.className = target.className
    }

    private enum CodingKeys: String, CodingKey {
        case __type, objectId, className // swiftlint:disable:this identifier_name
    }
}
