import Foundation

/**
  `PFFileObject` representes a file of binary data stored on the Parse servers.
  This can be a image, video, or anything else that an application needs to reference in a non-relational way.
 */
public struct File: Saveable, Fetchable {

    private let __type: String = "File" // swiftlint:disable:this identifier_name
    
    /**
      The name of the file.
      Before the file is saved, this is the filename given by
      the user. After the file is saved, that name gets prefixed with a unique
      identifier.
     */
    public var name: String?

    /**
      Creates a file with given data and content type.
      @param data The contents of the new `PFFileObject`.
      @param contentType Represents MIME type of the data.
      @return A new `PFFileObject` object.
     */
    public var data: Data?
    
    /**
     The url of the file.
     */
    public var url: URL?

    /**
      Creates a file with given data. A name will be assigned to it by the server.
      @param data The contents of the new `PFFileObject`.
      @return A new `PFFileObject`.
     */
    public init(data: Data) {
        self.data = data
        self.url = nil
    }

    public init(url: URL) {
        self.data = nil
        self.url = url
    }

    internal init(data: Data?, url: URL?) {
        self.data = data
        self.url = url
    }

    public func save(options: API.Options) throws -> File {
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
        case name
        case __type // swiftlint:disable:this identifier_name
    }
}
