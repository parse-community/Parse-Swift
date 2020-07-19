import Foundation

public struct File: Saving, Fetching {

    private let __type: String = "File" // swiftlint:disable:this identifier_name
    public var data: Data?
    public var url: URL?

    public init(data: Data?, url: URL?) {
        self.data = data
        self.url = url
    }

    public func save(options: API.Options) -> File {
        // upload file
        // store in server
        // callback with the data
        fatalError()
    }

    public func encode(to encoder: Encoder) throws {
        if data == nil && url == nil {
            throw ParseError(code: .unknownError, message: "cannot encode file")
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

    public func fetch(options: API.Options) -> File {
        fatalError()
    }

    enum CodingKeys: String, CodingKey {
        case url
        case data
        case __type // swiftlint:disable:this identifier_name
    }
}
