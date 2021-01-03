import Foundation

/**
 Objects that conform to the `ParseUser` protocol have a local representation of a user persisted to the Parse Data.
 This protocol inherits from the `ParseObject` protocol, and retains the same functionality of a `ParseObject`,
 but also extends it with various user specific methods, like authentication, signing up, and validation uniqueness.
*/
public protocol ParseUser: ParseObject {
    /**
    The username for the `ParseUser`.
    */
    var username: String? { get set }

    /**
    The email for the `ParseUser`.
    */
    var email: String? { get set }

    /**
     The password for the `ParseUser`.

     This will not be filled in from the server with the password.
     It is only meant to be set.
    */
    var password: String? { get set }
}

// MARK: SignupBody
struct SignupBody: Encodable {
    let username: String
    let password: String
}

// MARK: EmailBody
struct EmailBody: Encodable {
    let email: String
}

// MARK: Default Implementations
public extension ParseUser {
    static var className: String {
        return "_User"
    }
}

// MARK: Convenience
extension ParseUser {
    var endpoint: API.Endpoint {
        if let objectId = objectId {
            return .user(objectId: objectId)
        }

        return .users
    }
}

// MARK: CurrentUserContainer
struct CurrentUserContainer<T: ParseUser>: Codable {
    var currentUser: T?
    var sessionToken: String?
}

// MARK: Current User Support
extension ParseUser {
    static var currentUserContainer: CurrentUserContainer<Self>? {
        get {
            guard let currentUserInMemory: CurrentUserContainer<Self>
                = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                return try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
            }
            return currentUserInMemory
        }
        set { try? ParseStorage.shared.set(newValue, for: ParseStorage.Keys.currentUser) }
    }

    internal static func saveCurrentContainerToKeychain() {
        //Only save the BaseParseUser to keep Keychain footprint finite
        guard let currentUserInMemory: CurrentUserContainer<BaseParseUser>
            = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
            return
        }
        try? KeychainStore.shared.set(currentUserInMemory, for: ParseStorage.Keys.currentUser)
    }

    internal static func deleteCurrentContainerFromKeychain() {
        try? ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentUser)
        try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentUser)
    }

    /**
     Gets the currently logged in user from the Keychain and returns an instance of it.

     - returns: Returns a `ParseUser` that is the currently logged in user. If there is none, returns `nil`.
     - warning: Only use `current` users on the main thread as as modifications to `current` have to be unique.
    */
    public static var current: Self? {
        get { Self.currentUserContainer?.currentUser }
        set { Self.currentUserContainer?.currentUser = newValue }
    }

    /**
     The session token for the `ParseUser`.

     This is set by the server upon successful authentication.
    */
    public var sessionToken: String? {
        Self.currentUserContainer?.sessionToken
    }
}

// MARK: Logging In
extension ParseUser {

    /**
     Makes a *synchronous* request to login a user with specified credentials.

     Returns an instance of the successfully logged in `ParseUser`.
     This also caches the user locally so that calls to `+current` will use the latest logged in user.

     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter error: The error object to set on error.

     - throws: An error of type `ParseUser`.
     - returns: An instance of the logged in `ParseUser`.
     If login failed due to either an incorrect password or incorrect username, it throws a `ParseError`.
    */
    public static func login(username: String,
                             password: String, options: API.Options = []) throws -> Self {
        try loginCommand(username: username, password: password).execute(options: options)
    }

    /**
     Makes an *asynchronous* request to log in a user with specified credentials.
     Returns an instance of the successfully logged in `ParseUser`.

     This also caches the user locally so that calls to `+current` will use the latest logged in user.
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public static func login(
        username: String,
        password: String,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        loginCommand(username: username, password: password)
            .executeAsync(options: options, callbackQueue: callbackQueue, completion: completion)
    }

    internal static func loginCommand(username: String,
                                      password: String) -> API.NonParseBodyCommand<NoBody, Self> {
        let params = [
            "username": username,
            "password": password
        ]

        return API.NonParseBodyCommand<NoBody, Self>(method: .GET,
                                         path: .login,
                                         params: params) { (data) -> Self in
            let response = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: data)
            var user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)
            user.username = username
            user.password = password

            Self.currentUserContainer = .init(
                currentUser: user,
                sessionToken: response.sessionToken
            )
            Self.saveCurrentContainerToKeychain()
            return user
        }
    }
}

// MARK: Logging Out
extension ParseUser {

    /**
    Logs out the currently logged in user in Keychain *synchronously*.
    */
    public static func logout(options: API.Options = []) throws {
        _ = try logoutCommand().execute(options: options)
    }

    /**
     Logs out the currently logged in user *asynchronously*.

     This will also remove the session from the Keychain, log out of linked services
     and all future calls to `current` will return `nil`. This is preferable to using `logout`,
     unless your code is already running from a background thread.

     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when logging out, completes or fails.
    */
    public static func logout(options: API.Options = [], callbackQueue: DispatchQueue = .main,
                              completion: @escaping (ParseError?) -> Void) {
        logoutCommand().executeAsync(options: options, callbackQueue: callbackQueue) { result in
            switch result {

            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    internal static func logoutCommand() -> API.NonParseBodyCommand<NoBody, NoBody> {
        return API.NonParseBodyCommand(method: .POST, path: .logout) { (data) -> NoBody in
            var parseError: ParseError?
            var serverResponse = NoBody()
            do {
                serverResponse = try ParseCoding.jsonDecoder().decode(NoBody.self, from: data)
            } catch {
                if let foundError = error as? ParseError {
                    parseError = foundError
                } else {
                    parseError = ParseError(code: .unknownError, message: error.localizedDescription)
                }
            }
            //Always let user logout locally, no matter the error.
            deleteCurrentContainerFromKeychain()
            currentUserContainer = nil
            guard let error = parseError else {
                return serverResponse
            }
            throw error
       }
    }
}

// MARK: Password Reset
extension ParseUser {

    /**
     Requests *synchronously* a password reset email to be sent to the specified email address
     associated with the user account. This email allows the user to securely reset their password on the web.
        - parameter email: The email address associated with the user that forgot their password.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
    */
    public static func passwordReset(email: String, options: API.Options = []) throws {
        if let error = try passwordResetCommand(email: email).execute(options: options) {
            throw error
        }
    }

    /**
     Requests *asynchronously* a password reset email to be sent to the specified email address
     associated with the user account. This email allows the user to securely reset their password on the web.
        - parameter email: The email address associated with the user that forgot their password.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of .main.
        - parameter completion: A block that will be called when the password reset completes or fails.
    */
    public static func passwordReset(email: String, options: API.Options = [],
                                     callbackQueue: DispatchQueue = .main,
                                     completion: @escaping (ParseError?) -> Void) {
        passwordResetCommand(email: email).executeAsync(options: options, callbackQueue: callbackQueue) { result in
            switch result {

            case .success(let error):
                completion(error)
            case .failure(let error):
                completion(error)
            }
        }
    }

    internal static func passwordResetCommand(email: String) -> API.NonParseBodyCommand<EmailBody, ParseError?> {
        let emailBody = EmailBody(email: email)
        return API.NonParseBodyCommand(method: .POST, path: .passwordReset, body: emailBody) { (data) -> ParseError? in
            try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
        }
    }
}

// MARK: Verification Email Request
extension ParseUser {

    /**
     Requests *synchronously* a verification email be sent to the specified email address
     associated with the user account.
        - parameter email: The email address associated with the user.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
    */
    public static func verificationEmailRequest(email: String,
                                                options: API.Options = []) throws {
        if let error = try verificationEmailRequestCommand(email: email).execute(options: options) {
            throw error
        }
    }

    /**
     Requests *asynchronously* a verification email be sent to the specified email address
     associated with the user account.
        - parameter email: The email address associated with the user.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of .main.
        - parameter completion: A block that will be called when the verification request completes or fails.
    */
    public static func verificationEmailRequest(email: String,
                                                options: API.Options = [],
                                                callbackQueue: DispatchQueue = .main,
                                                completion: @escaping (ParseError?) -> Void) {
        verificationEmailRequestCommand(email: email)
            .executeAsync(options: options,
                          callbackQueue: callbackQueue) { result in
            switch result {

            case .success(let error):
                completion(error)
            case .failure(let error):
                completion(error)
            }
        }
    }

    // swiftlint:disable:next line_length
    internal static func verificationEmailRequestCommand(email: String) -> API.NonParseBodyCommand<EmailBody, ParseError?> {
        let emailBody = EmailBody(email: email)
        return API.NonParseBodyCommand(method: .POST,
                                       path: .verificationEmailRequest,
                                       body: emailBody) { (data) -> ParseError? in
            try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
        }
    }
}

// MARK: Signing Up
extension ParseUser {
    /**
     Signs up the user *synchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns whether the sign up was successful.
    */
    public static func signup(username: String,
                              password: String, options: API.Options = []) throws -> Self {
        try signupCommand(username: username, password: password).execute(options: options)
    }

    /**
     Signs up the user *synchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns whether the sign up was successful.
    */
    public func signup(options: API.Options = []) throws -> Self {
        try signupCommand().execute(options: options)
    }

    /**
     Signs up the user *asynchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func signup(options: API.Options = [], callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Self, ParseError>) -> Void) {
        signupCommand().executeAsync(options: options, callbackQueue: callbackQueue, completion: completion)
    }

    /**
     Signs up the user *asynchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public static func signup(
        username: String,
        password: String,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        signupCommand(username: username, password: password)
            .executeAsync(options: options, callbackQueue: callbackQueue, completion: completion)
    }

    internal static func signupCommand(username: String,
                                       password: String) -> API.NonParseBodyCommand<SignupBody, Self> {

        let body = SignupBody(username: username, password: password)
        return API.NonParseBodyCommand(method: .POST, path: .users, body: body) { (data) -> Self in

            let response = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: data)
            var user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)
            user.username = username
            user.password = password

            Self.currentUserContainer = .init(
                currentUser: user,
                sessionToken: response.sessionToken
            )
            Self.saveCurrentContainerToKeychain()
            return user
        }
    }

    internal func signupCommand() -> API.Command<Self, Self> {
        return API.Command(method: .POST, path: .users, body: self) { (data) -> Self in

            let response = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: data)
            var user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)
            user.username = self.username
            user.password = self.password

            Self.currentUserContainer = .init(
                currentUser: user,
                sessionToken: response.sessionToken
            )
            Self.saveCurrentContainerToKeychain()
            return user
        }
    }
}

// MARK: Fetchable
extension ParseUser {
    internal static func updateKeychainIfNeeded(_ results: [Self], deleting: Bool = false) throws {
        guard let currentUser = BaseParseUser.current else {
            return
        }

        var foundCurrentUserObjects = results.filter { $0.hasSameObjectId(as: currentUser) }
        foundCurrentUserObjects = try foundCurrentUserObjects.sorted(by: {
            if $0.updatedAt == nil || $1.updatedAt == nil {
                throw ParseError(code: .unknownError,
                                 message: "Objects from the server should always have an 'updatedAt'")
            }
            return $0.updatedAt!.compare($1.updatedAt!) == .orderedDescending
        })
        if let foundCurrentUser = foundCurrentUserObjects.first {
            if !deleting {
                Self.current = foundCurrentUser
                Self.saveCurrentContainerToKeychain()
            } else {
                Self.deleteCurrentContainerFromKeychain()
            }
        }
    }

    /**
     Fetches the `ParseUser` *synchronously* with the current data from the server and sets an error if one occurs.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An Error of `ParseError` type.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
    */
    public func fetch(options: API.Options = []) throws -> Self {
        let result: Self = try fetchCommand().execute(options: options)
        try? Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Fetches the `ParseUser` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
    */
    public func fetch(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
         do {
            try fetchCommand().executeAsync(options: options, callbackQueue: callbackQueue) { result in
                if case .success(let foundResult) = result {
                    try? Self.updateKeychainIfNeeded([foundResult])
                }
                completion(result)
            }
         } catch let error as ParseError {
             completion(.failure(error))
         } catch {
             completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
         }
    }

    func fetchCommand() throws -> API.Command<Self, Self> {
        guard isSaved else {
            throw ParseError(code: .unknownError, message: "Cannot fetch an object without id")
        }

        return API.Command(method: .GET,
                    path: endpoint) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }
}

// MARK: Savable
extension ParseUser {

    /**
     Saves the `ParseUser` *synchronously* and throws an error if there's an issue.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: A Error of type `ParseError`.
     - returns: Returns saved `ParseUser`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    public func save(options: API.Options = []) throws -> Self {
        var childObjects: [String: PointerType]?
        var childFiles: [UUID: ParseFile]?
        var error: ParseError?
        let group = DispatchGroup()
        group.enter()
        self.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, parseError) in
            childObjects = savedChildObjects
            childFiles = savedChildFiles
            error = parseError
            group.leave()
        }
        group.wait()

        if let error = error {
            throw error
        }

        let result: Self = try saveCommand()
            .execute(options: options,
                     childObjects: childObjects,
                     childFiles: childFiles)
        try? Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Saves the `ParseUser` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    public func save(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        self.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, error) in
            guard let parseError = error else {
                self.saveCommand().executeAsync(options: options,
                                                callbackQueue: callbackQueue,
                                                childObjects: savedChildObjects,
                                                childFiles: savedChildFiles) { result in
                    if case .success(let foundResults) = result {
                        try? Self.updateKeychainIfNeeded([foundResults])
                    }
                    completion(result)
                }
                return
            }
            completion(.failure(parseError))
        }
    }

    func saveCommand() -> API.Command<Self, Self> {
        if isSaved {
            return updateCommand()
        }
        return createCommand()
    }

    // MARK: Saving ParseObjects - private
    private func createCommand() -> API.Command<Self, Self> {
        let mapper = { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(SaveResponse.self, from: data).apply(to: self)
        }
        return API.Command<Self, Self>(method: .POST,
                                 path: endpoint,
                                 body: self,
                                 mapper: mapper)
    }

    private func updateCommand() -> API.Command<Self, Self> {
        let mapper = { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(UpdateResponse.self, from: data).apply(to: self)
        }
        return API.Command<Self, Self>(method: .PUT,
                                 path: endpoint,
                                 body: self,
                                 mapper: mapper)
    }
}

// MARK: Deletable
extension ParseUser {
    /**
     Deletes the `ParseUser` *synchronously* with the current data from the server and sets an error if one occurs.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An Error of `ParseError` type.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
    public func delete(options: API.Options = []) throws {
        _ = try deleteCommand().execute(options: options)
        try? Self.updateKeychainIfNeeded([self], deleting: true)
    }

    /**
     Deletes the `ParseUser` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
    public func delete(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (ParseError?) -> Void
    ) {
         do {
            try deleteCommand().executeAsync(options: options, callbackQueue: callbackQueue) { result in
                switch result {

                case .success:
                    try? Self.updateKeychainIfNeeded([self], deleting: true)
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
            }
         } catch let error as ParseError {
             completion(error)
         } catch {
             completion(ParseError(code: .unknownError, message: error.localizedDescription))
         }
    }

    func deleteCommand() throws -> API.NonParseBodyCommand<NoBody, ParseError?> {
        guard isSaved else {
            throw ParseError(code: .unknownError, message: "Cannot Delete an object without id")
        }

        return API.NonParseBodyCommand<NoBody, ParseError?>(
            method: .DELETE,
            path: endpoint
        ) { (data) -> ParseError? in
            try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
        }
    }
}

// MARK: Batch Support
public extension Sequence where Element: ParseUser {

    /**
     Saves a collection of users *synchronously* all at once and throws an error if necessary.
     - parameter batchLimit: The amount of objects to send in each batch. If the items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a save was successful or a `ParseError` if it failed.
     - throws: `ParseError`
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    func saveAll(batchLimit limit: Int? = nil, // swiftlint:disable:this function_body_length
                 options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        var childObjects = [String: PointerType]()
        var childFiles = [UUID: ParseFile]()
        var error: ParseError?
        let users = map { $0 }
        for user in users {
            let group = DispatchGroup()
            group.enter()
            user.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, parseError) -> Void in
                //If an error occurs, everything should be skipped
                if parseError != nil {
                    error = parseError
                }
                savedChildObjects.forEach {(key, value) in
                    if error != nil {
                        return
                    }
                    if childObjects[key] == nil {
                        childObjects[key] = value
                    } else {
                        error = ParseError(code: .unknownError, message: "circular dependency")
                        return
                    }
                }
                savedChildFiles.forEach {(key, value) in
                    if error != nil {
                        return
                    }
                    if childFiles[key] == nil {
                        childFiles[key] = value
                    } else {
                        error = ParseError(code: .unknownError, message: "circular dependency")
                        return
                    }
                }
                group.leave()
            }
            group.wait()
            if let error = error {
                throw error
            }
        }

        var returnBatch = [(Result<Self.Element, ParseError>)]()
        let commands = map { $0.saveCommand() }
        let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
        try batches.forEach {
            let currentBatch = try API.Command<Self.Element, Self.Element>
                .batch(commands: $0)
                .execute(options: options,
                         childObjects: childObjects,
                         childFiles: childFiles)
            returnBatch.append(contentsOf: currentBatch)
        }
        try? Self.Element.updateKeychainIfNeeded(returnBatch.compactMap {try? $0.get()})
        return returnBatch
    }

    /**
     Saves a collection of users all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The amount of objects to send in each batch. If the items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    func saveAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        var childObjects = [String: PointerType]()
        var childFiles = [UUID: ParseFile]()
        var error: ParseError?

        let users = map { $0 }
        for user in users {
            let group = DispatchGroup()
            group.enter()
            user.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, parseError) -> Void in
                //If an error occurs, everything should be skipped
                if parseError != nil {
                    error = parseError
                }
                savedChildObjects.forEach {(key, value) in
                    if error != nil {
                        return
                    }
                    if childObjects[key] == nil {
                        childObjects[key] = value
                    } else {
                        error = ParseError(code: .unknownError, message: "circular dependency")
                        return
                    }
                }
                savedChildFiles.forEach {(key, value) in
                    if error != nil {
                        return
                    }
                    if childFiles[key] == nil {
                        childFiles[key] = value
                    } else {
                        error = ParseError(code: .unknownError, message: "circular dependency")
                        return
                    }
                }
                group.leave()
            }
            group.wait()
            if let error = error {
                completion(.failure(error))
                return
            }
        }

        var returnBatch = [(Result<Self.Element, ParseError>)]()
        let commands = map { $0.saveCommand() }
        let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
        var completed = 0
        for batch in batches {
            API.Command<Self.Element, Self.Element>
                    .batch(commands: batch)
                    .executeAsync(options: options,
                                  callbackQueue: callbackQueue,
                                  childObjects: childObjects,
                                  childFiles: childFiles) { results in
                switch results {

                case .success(let saved):
                    returnBatch.append(contentsOf: saved)
                    if completed == (batches.count - 1) {
                        try? Self.Element.updateKeychainIfNeeded(returnBatch.compactMap {try? $0.get()})
                        completion(.success(returnBatch))
                    }
                    completed += 1
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
            }
        }
    }

    /**
     Fetches a collection of users *synchronously* all at once and throws an error if necessary.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a fetch was successful or a `ParseError` if it failed.
     - throws: `ParseError`
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - warning: The order in which users are returned are not guarenteed. You shouldn't expect results in
     any particular order.
    */
    func fetchAll(options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {

        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(self.compactMap { $0.objectId })
            let query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
            let fetchedObjects = try query.find(options: options)
            var fetchedObjectsToReturn = [(Result<Self.Element, ParseError>)]()

            uniqueObjectIds.forEach {
                let uniqueObjectId = $0
                if let fetchedObject = fetchedObjects.first(where: {$0.objectId == uniqueObjectId}) {
                    fetchedObjectsToReturn.append(.success(fetchedObject))
                } else {
                    fetchedObjectsToReturn.append(.failure(ParseError(code: .objectNotFound,
                                                                      // swiftlint:disable:next line_length
                                                                      message: "objectId \"\(uniqueObjectId)\" was not found in className \"\(Self.Element.className)\"")))
                }
            }
            try? Self.Element.updateKeychainIfNeeded(fetchedObjects)
            return fetchedObjectsToReturn
        } else {
            throw ParseError(code: .unknownError, message: "all items to fetch must be of the same class")
        }
    }

    /**
     Fetches a collection of users all at once *asynchronously* and executes the completion block when done.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - warning: The order in which users are returned are not guarenteed. You shouldn't expect results in
     any particular order.
    */
    func fetchAll(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(compactMap { $0.objectId })
            let query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
            query.find(options: options, callbackQueue: callbackQueue) { result in
                switch result {

                case .success(let fetchedObjects):
                    var fetchedObjectsToReturn = [(Result<Self.Element, ParseError>)]()

                    uniqueObjectIds.forEach {
                        let uniqueObjectId = $0
                        if let fetchedObject = fetchedObjects.first(where: {$0.objectId == uniqueObjectId}) {
                            fetchedObjectsToReturn.append(.success(fetchedObject))
                        } else {
                            fetchedObjectsToReturn.append(.failure(ParseError(code: .objectNotFound,
                                                                              // swiftlint:disable:next line_length
                                                                              message: "objectId \"\(uniqueObjectId)\" was not found in className \"\(Self.Element.className)\"")))
                        }
                    }
                    try? Self.Element.updateKeychainIfNeeded(fetchedObjects)
                    completion(.success(fetchedObjectsToReturn))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            completion(.failure(ParseError(code: .unknownError,
                                           message: "all items to fetch must be of the same class")))
        }
    }

    /**
     Deletes a collection of users *synchronously* all at once and throws an error if necessary.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns `nil` if the delete successful or a `ParseError` if it failed.
        1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
        array of other Parse.Error objects. Each error object in this array
        has an "object" property that references the object that could not be
        deleted (for instance, because that object could not be found).
        2. A non-aggregate Parse.Error. This indicates a serious error that
        caused the delete operation to be aborted partway through (for
        instance, a connection failure in the middle of the delete).
     - throws: `ParseError`
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
    func deleteAll(batchLimit limit: Int? = nil,
                   options: API.Options = []) throws -> [ParseError?] {
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        var returnBatch = [ParseError?]()
        let commands = try map { try $0.deleteCommand() }
        let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
        try batches.forEach {
            let currentBatch = try API.Command<Self.Element, ParseError?>
                .batch(commands: $0)
                .execute(options: options)
            returnBatch.append(contentsOf: currentBatch)
        }
        try? Self.Element.updateKeychainIfNeeded(compactMap {$0})
        return returnBatch
    }

    /**
     Deletes a collection of users all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[ParseError?], ParseError>)`.
     Each element in the array is `nil` if the delete successful or a `ParseError` if it failed.
     1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
     array of other Parse.Error objects. Each error object in this array
     has an "object" property that references the object that could not be
     deleted (for instance, because that object could not be found).
     2. A non-aggregate Parse.Error. This indicates a serious error that
     caused the delete operation to be aborted partway through (for
     instance, a connection failure in the middle of the delete).
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
    func deleteAll(
        batchLimit limit: Int? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[ParseError?], ParseError>) -> Void
    ) {
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        do {
            var returnBatch = [ParseError?]()
            let commands = try map({ try $0.deleteCommand() })
            let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
            var completed = 0
            for batch in batches {
                API.Command<Self.Element, ParseError?>
                        .batch(commands: batch)
                        .executeAsync(options: options,
                                      callbackQueue: callbackQueue) { results in
                    switch results {

                    case .success(let saved):
                        returnBatch.append(contentsOf: saved)
                        if completed == (batches.count - 1) {
                            try? Self.Element.updateKeychainIfNeeded(self.compactMap {$0})
                            completion(.success(returnBatch))
                        }
                        completed += 1
                    case .failure(let error):
                        completion(.failure(error))
                        return
                    }
                }
            }
        } catch {
            guard let parseError = error as? ParseError else {
                completion(.failure(ParseError(code: .unknownError,
                                               message: error.localizedDescription)))
                return
            }
            completion(.failure(parseError))
        }
    }
} // swiftlint:disable:this file_length
