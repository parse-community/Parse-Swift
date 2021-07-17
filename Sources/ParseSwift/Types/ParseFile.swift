import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
  A `ParseFile` object representes a file of binary data stored on the Parse server.
  This can be a image, video, or anything else that an application needs to reference in a non-relational way.
 */
public struct ParseFile: Fileable, Savable, Fetchable, Deletable, Hashable {

    internal let __type: String = "File" // swiftlint:disable:this identifier_name

    internal var isDownloadNeeded: Bool {
        return cloudURL != nil
            && url == nil
            && localURL == nil
            && data == nil
    }

    public var localId: UUID

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
     The link to the file online that should be fetched before uploading to the Parse Server.
     */
    public var cloudURL: URL?

    /**
     The contents of the file.
     */
    public var data: Data?

    /// The Content-Type header to use for the file.
    public var mimeType: String?

    /// Key value pairs to be stored with the file object.
    public var metadata: [String: String]?

    /// Key value pairs to be stored with the file object.
    public var tags: [String: String]?

    /// A set of header options sent to the server.
    public var options: API.Options = []

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
     - note: `metadata` and `tags` is file adapter specific and not supported by all file adapters.
     For more, see details on the
     [S3 adapter](https://github.com/parse-community/parse-server-s3-adapter#adding-metadata-and-tags)
     */
    public init(name: String = "file", data: Data, mimeType: String? = nil,
                metadata: [String: String]? = nil, tags: [String: String]? = nil,
                options: API.Options = []) {
        self.name = name
        self.data = data
        self.mimeType = mimeType
        self.metadata = metadata
        self.tags = tags
        self.options = options
        self.localId = UUID()
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
     - parameter metadata: Optional key value pairs to be stored with file object.
     - parameter tags: Optional key value pairs to be stored with file object.
     - note: `metadata` and `tags` is file adapter specific and not supported by all file adapters.
     For more, see details on the
     [S3 adapter](https://github.com/parse-community/parse-server-s3-adapter#adding-metadata-and-tags).
     */
    public init(name: String = "file", localURL: URL,
                metadata: [String: String]? = nil, tags: [String: String]? = nil,
                options: API.Options = []) {
        self.name = name
        self.localURL = localURL
        self.metadata = metadata
        self.tags = tags
        self.options = options
        self.localId = UUID()
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
     - parameter metadata: Optional key value pairs to be stored with file object.
     - parameter tags: Optional key value pairs to be stored with file object.
     - note: `metadata` and `tags` is file adapter specific and not supported by all file adapters.
     For more, see details on the
     [S3 adapter](https://github.com/parse-community/parse-server-s3-adapter#adding-metadata-and-tags).
     */
    public init(name: String = "file", cloudURL: URL,
                metadata: [String: String]? = nil, tags: [String: String]? = nil,
                options: API.Options = []) {
        self.name = name
        self.cloudURL = cloudURL
        self.metadata = metadata
        self.tags = tags
        self.options = options
        self.localId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case url
        case name
        case __type // swiftlint:disable:this identifier_name
    }
}

extension ParseFile {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        url = try values.decode(URL.self, forKey: .url)
        name = try values.decode(String.self, forKey: .name)
        localId = UUID()
    }
}

// MARK: Deleting
extension ParseFile {
    /**
     Deletes the file from the Parse cloud.
     - requires: `.useMasterKey` has to be available.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: A `ParseError` if there was an issue deleting the file. Otherwise it was successful.
     */
    public func delete(options: API.Options) throws {
        var options = options
        options.insert(.useMasterKey)
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        options = options.union(self.options)

        _ = try deleteFileCommand().execute(options: options, callbackQueue: .main)
    }

    /**
     Deletes the file from the Parse cloud. Completes with `nil` if successful.
     - requires: `.useMasterKey` has to be available.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when file deletes or fails.
     It should have the following argument signature: `(Result<Void, ParseError>)`
     */
    public func delete(options: API.Options,
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Void, ParseError>) -> Void) {
        var options = options
        options.insert(.useMasterKey)
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        options = options.union(self.options)

        deleteFileCommand().executeAsync(options: options, callbackQueue: callbackQueue) { result in
            callbackQueue.async {
                switch result {

                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
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
     
    **Checking progress**
             
          guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
            return
          }

          let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
          let fetchedFile = try parseFile.fetch(stream: InputStream(fileAtPath: URL("parse.org")!) {
          (_, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            print(currentProgess)
          }
     
    **Cancelling**
              
           guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
             return
           }

           let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
           let fetchedFile = try parseFile.fetch(stream: InputStream(fileAtPath: URL("parse.org")!){
           (task, _, totalWritten, totalExpected) in
             let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
             //Cancel when data exceeds 10%
             if currentProgess > 10 {
               task.cancel()
               print("task has been cancelled")
             }
             print(currentProgess)
           }
      
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it's progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - parameter stream: An input file stream.
     - returns: A saved `ParseFile`.
     */
    public func save(options: API.Options = [],
                     stream: InputStream,
                     progress: ((URLSessionTask, Int64, Int64, Int64) -> Void)? = nil) throws {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
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
        options = options.union(self.options)
        return try uploadFileCommand()
            .executeStream(options: options,
                           callbackQueue: .main,
                           uploadProgress: progress,
                           stream: stream)
    }

    /**
     Creates a file with given data *synchronously*. A name will be assigned to it by the server.
     If the file hasn't been downloaded, it will automatically be downloaded before saved.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A saved `ParseFile`.
     */
    public func save(options: API.Options = []) throws -> ParseFile {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
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
        options = options.union(self.options)
        if isDownloadNeeded {
            let fetched = try fetch(options: options)
            return try fetched.uploadFileCommand().execute(options: options, callbackQueue: .main)
        }
        return try uploadFileCommand().execute(options: options, callbackQueue: .main)
    }

    /**
     Creates a file with given data *synchronously*. A name will be assigned to it by the server.
     If the file hasn't been downloaded, it will automatically be downloaded before saved.
     
    **Checking progress**
             
          guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
            return
          }

          let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
          let fetchedFile = try parseFile.save { (_, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            print(currentProgess)
          }
     
    **Cancelling**
              
           guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
             return
           }

           let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
           let fetchedFile = try parseFile.save { (task, _, totalWritten, totalExpected) in
             let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
             //Cancel when data exceeds 10%
             if currentProgess > 10 {
               task.cancel()
               print("task has been cancelled")
             }
             print(currentProgess)
           }
      
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it's progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - returns: A saved `ParseFile`.
     */
    public func save(options: API.Options = [],
                     progress: ((URLSessionTask, Int64, Int64, Int64) -> Void)?) throws -> ParseFile {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
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
        options = options.union(self.options)
        if isDownloadNeeded {
            let fetched = try fetch(options: options)
            return try fetched
                .uploadFileCommand()
                .execute(options: options,
                         callbackQueue: .main,
                         uploadProgress: progress)
        }
        return try uploadFileCommand().execute(options: options, callbackQueue: .main, uploadProgress: progress)
    }

    /**
     Creates a file with given data *asynchronously* and executes the given callback block.
     A name will be assigned to it by the server. If the file hasn't been downloaded, it will automatically
     be downloaded before saved.
    
    **Checking progress**
             
          guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
            return
          }

          let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
          let fetchedFile = try parseFile.save { (_, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            print(currentProgess)
          }
     
    **Cancelling**
              
           guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
             return
           }

           let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
           let fetchedFile = try parseFile.save(progress: {(task, _, totalWritten, totalExpected)-> Void in
               let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
                 //Cancel when data exceeds 10%
                 if currentProgess > 10 {
                   task.cancel()
                   print("task has been cancelled")
                 }
                 print(currentProgess)
               }) { result in
                 ...
           })
      
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter progress: A block that will be called when file updates it's progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - parameter completion: A block that will be called when file saves or fails.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func save(options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     progress: ((URLSessionTask, Int64, Int64, Int64) -> Void)? = nil,
                     completion: @escaping (Result<Self, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
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
        options = options.union(self.options)
        if isDownloadNeeded {
            fetch(options: options) { result in
                switch result {

                case .success(let fetched):
                    do {
                        try fetched.uploadFileCommand()
                            .executeAsync(options: options,
                                      callbackQueue: callbackQueue,
                                      uploadProgress: progress) { result in
                                callbackQueue.async {
                                    completion(result)
                                }
                            }
                    } catch {
                        callbackQueue.async {
                            if let parseError = error as? ParseError {
                                completion(.failure(parseError))
                            } else {
                                let parseError = ParseError(code: .unknownError, message: error.localizedDescription)
                                completion(.failure(parseError))
                            }
                        }
                    }
                case .failure(let error):
                    callbackQueue.async {
                        completion(.failure(error))
                    }
                }
            }
        } else {
            do {
                try uploadFileCommand()
                    .executeAsync(options: options,
                                  callbackQueue: callbackQueue,
                                  uploadProgress: progress) { result in
                        callbackQueue.async {
                            completion(result)
                        }
                    }
            } catch {
                callbackQueue.async {
                    if let parseError = error as? ParseError {
                        completion(.failure(parseError))
                    } else {
                        let parseError = ParseError(code: .unknownError, message: error.localizedDescription)
                        completion(.failure(parseError))
                    }
                }
            }
        }

    }

    internal func uploadFileCommand() throws -> API.Command<Self, Self> {
        try API.Command<Self, Self>.uploadFileCommand(self)
    }
}

// MARK: Fetching
extension ParseFile {
    /**
     Fetches a file with given url *synchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter stream: An input file stream.
     - returns: A saved `ParseFile`.
     */
    public func fetch(options: API.Options = [],
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
        options = options.union(self.options)
        return try downloadFileCommand()
            .executeStream(options: options,
                           callbackQueue: .main,
                           stream: stream)
    }

    /**
     Fetches a file with given url *synchronously*.
     - parameter includeKeys: Currently not used for `ParseFile`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A saved `ParseFile`.
     */
    public func fetch(includeKeys: [String]? = nil, options: API.Options = []) throws -> ParseFile {
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
        options = options.union(self.options)
        return try downloadFileCommand()
            .execute(options: options,
                     callbackQueue: .main)
    }

    /**
     Fetches a file with given url *synchronously*.
     
    **Checking progress**
            
         guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
           return
         }

         let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
         let fetchedFile = try parseFile.fetch { (_, _, totalDownloaded, totalExpected) in
           let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
           print(currentProgess)
         }
    
    **Cancelling**
             
          guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
            return
          }

          let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
          let fetchedFile = try parseFile.fetch { (task, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            //Cancel when data exceeds 10%
            if currentProgess > 10 {
              task.cancel()
              print("task has been cancelled")
            }
            print(currentProgess)
          }
     
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it's progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - returns: A saved `ParseFile`.
     */
    public func fetch(options: API.Options = [],
                      progress: @escaping ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)) throws -> ParseFile {
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
        options = options.union(self.options)
        return try downloadFileCommand()
            .execute(options: options,
                     callbackQueue: .main,
                     downloadProgress: progress)
    }

    /**
     Fetches a file with given url *asynchronously*.
     
    **Checking progress**
             
          guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
            return
          }

          let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
          let fetchedFile = try parseFile.fetch { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            print(currentProgess)
          }
     
    **Cancelling**
              
           guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
             return
           }

           let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
           let fetchedFile = try parseFile.fetch(progress: {(task, _, totalDownloaded, totalExpected)-> Void in
             let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
             //Cancel when data exceeds 10%
             if currentProgess > 10 {
               task.cancel()
               print("task has been cancelled")
             }
             print(currentProgess)
           }) { result in
             ...
           }
      
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter progress: A block that will be called when file updates it's progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - parameter completion: A block that will be called when file fetches or fails.
     It should have the following argument signature: `(Result<Self, ParseError>)`
    */
    public func fetch(options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      progress: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)? = nil,
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
        options = options.union(self.options)
        downloadFileCommand()
            .executeAsync(options: options,
                          callbackQueue: callbackQueue,
                          downloadProgress: progress) { result in
            callbackQueue.async {
                completion(result)
            }
        }
    }

    internal func downloadFileCommand() -> API.Command<Self, Self> {
        return API.Command<Self, Self>.downloadFileCommand(self)
    }
}

// MARK: CustomDebugStringConvertible
extension ParseFile: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
            return "ParseFile ()"
        }
        return "ParseFile (\(descriptionString))"
    }
}

// MARK: CustomStringConvertible
extension ParseFile: CustomStringConvertible {
    public var description: String {
        debugDescription
    }
} // swiftlint:disable:this file_length
