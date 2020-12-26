import Foundation

/**
  A `ParseFile` object representes a file of binary data stored on the Parse server.
  This can be a image, video, or anything else that an application needs to reference in a non-relational way.
 */
public struct ParseFile: Saveable, Fetchable, Deletable {

    private let __type: String = "File" // swiftlint:disable:this identifier_name

    internal var isSaved: Bool {
        return url != nil
    }

    internal var isDownloadNeeded: Bool {
        return cloudURL != nil
            && url == nil
            && localURL == nil
            && data == nil
            && stream == nil
    }

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
     The stream for the file.
     */
    public var stream: InputStream?

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
    public init(name: String = "file", localURL: URL,
                metadata: [String: String]? = nil, tags: [String: String]? = nil) {
        self.name = name
        self.localURL = localURL
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
    public init(name: String = "file", cloudURL: URL,
                metadata: [String: String]? = nil, tags: [String: String]? = nil) {
        self.name = name
        self.cloudURL = cloudURL
        self.metadata = metadata
        self.tags = tags
    }

    /**
     Creates a file from a stream and name.
     - parameter name: The name of the new `ParseFile`. The file name must begin with and
     alphanumeric character, and consist of alphanumeric characters, periods, spaces, underscores,
     or dashes. The default value is "file".
     - parameter stream: The stream of the`ParseFile`.
     - parameter mimeType: Specify the Content-Type header to use for the file,  for example
     "application/pdf". The default is nil. If no value is specified the file type will be inferred from the file
     extention of `name`.
     - parameter metadata: Optional key value pairs to be stored with file object
     - parameter tags: Optional key value pairs to be stored with file object
     */
    public init(name: String = "file", stream: InputStream,
                metadata: [String: String]? = nil, tags: [String: String]? = nil) {
        self.name = name
        self.stream = stream
        self.metadata = metadata
        self.tags = tags
    }

    enum CodingKeys: String, CodingKey {
        case url
        case name
        case __type // swiftlint:disable:this identifier_name
    }
}

// MARK: Deleting
extension ParseFile {
    /**
     Deletes the file from the Parse cloud.
     - warning: Requires the masterKey be passed as one of the set of `options`.
     - parameter options: A set of options used to delete files.
     - throws: A `ParseError` if there was an issue deleting the file. Otherwise it was successful.
     */
    public func delete(options: API.Options) throws {
        if !options.contains(.useMasterKey) {
            throw ParseError(code: .unknownError,
                             message: "You must specify \"useMasterKey\" in \"options\" in order to delete a file.")
        }
        _ = try deleteFileCommand().execute(options: options)
    }

    /**
     Deletes the file from the Parse cloud.
     - warning: Requires the masterKey be passed as one of the set of `options`.
     - parameter options: A set of options used to delete files.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when file deletes or fails.
     */
    public func delete(options: API.Options,
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping (ParseError?) -> Void) {
        if !options.contains(.useMasterKey) {
            completion(ParseError(code: .unknownError,
                                  // swiftlint:disable:next line_length
                                  message: "You must specify \"useMasterKey\" in \"options\" in order to delete a file."))
            return
        }
        deleteFileCommand().executeAsync(options: options,
                                         callbackQueue: callbackQueue) { result in
            switch result {

            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    internal func deleteFileCommand() -> API.Command<Self, NoBody> {
        return API.Command<Self, NoBody>.deleteFileCommand(self)
    }
}

// MARK: Saving
extension ParseFile {
    /**
     Creates a file with given stream *synchronously*. A name will be assigned to it by the server.
     - parameter options: A set of options used to save files. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it's progress.
     - parameter stream: An input file stream.
     - returns: A saved `ParseFile`.
     */
    public mutating func save(options: API.Options = [],
                              progress: ((Int64, Int64, Int64) -> Void)? = nil,
                              stream: InputStream?) throws {
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

        if let stream = stream {
            self.stream = stream
            return try uploadFileCommand().executeStream(options: options, progress: progress, stream: stream)
        } else if let stream = self.stream {
            return try uploadFileCommand().executeStream(options: options, progress: progress, stream: stream)
        } else {
            throw ParseError(code: .unknownError, message: "a file stream is required")
        }
    }

    /**
     Creates a file with given data *synchronously*. A name will be assigned to it by the server.
     If the file hasn't been downloaded, it will automatically be downloaded before saved.
     - parameter options: A set of options used to save files. Defaults to an empty set.
     - returns: A saved `ParseFile`.
     */
    public func save(options: API.Options = []) throws -> ParseFile {
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
        if isDownloadNeeded {
            let fetched = try fetch(options: options)
            return try fetched.uploadFileCommand().execute(options: options)
        }
        return try uploadFileCommand().execute(options: options)
    }

    /**
     Creates a file with given data *synchronously*. A name will be assigned to it by the server.
     If the file hasn't been downloaded, it will automatically be downloaded before saved.
     - parameter options: A set of options used to save files. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it's progress.
     - returns: A saved `ParseFile`.
     */
    public func save(options: API.Options = [],
                     progress: ((Int64, Int64, Int64) -> Void)?) throws -> ParseFile {
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
        if isDownloadNeeded {
            let fetched = try fetch(options: options)
            return try fetched.uploadFileCommand().execute(options: options, progress: progress)
        }
        return try uploadFileCommand().execute(options: options, progress: progress)
    }

    /**
     Creates a file with given data *asynchronously* and executes the given callback block.
     A name will be assigned to it by the server. If the file hasn't been downloaded, it will automatically
     be downloaded before saved.
     - parameter options: A set of options used to save files. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter progress: A block that will be called when file updates it's progress.
     - parameter completion: A block that will be called when file saves or fails.
    */
    public func save(options: API.Options = [],
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
        if isDownloadNeeded {
            fetch(options: options) { result in
                switch result {

                case .success(let fetched):
                    fetched.uploadFileCommand()
                        .executeAsync(options: options,
                                      callbackQueue: callbackQueue,
                                      progress: progress, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            uploadFileCommand()
                .executeAsync(options: options,
                              callbackQueue: callbackQueue,
                              progress: progress, completion: completion)
        }

    }

    internal func uploadFileCommand() -> API.Command<Self, Self> {
        return API.Command<Self, Self>.uploadFileCommand(self)
    }
}

// MARK: Downloading
extension ParseFile {
    /**
     Fetches a file with given url *synchronously*.
     - parameter options: A set of options used to fetch the file. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it's progress.
     - parameter stream: An input file stream.
     - returns: A saved `ParseFile`.
     */
    public func fetch(options: API.Options = [],
                      progress: ((Int64, Int64, Int64) -> Void)? = nil,
                      stream: InputStream) throws {
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
        return try downloadFileCommand().executeStream(options: options, progress: progress, stream: stream)
    }

    /**
     Fetches a file with given url *synchronously*.
     - parameter options: A set of options used to fetch the file. Defaults to an empty set.
     - returns: A saved `ParseFile`.
     */
    public func fetch(options: API.Options = []) throws -> ParseFile {
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
        return try downloadFileCommand().execute(options: options)
    }

    /**
     Fetches a file with given url *synchronously*.
     - parameter options: A set of options used to fetch the file. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it's progress.
     - returns: A saved `ParseFile`.
     */
    public func fetch(options: API.Options = [],
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
        return try downloadFileCommand().execute(options: options, progress: progress)
    }

    /**
     Fetches a file with given url *asynchronously*.
     - parameter options: A set of options used to fetch the file. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter progress: A block that will be called when file updates it's progress.
     - parameter completion: A block that will be called when file fetches or fails.
    */
    public func fetch(options: API.Options = [],
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
        downloadFileCommand().executeAsync(options: options,
                                     callbackQueue: callbackQueue,
                                     progress: progress, completion: completion)
    }

    internal func downloadFileCommand() -> API.Command<Self, Self> {
        return API.Command<Self, Self>.downloadFileCommand(self)
    }
} // swiftlint:disable:this file_length
