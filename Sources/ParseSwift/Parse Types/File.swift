import Foundation

/**
  A `File` object representes a file of binary data stored on the Parse server.
  This can be a image, video, or anything else that an application needs to reference in a non-relational way.
 */
public struct File: Saveable, Fetchable {

    private let __type: String = "File" // swiftlint:disable:this identifier_name

    /**
      The name of the file.
      Before the file is saved, this is the filename given by the user.
      After the file is saved, that name gets prefixed with a unique identifier.
     */
    public var name: String

    /**
     The contents of the file.
     */
    public var data: Data?

    /**
     The url of the file.
     */
    public var url: URL?

    public var mimeType: String?
/*
    internal init(data: Data?, urlString: String?) {
        self.data = data
        self.urlString = urlString
    }
*/
    /**
     Creates a file with given data and name.
     @param name The name of the new PFFileObject. The file name must begin with and
     alphanumeric character, and consist of alphanumeric characters, periods,
     spaces, underscores, or dashes.
     @param data The contents of the new `PFFileObject`.
     @return A new `PFFileObject` object.
     */
  /*  public init(name: String, data: Data?) {
        self.init(data: data, urlString: nil)
    }
*/
    internal init(name: String = "file", urlString: String, mimeType: String) {
        self.name = name
        self.url = URL(string: urlString)
        self.mimeType = mimeType
    }

    /**
     Creates a file with given data. A name will be assigned to it by the server.
     @param data The contents of the new `PFFileObject`.
     @return A new `PFFileObject`.
     */
/*    public init(data: Data?) {
        self.init(data: data, urlString: nil)
    }
  */
    /*private var url: URL? {
        get {
            guard let urlString = urlString,
                  let url = URLComponents(string: urlString)?.url else {
                return nil
            }
            
            return url
        }
    }*/

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

// MARK: Uploading
extension File {

    /**
    Logs out the currently logged in user in Keychain *synchronously*.
    */
    public func upload() throws {
        _ = try uploadCommand().execute(options: [])
    }

    /**
     Logs out the currently logged in user *asynchronously*.

     This will also remove the session from the Keychain, log out of linked services
     and all future calls to `current` will return `nil`. This is preferable to using `logout`,
     unless your code is already running from a background thread.

     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when logging out, completes or fails.
    */
    public func upload(callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Bool, ParseError>) -> Void) {
        uploadCommand().executeAsync(options: [], callbackQueue: callbackQueue) { result in
            completion(result.map { true })
        }
    }

    private func uploadCommand() -> API.Command<NoBody, Void> {
        return API.Command(method: .POST, path: .file(fileName: name)) { (_) -> Void in

        }
    }
}
