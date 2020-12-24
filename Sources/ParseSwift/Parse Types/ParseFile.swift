import Foundation

/**
  A `ParseFile` object representes a file of binary data stored on the Parse server.
  This can be a image, video, or anything else that an application needs to reference in a non-relational way.
 */
public struct ParseFile: Saveable, Fetchable {

    private let __type: String = "File" // swiftlint:disable:this identifier_name

    /**
      The name of the file.
      Before the file is saved, this is the filename given by the user.
      After the file is saved, that name gets prefixed with a unique identifier.
     */
    public internal(set) var name: String

    /**
     The Parse Server url of the file.
     */
    public internal(set) var url: URL?

    /**
     The local file path.
     */
    public var localURL: URL?

    /**
     The link to the file online that should be downloaded.
     */
    public var cloudURL: URL?

    /**
     The contents of the file.
     */
    public var data: Data?

    /// The Content-Type header to use for the file.
    public var mimeType: String?

    /// Key value pairs to be stored with file object
    public var metadata: [String: String]?

    /// Key value pairs to be stored with file object
    public var tags: [String: String]?

    /**
     Creates a file with given data and name.
     - parameter name: The name of the new `ParseFile`. The file name must begin with and
     alphanumeric character, and consist of alphanumeric characters, periods, spaces, underscores,
     or dashes. The default value is "file".
     - parameter data: The contents of the new `ParseFile`.
     - parameter mimeType: Specify the Content-Type header to use for the file,  for example
     "application/pdf". The default is nil. If no value is specified the file type will be inferred from the file
     extention of `name`.
     - parameter metadata: Optional key value pairs to be stored with file object
     - parameter tags: Optional key value pairs to be stored with file object
     */
    public init(name: String = "file", data: Data, mimeType: String? = nil,
                metadata: [String: String]? = nil, tags: [String: String]? = nil) {
        self.name = name
        self.data = data
        self.mimeType = mimeType
        self.metadata = metadata
        self.tags = tags
    }

    /**
     Creates a file from a local file path and name.
     - parameter name: The name of the new `ParseFile`. The file name must begin with and
     alphanumeric character, and consist of alphanumeric characters, periods, spaces, underscores,
     or dashes. The default value is "file".
     - parameter localURL: The local file path of the`ParseFile`.
     - parameter mimeType: Specify the Content-Type header to use for the file,  for example
     "application/pdf". The default is nil. If no value is specified the file type will be inferred from the file
     extention of `name`.
     - parameter metadata: Optional key value pairs to be stored with file object
     - parameter tags: Optional key value pairs to be stored with file object
     */
    public init(name: String = "file", localURL: String, metadata: [String: String]? = nil, tags: [String: String]? = nil) {
        self.name = name
        self.localURL = URL(string: localURL)
        self.metadata = metadata
        self.tags = tags
    }

    /**
     Creates a file from a link online and name.
     - parameter name: The name of the new `ParseFile`. The file name must begin with and
     alphanumeric character, and consist of alphanumeric characters, periods, spaces, underscores,
     or dashes. The default value is "file".
     - parameter cloudURL: The online link of the`ParseFile`.
     - parameter mimeType: Specify the Content-Type header to use for the file,  for example
     "application/pdf". The default is nil. If no value is specified the file type will be inferred from the file
     extention of `name`.
     - parameter metadata: Optional key value pairs to be stored with file object
     - parameter tags: Optional key value pairs to be stored with file object
     */
    public init(name: String = "file", cloudURL: String, metadata: [String: String]? = nil, tags: [String: String]? = nil) {
        self.name = name
        self.cloudURL = URL(string: cloudURL)
        self.metadata = metadata
        self.tags = tags
    }

    /*
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
    }*/

    enum CodingKeys: String, CodingKey {
        case url
        //case data
        case name
        case __type // swiftlint:disable:this identifier_name
    }
}

// MARK: Saving
extension ParseFile {
    /**
     Creates a file with given data. A name will be assigned to it by the server.
     - parameter options: A set of options used to save files. Defaults to an empty set.
     - returns: A saved `ParseFile`.
     */
    public func save(options: API.Options) throws -> Self {
        try upload(options: options)
    }

    /**
     
     - parameter options: A set of options used to save files. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it's progress.
    */
    public func save(options: API.Options, progress: ((Int64, Int64, Int64) -> Void)?) throws -> Self {
        try upload(options: options, progress: progress)
    }

    /**
     
     - parameter options: A set of options used to save files. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter progress: A block that will be called when file updates it's progress.
     - parameter completion: A block that will be called when file saves or fails.
    */
    public func save(options: API.Options,
                     progress: ((Int64, Int64, Int64) -> Void)? = nil,
                     completion: @escaping (Result<Self, ParseError>) -> Void) {
        upload(options: options, progress: progress, completion: completion)
    }
}

// MARK: Saving
extension ParseFile {
    public func fetch(options: API.Options) -> ParseFile {
        fatalError()
    }
}

// MARK: Uploading
extension ParseFile {

    internal func upload(options: API.Options = [],
                         progress: ((Int64, Int64, Int64) -> Void)? = nil) throws -> ParseFile {
        var options = options
        if let mimeType = mimeType {
            options.insert(.mimeType(mimeType))
        } else {
            options.insert(.removeMimeType)
        }
        if let metadata = metadata {
            options.insert(.metadata(metadata))
        }
        if let tags = tags {
            options.insert(.tags(tags))
        }
        return try uploadCommand().execute(options: options, progress: progress)
    }

    internal func upload(options: API.Options = [],
                         callbackQueue: DispatchQueue = .main,
                         progress: ((Int64, Int64, Int64) -> Void)? = nil,
                         completion: @escaping (Result<Self, ParseError>) -> Void) {
        var options = options
        if let mimeType = mimeType {
            options.insert(.mimeType(mimeType))
        } else {
            options.insert(.removeMimeType)
        }
        if let metadata = metadata {
            options.insert(.metadata(metadata))
        }
        if let tags = tags {
            options.insert(.tags(tags))
        }
        uploadCommand().executeAsync(options: options,
                                     callbackQueue: callbackQueue,
                                     progress: progress, completion: completion)
    }

    internal func uploadCommand() -> API.Command<Self, Self> {
        return API.Command<Self, Self>.uploadCommand(self)
    }
}
