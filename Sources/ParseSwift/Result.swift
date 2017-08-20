import Foundation

public enum Result<T> {
    case success(T)
    case error(Error)
    case unknown

    public init(_ response: T?, _ error: Error?) {
        if let error = error {
            self = .error(error)
        } else if let response = response {
            self = .success(response)
        } else {
            self = .unknown
        }
    }

    func map<U>(_ transform: (T) throws -> U) -> Result<U> {
        switch self {
        case .success(let success):
            do {
                return .success(try transform(success))
            } catch let e {
                return .error(e)
            }
        case .error(let error):
            return .error(error)
        default: return .unknown
        }
    }

    public func flatMap<U>(_ transform: (T) throws -> Result<U>) rethrows -> Result<U> {
        switch self {
        case .success(let success):
            do {
                return try transform(success)
            } catch let e {
                return .error(e)
            }
        case .error(let error):
            return .error(error)
        default: return .unknown
        }
    }
}

extension Result where T == Data {
    func decode<U>() -> Result<U> where U: Decodable {
        return map { data -> U in
            return try getDecoder().decode(U.self, from: data)
        }
    }

    func map<U>(_ mapper: (T) throws -> U) -> Result<U> {
        switch self {
        case .success(let data):
            do {
                return .success(try mapper(data))
            } catch let e {
                do { // try default error mapper :)
                    return .error(try getDecoder().decode(ParseError.self, from: data))
                } catch {}
                return .error(e)
            }
        case .error(let error):
            return .error(error)
        default: return .unknown
        }
    }
}
