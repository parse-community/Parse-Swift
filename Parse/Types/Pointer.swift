import Foundation

private func getObjectId<T: ObjectType>(target: T) -> String {
    guard let objectId = target.objectId else {
        fatalError("Cannot set a pointer to an unsaved object")
    }
    return objectId
}

public struct Pointer<T: ObjectType>: Fetching, Codable {
    private let __type: String = "Pointer"
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
        case __type, objectId, className
    }
}

extension Pointer {
    public func fetch(callback: ((Result<T>) -> Void)?) -> Cancellable? {
        return RESTCommand<NoBody, T>(method: .GET, path: "/classes/\(className)/\(objectId)", mapper: { (data) -> T in
            return try getDecoder().decode(T.self, from: data)
        }).execute(callback)
    }
}
