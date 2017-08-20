import Foundation

public struct File: Saving, Fetching {
    private let __type: String = "File"
    public var data: Data?
    public var url: URL?

    public init(data: Data?, url: URL?) {
        self.data = data
        self.url = url
    }

    public func save(callback: ((Result<File>) -> ())? = nil) -> Cancellable {
        // upload file
        // store in server
        // callback with the data
        fatalError()
    }

    public func encode(to encoder: Encoder) throws {
        if data == nil && url == nil {
            throw NSError(domain: "cannot encode file", code: -1, userInfo: nil)
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let url = url {
            try container.encode(__type, forKey: .__type)
            try container.encode(url.absoluteString, forKey: .url)
        }
        if let data = data {
            try container.encode(__type, forKey: .__type)
            try container.encode(data, forKey: .data)
        }
    }

    public func fetch(callback: ((Result<File>) -> ())? = nil) -> Cancellable? {
        fatalError()
    }

    enum CodingKeys: String, CodingKey {
        case url
        case data
        case __type
    }
}
