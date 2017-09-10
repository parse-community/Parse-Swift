//
//  ParseObjectType.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public protocol ObjectType: Fetching, Saving, CustomDebugStringConvertible, Equatable {
    static var className: String { get }

    var objectId: String? { get set }
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
    var ACL: ACL? { get set }
}

extension ObjectType {
    // Parse ClassName inference
    public static var className: String {
        let t = "\(type(of: self))"
        return t.components(separatedBy: ".").first! // strip .Type
    }

    public var className: String {
        return Self.className
    }

    var endpoint: API.Endpoint {
        if let objectId = objectId {
            return .object(className: className, objectId: objectId)
        }
        return .objects(className: className)
    }

    var isSaved: Bool {
        return objectId != nil
    }
}

extension ObjectType {
    func getEncoder() -> ParseEncoder {
        return getParseEncoder()
    }

    func toPointer() -> Pointer<Self> {
        return Pointer(self)
    }
}

extension ObjectType {
    public var debugDescription: String {
        guard let descriptionData = try? getJSONEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "\(className) ()"
        }
        return "\(className) (\(descriptionString))"
    }
}

public extension ObjectType {
    public func save(options: API.Option, callback: ((Self?, Error?) -> Void)? = nil) -> Cancellable {
        let requestMethod: API.Method = isSaved ? .put : .post

        return endpoint.makeRequest(method: requestMethod) {(data, error) in
            if let data = data {
                do {
                    var object: Self!

                    if self.isSaved {
                        object = try getDecoder().decode(UpdateResponse.self, from: data).apply(self)
                    } else {
                        object = try getDecoder().decode(SaveResponse.self, from: data).apply(self)
                    }

                    callback?(object, nil)
                } catch {
                    callback?(nil, error)
                }
            } else if let error = error {
                callback?(nil, error)
            } else {
                callback?(nil, ParseError.unknownResult())
            }
        }
    }
}

public extension ObjectType {
    public func fetch(options: API.Option, callback: ((Self?, Error?) -> Void)? = nil) -> Cancellable? {
        guard isSaved else {
            let error = ParseError(code: -1, error: "Cannot Fetch an object without id")
            callback?(nil, error)
            return nil
        }

        return endpoint.makeRequest(method: .get) {(data, error) in
            if let data = data {
                do {
                    let object = try getDecoder().decode(UpdateResponse.self, from: data).apply(self)
                    callback?(object, nil)
                } catch {
                    callback?(nil, error)
                }
            } else if let error = error {
                callback?(nil, error)
            } else {
                callback?(nil, ParseError.unknownResult())
            }
        }
    }
}

public struct FindResult<T>: Decodable where T: ObjectType {
    let results: [T]
    let count: Int?
}

public extension ObjectType {
    var mutationContainer: ParseMutationContainer<Self> {
        return ParseMutationContainer(target: self)
    }
}
