import Foundation

protocol ParsePointer: Encodable {

    var __type: String { get } // swiftlint:disable:this identifier_name

    var className: String { get }

    var objectId: String { get set }
}

extension ParsePointer {
    /**
     Determines if two objects have the same objectId.
     - parameter as: Object to compare.
     - returns: Returns a **true** if the other object has the same `objectId` or **false** if unsuccessful.
    */
    func hasSameObjectId(as other: ParsePointer) -> Bool {
        return other.className == className && other.objectId == objectId
    }
}

private func getObjectId(target: Objectable) throws -> String {
    guard let objectId = target.objectId else {
        throw ParseError(code: .missingObjectId, message: "Cannot set a pointer to an unsaved object")
    }
    return objectId
}

/// A Pointer referencing a ParseObject.
public struct Pointer<T: ParseObject>: ParsePointer, ParseTypeable, Fetchable, Hashable {

    internal let __type: String = "Pointer" // swiftlint:disable:this identifier_name

    /**
     The class name of the object.
    */
    public var className: String

    /**
     The id of the object.
    */
    public var objectId: String

    /**
     Create a Pointer type.
     - parameter target: Object to point to.
     - throws: An error of type `ParseError`.
     */
    public init(_ target: T) throws {
        self.objectId = try getObjectId(target: target)
        self.className = target.className
    }

    /**
     Create a Pointer type.
     - parameter objectId: The id of the object.
     */
    public init(objectId: String) {
        self.className = T.className
        self.objectId = objectId
    }

    /**
     Convert a Pointer to its respective `ParseObject`.
     - returns: A `ParseObject` created from this Pointer.
     */
    public func toObject() -> T {
        var object = T()
        object.objectId = self.objectId
        return object
    }

    private enum CodingKeys: String, CodingKey {
        case __type, objectId, className // swiftlint:disable:this identifier_name
    }
}

public extension Pointer {

    /**
     Determines if a `ParseObject` and `Pointer`have the same `objectId`.
     - parameter as: `ParseObject` to compare.
     - returns: Returns a **true** if the other object has the same `objectId` or **false** if unsuccessful.
    */
    func hasSameObjectId(as other: T) -> Bool {
        return other.className == className && other.objectId == objectId
    }

    /**
     Determines if two `Pointer`'s have the same `objectId`.
     - parameter as: `Pointer` to compare.
     - returns: Returns a **true** if the other object has the same `objectId` or **false** if unsuccessful.
    */
    func hasSameObjectId(as other: Self) -> Bool {
        return other.className == className && other.objectId == objectId
    }

    /**
     Fetches the `ParseObject` *synchronously* with the current data from the server.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: The `ParseObject` with respect to the `Pointer`.
     - throws: An error of `ParseError` type.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetch(includeKeys: [String]? = nil,
               options: API.Options = []) throws -> T {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let path = API.Endpoint.object(className: className, objectId: objectId)
        return try API.NonParseBodyCommand<NoBody, T>(method: .GET,
                                      path: path) { (data) -> T in
                    try ParseCoding.jsonDecoder().decode(T.self, from: data)
        }.execute(options: options)
    }

    /**
     Fetches the `ParseObject` *asynchronously* and executes the given callback block.
     - parameter includeKeys: The name(s) of the key(s) to include. Use `["*"]` to include
     all keys.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<T, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetch(includeKeys: [String]? = nil,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<T, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let path = API.Endpoint.object(className: className, objectId: objectId)
        API.NonParseBodyCommand<NoBody, T>(method: .GET,
                                      path: path) { (data) -> T in
                    try ParseCoding.jsonDecoder().decode(T.self, from: data)
        }.executeAsync(options: options,
                       callbackQueue: callbackQueue) { result in
            completion(result)
        }
    }
}

internal struct PointerType: ParsePointer, Codable {
    var __type: String = "Pointer" // swiftlint:disable:this identifier_name
    var className: String
    var objectId: String

    init(_ target: Objectable) throws {
        self.objectId = try getObjectId(target: target)
        self.className = target.className
    }
}
