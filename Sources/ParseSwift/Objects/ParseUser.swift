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
    Determines if the email is verified for the `ParseUser`.
     - note: This value can only be changed on the Parse Server.
    */
    var emailVerified: Bool? { get }

    /**
     The password for the `ParseUser`.

     This will not be filled in from the server with the password.
     It is only meant to be set.
    */
    var password: String? { get set }

    /**
     The authentication data for the `ParseUser`. Used by `ParseAnonymous`
     or any authentication type that conforms to `ParseAuthentication`.
    */
    var authData: [String: [String: String]?]? { get set }
}

// MARK: SignupLoginBody
struct SignupLoginBody: Encodable {
    var username: String?
    var password: String?
    var authData: [String: [String: String]?]?

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    init(authData: [String: [String: String]?]) {
        self.authData = authData
    }
}

// MARK: EmailBody
struct EmailBody: Encodable {
    let email: String
}

// MARK: Default Implementations
public extension ParseUser {
    static var className: String {
        "_User"
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

    func endpoint(_ method: API.Method) -> API.Endpoint {
        if !ParseSwift.configuration.allowCustomObjectId || method != .POST {
            return endpoint
        } else {
            return .users
        }
    }

    static func deleteCurrentKeychain() {
        deleteCurrentContainerFromKeychain()
        BaseParseInstallation.deleteCurrentContainerFromKeychain()
        BaseConfig.deleteCurrentContainerFromKeychain()
        ParseSwift.clearCache()
    }
}

// MARK: CurrentUserContainer
struct CurrentUserContainer<T: ParseUser>: Codable {
    var currentUser: T?
    var sessionToken: String?
}

// MARK: Current User Support
public extension ParseUser {
    internal static var currentContainer: CurrentUserContainer<Self>? {
        get {
            guard let currentUserInMemory: CurrentUserContainer<Self>
                = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                #if !os(Linux) && !os(Android)
                return try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
                #else
                return nil
                #endif
            }
            return currentUserInMemory
        }
        set { try? ParseStorage.shared.set(newValue, for: ParseStorage.Keys.currentUser) }
    }

    internal static func saveCurrentContainerToKeychain() {
        #if !os(Linux) && !os(Android)
        try? KeychainStore.shared.set(Self.currentContainer, for: ParseStorage.Keys.currentUser)
        #endif
    }

    internal static func deleteCurrentContainerFromKeychain() {
        try? ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentUser)
        #if !os(Linux) && !os(Android)
        if #available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *) {
            URLSession.liveQuery.closeAll()
        }
        try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentUser)
        #endif
        Self.currentContainer = nil
    }

    /**
     Gets the currently logged in user from the Keychain and returns an instance of it.

     - returns: Returns a `ParseUser` that is the currently logged in user. If there is none, returns `nil`.
     - warning: Only use `current` users on the main thread as as modifications to `current` have to be unique.
    */
    internal(set) static var current: Self? {
        get { Self.currentContainer?.currentUser }
        set {
            Self.currentContainer?.currentUser = newValue
        }
    }

    /**
     The session token for the `ParseUser`.

     This is set by the server upon successful authentication.
    */
    var sessionToken: String? {
        Self.currentContainer?.sessionToken
    }
}

// MARK: Logging In
extension ParseUser {

    /**
     Makes a *synchronous* request to login a user with specified credentials.

     Returns an instance of the successfully logged in `ParseUser`.
     This also caches the user locally so that calls to *current* will use the latest logged in user.

     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - returns: An instance of the logged in `ParseUser`.
     If login failed due to either an incorrect password or incorrect username, it throws a `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public static func login(username: String,
                             password: String, options: API.Options = []) throws -> Self {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        return try loginCommand(username: username, password: password).execute(options: options)
    }

    /**
     Makes an *asynchronous* request to log in a user with specified credentials.
     Returns an instance of the successfully logged in `ParseUser`.

     This also caches the user locally so that calls to *current* will use the latest logged in user.
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public static func login(
        username: String,
        password: String,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        loginCommand(username: username, password: password)
            .executeAsync(options: options) { result in
                callbackQueue.async {
                    completion(result)
                }
            }
    }

    internal static func loginCommand(username: String,
                                      password: String) -> API.NonParseBodyCommand<SignupLoginBody, Self> {

        let body = SignupLoginBody(username: username, password: password)
        return API.NonParseBodyCommand<SignupLoginBody, Self>(method: .POST,
                                         path: .login,
                                         body: body) { (data) -> Self in
            let sessionToken = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: data).sessionToken
            var user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)
            user.username = username

            Self.currentContainer = .init(
                currentUser: user,
                sessionToken: sessionToken
            )
            Self.saveCurrentContainerToKeychain()
            return user
        }
    }

    /**
     Logs in a `ParseUser` *synchronously* with a session token. On success, this saves the session
     to the keychain, so you can retrieve the currently logged in user using *current*.

     - parameter sessionToken: The sessionToken of the user to login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An Error of `ParseError` type.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func become(sessionToken: String, options: API.Options = []) throws -> Self {
        var newUser = self
        newUser.objectId = "me"
        var options = options
        options.insert(.sessionToken(sessionToken))
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        return try newUser.meCommand(sessionToken: sessionToken)
            .execute(options: options,
                     callbackQueue: .main)
    }

    /**
     Logs in a `ParseUser` *asynchronously* with a session token. On success, this saves the session
     to the keychain, so you can retrieve the currently logged in user using *current*.

     - parameter sessionToken: The sessionToken of the user to login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func become(sessionToken: String,
                       options: API.Options = [],
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Self, ParseError>) -> Void) {
        var newUser = self
        newUser.objectId = "me"
        var options = options
        options.insert(.sessionToken(sessionToken))
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
         do {
            try newUser.meCommand(sessionToken: sessionToken)
                .executeAsync(options: options,
                              callbackQueue: callbackQueue) { result in
                if case .success(let foundResult) = result {
                    callbackQueue.async {
                        completion(.success(foundResult))
                    }
                } else {
                    callbackQueue.async {
                        completion(result)
                    }
                }
            }
         } catch let error as ParseError {
            callbackQueue.async {
                completion(.failure(error))
            }
         } catch {
            callbackQueue.async {
                completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
            }
         }
    }

    internal func meCommand(sessionToken: String) throws -> API.Command<Self, Self> {

        return API.Command(method: .GET,
                    path: endpoint) { (data) -> Self in
            let user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)

            if let current = Self.current {
                if !current.hasSameObjectId(as: user) && self.anonymous.isLinked {
                    Self.deleteCurrentContainerFromKeychain()
                }
            }

            Self.currentContainer = .init(
                currentUser: user,
                sessionToken: sessionToken
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
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of `ParseError` type.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public static func logout(options: API.Options = []) throws {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let error = try? logoutCommand().execute(options: options)
        //Always let user logout locally, no matter the error.
        deleteCurrentKeychain()
        //Wait to throw error
        if let parseError = error {
            throw parseError
        }
    }

    /**
     Logs out the currently logged in user *asynchronously*.

     This will also remove the session from the Keychain, log out of linked services
     and all future calls to `current` will return `nil`. This is preferable to using `logout`,
     unless your code is already running from a background thread.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when logging out completes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public static func logout(options: API.Options = [], callbackQueue: DispatchQueue = .main,
                              completion: @escaping (Result<Void, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        logoutCommand().executeAsync(options: options) { result in
            callbackQueue.async {

                //Always let user logout locally, no matter the error.
                deleteCurrentKeychain()

                switch result {

                case .success(let error):
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    internal static func logoutCommand() -> API.NonParseBodyCommand<NoBody, ParseError?> {
        return API.NonParseBodyCommand(method: .POST, path: .logout) { (data) -> ParseError? in
            do {
                let parseError = try ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
                return parseError
            } catch {
                return nil
            }
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
        - throws: An error of `ParseError` type.
        - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
        desires a different policy, it should be inserted in `options`.
    */
    public static func passwordReset(email: String, options: API.Options = []) throws {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
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
        - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
        desires a different policy, it should be inserted in `options`.
    */
    public static func passwordReset(email: String, options: API.Options = [],
                                     callbackQueue: DispatchQueue = .main,
                                     completion: @escaping (Result<Void, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        passwordResetCommand(email: email).executeAsync(options: options) { result in
            callbackQueue.async {
                switch result {

                case .success(let error):
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
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
        - throws: An error of `ParseError` type.
        - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
        desires a different policy, it should be inserted in `options`.
    */
    public static func verificationEmail(email: String,
                                         options: API.Options = []) throws {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        if let error = try verificationEmailCommand(email: email).execute(options: options) {
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
        - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
        desires a different policy, it should be inserted in `options`.
    */
    public static func verificationEmail(email: String,
                                         options: API.Options = [],
                                         callbackQueue: DispatchQueue = .main,
                                         completion: @escaping (Result<Void, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        verificationEmailCommand(email: email)
            .executeAsync(options: options) { result in
                callbackQueue.async {

                    switch result {

                    case .success(let error):
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
        }
    }

    internal static func verificationEmailCommand(email: String) -> API.NonParseBodyCommand<EmailBody, ParseError?> {
        let emailBody = EmailBody(email: email)
        return API.NonParseBodyCommand(method: .POST,
                                       path: .verificationEmail,
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
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public static func signup(username: String,
                              password: String,
                              options: API.Options = []) throws -> Self {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let body = SignupLoginBody(username: username,
                                   password: password)
        if let current = Self.current {
            return try current.linkCommand(body: body)
                .execute(options: options)
        } else {
            return try signupCommand(body: body)
                .execute(options: options)
        }
    }

    /**
     Signs up the user *synchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns whether the sign up was successful.
     - throws: An error of `ParseError` type.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func signup(options: API.Options = []) throws -> Self {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        if let current = Self.current {
            return try current.linkCommand()
                .execute(options: options)
        } else {
            return try signupCommand().execute(options: options,
                                               callbackQueue: .main)
        }
    }

    /**
     Signs up the user *asynchronously*.

     This will also enforce that the username isn't already taken.

     - warning: Make sure that password and username are set before calling this method.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func signup(options: API.Options = [], callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Self, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        if let current = Self.current {
            current.linkCommand()
                .executeAsync(options: options) { result in
                    callbackQueue.async {
                        completion(result)
                    }
                }
        } else {
            do {
                try signupCommand()
                    .executeAsync(options: options,
                                  callbackQueue: callbackQueue) { result in
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
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public static func signup(
        username: String,
        password: String,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void) {

        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let body = SignupLoginBody(username: username, password: password)
        if let current = Self.current {
            current.linkCommand(body: body)
                .executeAsync(options: options) { result in
                    callbackQueue.async {
                        completion(result)
                    }
                }
        } else {
            do {
                try signupCommand(body: body)
                    .executeAsync(options: options) { result in
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

    internal static func signupCommand(body: SignupLoginBody) throws -> API.NonParseBodyCommand<SignupLoginBody, Self> {
        API.NonParseBodyCommand(method: .POST,
                                path: .users, body: body) { (data) -> Self in

            let sessionToken = try ParseCoding.jsonDecoder()
                .decode(LoginSignupResponse.self, from: data).sessionToken
            var user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)

            if user.username == nil {
                if let username = body.username {
                    user.username = username
                }
            }
            if user.authData == nil {
                if let authData = body.authData {
                    user.authData = authData
                }
            }
            Self.currentContainer = .init(currentUser: user,
                                              sessionToken: sessionToken)
            Self.saveCurrentContainerToKeychain()
            return user
        }
    }

    internal func signupCommand() throws -> API.Command<Self, Self> {

        API.Command(method: .POST,
                    path: endpoint,
                    body: self) { (data) -> Self in

            let response = try ParseCoding.jsonDecoder()
                .decode(LoginSignupResponse.self, from: data)
            let user = response.applySignup(to: self)
            Self.currentContainer = .init(
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
        guard let currentUser = Self.current else {
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
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of `ParseError` type.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func fetch(includeKeys: [String]? = nil,
                      options: API.Options = []) throws -> Self {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let result: Self = try fetchCommand(include: includeKeys)
            .execute(options: options,
                     callbackQueue: .main)
        try Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Fetches the `ParseUser` *asynchronously* and executes the given callback block.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func fetch(
        includeKeys: [String]? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
         do {
            try fetchCommand(include: includeKeys)
                .executeAsync(options: options,
                              callbackQueue: callbackQueue) { result in
                callbackQueue.async {
                    if case .success(let foundResult) = result {
                        do {
                            try Self.updateKeychainIfNeeded([foundResult])
                            completion(.success(foundResult))
                        } catch {
                            let returnError: ParseError!
                            if let parseError = error as? ParseError {
                                returnError = parseError
                            } else {
                                returnError = ParseError(code: .unknownError, message: error.localizedDescription)
                            }
                            completion(.failure(returnError))
                        }
                    } else {
                        completion(result)
                    }
                }
            }
         } catch {
            callbackQueue.async {
                if let error = error as? ParseError {
                    completion(.failure(error))
                } else {
                    completion(.failure(ParseError(code: .unknownError,
                                                   message: error.localizedDescription)))
                }
            }
         }
    }

    func fetchCommand(include: [String]?) throws -> API.Command<Self, Self> {
        guard objectId != nil else {
            throw ParseError(code: .unknownError, message: "Cannot fetch an object without id")
        }

        var params: [String: String]?
        if let includeParams = include {
            params = ["include": "\(includeParams)"]
        }

        return API.Command(method: .GET,
                           path: endpoint,
                           params: params) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }
}

// MARK: Savable
extension ParseUser {

    /**
     Saves the `ParseUser` *synchronously* and throws an error if there's an issue.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - returns: Returns saved `ParseUser`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    public func save(options: API.Options = []) throws -> Self {
        try save(isIgnoreCustomObjectIdConfig: false, options: options)
    }

    /**
     Saves the `ParseUser` *synchronously* and throws an error if there's an issue.

     - parameter isIgnoreCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.allowCustomObjectId = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - returns: Returns saved `ParseUser`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If you are using `ParseConfiguration.allowCustomObjectId = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `isIgnoreCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.allowCustomObjectId = true` and
     `isIgnoreCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func save(isIgnoreCustomObjectIdConfig: Bool,
                     options: API.Options = []) throws -> Self {
        var childObjects: [String: PointerType]?
        var childFiles: [UUID: ParseFile]?
        var error: ParseError?
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
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

        let result: Self = try saveCommand(isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig)
            .execute(options: options,
                     callbackQueue: .main,
                     childObjects: childObjects,
                     childFiles: childFiles)
        try Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Saves the `ParseUser` *asynchronously* and executes the given callback block.

     - parameter isIgnoreCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.allowCustomObjectId = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If you are using `ParseConfiguration.allowCustomObjectId = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `isIgnoreCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.allowCustomObjectId = true` and
     `isIgnoreCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func save(
        isIgnoreCustomObjectIdConfig: Bool = false,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        self.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, error) in
            guard let parseError = error else {
                do {
                    try self.saveCommand(isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig)
                        .executeAsync(options: options,
                                      callbackQueue: callbackQueue,
                                      childObjects: savedChildObjects,
                                      childFiles: savedChildFiles) { result in
                            callbackQueue.async {
                                if case .success(let foundResults) = result {
                                    try? Self.updateKeychainIfNeeded([foundResults])
                                }
                                completion(result)
                            }
                    }
                } catch {
                    callbackQueue.async {
                        if let parseError = error as? ParseError {
                            completion(.failure(parseError))
                        } else {
                            completion(.failure(.init(code: .unknownError, message: error.localizedDescription)))
                        }
                    }
                }
                return
            }
            callbackQueue.async {
                completion(.failure(parseError))
            }
        }
    }

    func saveCommand(isIgnoreCustomObjectIdConfig: Bool = false) throws -> API.Command<Self, Self> {
        if ParseSwift.configuration.allowCustomObjectId && objectId == nil && !isIgnoreCustomObjectIdConfig {
            throw ParseError(code: .missingObjectId, message: "objectId must not be nil")
        }
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
                                       path: endpoint(.POST),
                                       body: self,
                                       mapper: mapper)
    }

    private func updateCommand() -> API.Command<Self, Self> {
        var mutableSelf = self
        if let currentUser = Self.current,
           currentUser.hasSameObjectId(as: mutableSelf) == true {
            #if !os(Linux) && !os(Android)
            // swiftlint:disable:next line_length
            if let currentUserContainerInKeychain: CurrentUserContainer<BaseParseUser> = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
               currentUserContainerInKeychain.currentUser?.email == mutableSelf.email {
                mutableSelf.email = nil
            }
            #else
            if currentUser.email == mutableSelf.email {
                mutableSelf.email = nil
            }
            #endif
        }
        let mapper = { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(UpdateResponse.self, from: data).apply(to: self)
        }
        return API.Command<Self, Self>(method: .PUT,
                                 path: endpoint,
                                 body: mutableSelf,
                                 mapper: mapper)
    }
}

// MARK: Deletable
extension ParseUser {
    /**
     Deletes the `ParseUser` *synchronously* with the current data from the server and sets an error if one occurs.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of `ParseError` type.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func delete(options: API.Options = []) throws {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        _ = try deleteCommand().execute(options: options)
        try Self.updateKeychainIfNeeded([self], deleting: true)
    }

    /**
     Deletes the `ParseUser` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func delete(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Void, ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
         do {
            try deleteCommand().executeAsync(options: options) { result in
                switch result {

                case .success:
                    callbackQueue.async {
                        try? Self.updateKeychainIfNeeded([self], deleting: true)
                        completion(.success(()))
                    }
                case .failure(let error):
                    callbackQueue.async {
                        completion(.failure(error))
                    }
                }
            }
         } catch let error as ParseError {
            callbackQueue.async {
                completion(.failure(error))
            }
         } catch {
            callbackQueue.async {
                completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
            }
         }
    }

    func deleteCommand() throws -> API.NonParseBodyCommand<NoBody, NoBody> {
        guard isSaved else {
            throw ParseError(code: .unknownError, message: "Cannot Delete an object without id")
        }

        return API.NonParseBodyCommand<NoBody, NoBody>(
            method: .DELETE,
            path: endpoint
        ) { (data) -> NoBody in
            let error = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
            if let error = error {
                throw error
            } else {
                return NoBody()
            }
        }
    }
}

// MARK: Batch Support
public extension Sequence where Element: ParseUser {

    /**
     Saves a collection of users *synchronously* all at once and throws an error if necessary.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter isIgnoreCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.allowCustomObjectId = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a save was successful or a `ParseError` if it failed.
     - throws: `ParseError`
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - warning: If you are using `ParseConfiguration.allowCustomObjectId = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `isIgnoreCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.allowCustomObjectId = true` and
     `isIgnoreCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func saveAll(batchLimit limit: Int? = nil, // swiftlint:disable:this function_body_length
                 transaction: Bool = false,
                 isIgnoreCustomObjectIdConfig: Bool = false,
                 options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {
        var childObjects = [String: PointerType]()
        var childFiles = [UUID: ParseFile]()
        var error: ParseError?
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
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
        let commands = try map {
            try $0.saveCommand(isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig)
        }
        let batchLimit: Int!
        if transaction {
            batchLimit = commands.count
        } else {
            batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        }
        let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
        try batches.forEach {
            let currentBatch = try API.Command<Self.Element, Self.Element>
                .batch(commands: $0, transaction: transaction)
                .execute(options: options,
                         callbackQueue: .main,
                         childObjects: childObjects,
                         childFiles: childFiles)
            returnBatch.append(contentsOf: currentBatch)
        }
        try Self.Element.updateKeychainIfNeeded(returnBatch.compactMap {try? $0.get()})
        return returnBatch
    }

    /**
     Saves a collection of users all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter isIgnoreCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.allowCustomObjectId = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - warning: If you are using `ParseConfiguration.allowCustomObjectId = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `isIgnoreCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.allowCustomObjectId = true` and
     `isIgnoreCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func saveAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        transaction: Bool = false,
        isIgnoreCustomObjectIdConfig: Bool = false,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let uuid = UUID()
        let queue = DispatchQueue(label: "com.parse.saveAll.\(uuid)",
                                  qos: .default,
                                  attributes: .concurrent,
                                  autoreleaseFrequency: .inherit,
                                  target: nil)
        queue.sync {
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
                    callbackQueue.async {
                        completion(.failure(error))
                    }
                    return
                }
            }

            do {
                var returnBatch = [(Result<Self.Element, ParseError>)]()
                let commands = try map {
                    try $0.saveCommand(isIgnoreCustomObjectIdConfig: isIgnoreCustomObjectIdConfig)
                }
                let batchLimit: Int!
                if transaction {
                    batchLimit = commands.count
                } else {
                    batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
                }
                let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
                var completed = 0
                for batch in batches {
                    API.Command<Self.Element, Self.Element>
                            .batch(commands: batch, transaction: transaction)
                            .executeAsync(options: options,
                                          callbackQueue: callbackQueue,
                                          childObjects: childObjects,
                                          childFiles: childFiles) { results in
                        switch results {

                        case .success(let saved):
                            returnBatch.append(contentsOf: saved)
                            if completed == (batches.count - 1) {
                                callbackQueue.async {
                                    try? Self.Element.updateKeychainIfNeeded(returnBatch.compactMap {try? $0.get()})
                                    completion(.success(returnBatch))
                                }
                            }
                            completed += 1
                        case .failure(let error):
                            callbackQueue.async {
                                completion(.failure(error))
                            }
                            return
                        }
                    }
                }
            } catch {
                callbackQueue.async {
                    if let parseError = error as? ParseError {
                        completion(.failure(parseError))
                    } else {
                        completion(.failure(.init(code: .unknownError, message: error.localizedDescription)))
                    }
                }
            }
        }
    }

    /**
     Fetches a collection of users *synchronously* all at once and throws an error if necessary.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a fetch was successful or a `ParseError` if it failed.
     - throws: An error of `ParseError` type.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - warning: The order in which users are returned are not guarenteed. You shouldn't expect results in
     any particular order.
    */
    func fetchAll(includeKeys: [String]? = nil,
                  options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {

        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(self.compactMap { $0.objectId })
            var query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
                .limit(uniqueObjectIds.count)
            if let include = includeKeys {
                query = query.include(include)
            }
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
            try Self.Element.updateKeychainIfNeeded(fetchedObjects)
            return fetchedObjectsToReturn
        } else {
            throw ParseError(code: .unknownError, message: "all items to fetch must be of the same class")
        }
    }

    /**
     Fetches a collection of users all at once *asynchronously* and executes the completion block when done.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - warning: The order in which users are returned are not guarenteed. You shouldn't expect results in
     any particular order.
    */
    func fetchAll(
        includeKeys: [String]? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(compactMap { $0.objectId })
            var query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
            if let include = includeKeys {
                query = query.include(include)
            }
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
                    callbackQueue.async {
                        try? Self.Element.updateKeychainIfNeeded(fetchedObjects)
                        completion(.success(fetchedObjectsToReturn))
                    }
                case .failure(let error):
                    callbackQueue.async {
                        completion(.failure(error))
                    }
                }
            }
        } else {
            callbackQueue.async {
                completion(.failure(ParseError(code: .unknownError,
                                               message: "all items to fetch must be of the same class")))
            }
        }
    }

    /**
     Deletes a collection of users *synchronously* all at once and throws an error if necessary.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns `nil` if the delete successful or a `ParseError` if it failed.
        1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
        array of other Parse.Error objects. Each error object in this array
        has an "object" property that references the object that could not be
        deleted (for instance, because that object could not be found).
        2. A non-aggregate Parse.Error. This indicates a serious error that
        caused the delete operation to be aborted partway through (for
        instance, a connection failure in the middle of the delete).
     - throws: An error of `ParseError` type.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func deleteAll(batchLimit limit: Int? = nil,
                   transaction: Bool = false,
                   options: API.Options = []) throws -> [(Result<Void, ParseError>)] {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        var returnBatch = [(Result<Void, ParseError>)]()
        let commands = try map { try $0.deleteCommand() }
        let batchLimit: Int!
        if transaction {
            batchLimit = commands.count
        } else {
            batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        }
        let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
        try batches.forEach {
            let currentBatch = try API.Command<Self.Element, ParseError?>
                .batch(commands: $0, transaction: transaction)
                .execute(options: options)
            returnBatch.append(contentsOf: currentBatch)
        }
        try Self.Element.updateKeychainIfNeeded(compactMap {$0},
                                                deleting: true)
        return returnBatch
    }

    /**
     Deletes a collection of users all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
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
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func deleteAll(
        batchLimit limit: Int? = nil,
        transaction: Bool = false,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Void, ParseError>)], ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        do {
            var returnBatch = [(Result<Void, ParseError>)]()
            let commands = try map({ try $0.deleteCommand() })
            let batchLimit: Int!
            if transaction {
                batchLimit = commands.count
            } else {
                batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
            }
            let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
            var completed = 0
            for batch in batches {
                API.Command<Self.Element, ParseError?>
                        .batch(commands: batch, transaction: transaction)
                        .executeAsync(options: options) { results in
                    switch results {

                    case .success(let saved):
                        returnBatch.append(contentsOf: saved)
                        if completed == (batches.count - 1) {
                            callbackQueue.async {
                                try? Self.Element.updateKeychainIfNeeded(self.compactMap {$0},
                                                                         deleting: true)
                                completion(.success(returnBatch))
                            }
                        }
                        completed += 1
                    case .failure(let error):
                        callbackQueue.async {
                            completion(.failure(error))
                        }
                        return
                    }
                }
            }
        } catch {
            callbackQueue.async {
                guard let parseError = error as? ParseError else {
                    completion(.failure(ParseError(code: .unknownError,
                                                   message: error.localizedDescription)))
                    return
                }
                completion(.failure(parseError))
            }
        }
    }
} // swiftlint:disable:this file_length
