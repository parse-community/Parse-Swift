import Foundation

/**
 Objects that conform to the `ParseUser` protocol have a local representation of a user persisted to the
 Keychain and Parse Server. This protocol inherits from the `ParseObject` protocol, and retains the same
 functionality of a `ParseObject`, but also extends it with various user specific methods, like
 authentication, signing up, and validation uniqueness.
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

// MARK: Default Implementations
public extension ParseUser {
    static var className: String {
        "_User"
    }

    func mergeParse(with object: Self) throws -> Self {
        guard hasSameObjectId(as: object) else {
            throw ParseError(code: .unknownError,
                             message: "objectId's of objects do not match")
        }
        var updatedUser = self
        if shouldRestoreKey(\.ACL,
                             original: object) {
            updatedUser.ACL = object.ACL
        }
        if shouldRestoreKey(\.username,
                             original: object) {
            updatedUser.username = object.username
        }
        if shouldRestoreKey(\.email,
                             original: object) {
            updatedUser.email = object.email
        }
        if shouldRestoreKey(\.authData,
                             original: object) {
            updatedUser.authData = object.authData
        }
        return updatedUser
    }

    func merge(with object: Self) throws -> Self {
        do {
            return try mergeAutomatically(object)
        } catch {
            return try mergeParse(with: object)
        }
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
        if !Parse.configuration.isRequiringCustomObjectIds || method != .POST {
            return endpoint
        } else {
            return .users
        }
    }

    static func deleteCurrentKeychain() {
        deleteCurrentContainerFromKeychain()
        BaseParseInstallation.deleteCurrentContainerFromKeychain()
        ParseACL.deleteDefaultFromKeychain()
        BaseConfig.deleteCurrentContainerFromKeychain()
        clearCache()
    }
}

// MARK: CurrentUserContainer
struct CurrentUserContainer<T: ParseUser>: Codable, Hashable {
    var currentUser: T?
    var sessionToken: String?
}

// MARK: Current User Support
public extension ParseUser {
    internal static var currentContainer: CurrentUserContainer<Self>? {
        get {
            guard let currentUserInMemory: CurrentUserContainer<Self>
                = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
                #if !os(Linux) && !os(Android) && !os(Windows)
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
        Self.currentContainer?.currentUser?.originalData = nil
        #if !os(Linux) && !os(Android) && !os(Windows)
        try? KeychainStore.shared.set(currentContainer, for: ParseStorage.Keys.currentUser)
        #endif
    }

    internal static func deleteCurrentContainerFromKeychain() {
        try? ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentUser)
        #if !os(Linux) && !os(Android) && !os(Windows)
        URLSession.liveQuery.closeAll()
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

// MARK: SignupLoginBody
struct SignupLoginBody: ParseEncodable {
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
struct EmailBody: ParseEncodable {
    let email: String
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
            .executeAsync(options: options,
                          callbackQueue: callbackQueue) { result in
                completion(result)
            }
    }

    internal static func loginCommand(username: String,
                                      password: String) -> API.Command<SignupLoginBody, Self> {

        let body = SignupLoginBody(username: username, password: password)
        return API.Command<SignupLoginBody, Self>(method: .POST,
                                                  path: .login,
                                                  body: body) { (data) -> Self in
            let sessionToken = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: data).sessionToken
            let user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)

            Self.currentContainer = .init(
                currentUser: user,
                sessionToken: sessionToken
            )
            Self.saveCurrentContainerToKeychain()
            return user
        }
    }

    /**
     Logs in a `ParseUser` *synchronously* with a session token. On success, this saves the logged in
     `ParseUser`with this session to the keychain, so you can retrieve the currently logged in user using
     *current*.

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
            .execute(options: options)
    }

    /**
     Logs in a `ParseUser` *asynchronously* with a session token. On success, this saves the logged in
     `ParseUser`with this session to the keychain, so you can retrieve the currently logged in user using
     *current*.

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
        Self.become(sessionToken: sessionToken,
                    options: options,
                    callbackQueue: callbackQueue,
                    completion: completion)
    }

    /**
     Logs in a `ParseUser` *asynchronously* with a session token. On success, this saves the logged in
     `ParseUser`with this session to the keychain, so you can retrieve the currently logged in user using
     *current*.

     - parameter sessionToken: The sessionToken of the user to login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public static func become(sessionToken: String,
                              options: API.Options = [],
                              callbackQueue: DispatchQueue = .main,
                              completion: @escaping (Result<Self, ParseError>) -> Void) {
        var newUser = Self()
        newUser.objectId = "me"
        var options = options
        options.insert(.sessionToken(sessionToken))
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        do {
            try newUser.meCommand(sessionToken: sessionToken)
                .executeAsync(options: options,
                              callbackQueue: callbackQueue) { result in
                if case .success(let foundResult) = result {
                    completion(.success(foundResult))
                } else {
                    completion(result)
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

#if !os(Linux) && !os(Android) && !os(Windows)
    /**
     Logs in a `ParseUser` *asynchronously* using the session token from the Parse Objective-C SDK Keychain.
     Returns an instance of the successfully logged in `ParseUser`. The Parse Objective-C SDK Keychain is not
     modified in any way when calling this method; allowing developers to revert their applications back to the older
     SDK if desired.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: When initializing the Swift SDK, `migratingFromObjcSDK` should be set to **false**
     when calling this method.
     - warning: The latest **PFUser** from the Objective-C SDK should be saved to your
     Parse Server before calling this method.
    */
    public static func loginUsingObjCKeychain(options: API.Options = [],
                                              callbackQueue: DispatchQueue = .main,
                                              completion: @escaping (Result<Self, ParseError>) -> Void) {

        let objcParseKeychain = KeychainStore.objectiveC

        guard let objcParseUser: [String: String] = objcParseKeychain?.objectObjectiveC(forKey: "currentUser"),
            let sessionToken: String = objcParseUser["sessionToken"] ??
                objcParseUser["session_token"] else {
            let error = ParseError(code: .unknownError,
                                   message: "Could not find a session token in the Parse Objective-C SDK Keychain.")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }

        guard let currentUser = Self.current else {
            become(sessionToken: sessionToken,
                   options: options,
                   callbackQueue: callbackQueue,
                   completion: completion)
            return
        }

        guard currentUser.sessionToken == sessionToken else {
            let error = ParseError(code: .unknownError,
                                   message: """
                                   Currently logged in as a ParseUser who has a different
                                   session token than the Objective-C Parse SDK session token. Please log out before
                                   calling this method.
            """)
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        callbackQueue.async {
            completion(.success(currentUser))
        }
    }
#endif

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
        // Always let user logout locally, no matter the error.
        deleteCurrentKeychain()
        // Wait to throw error
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
        logoutCommand().executeAsync(options: options,
                                     callbackQueue: callbackQueue) { result in
            // Always let user logout locally, no matter the error.
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

    internal static func logoutCommand() -> API.Command<NoBody, ParseError?> {
        return API.Command(method: .POST, path: .logout) { (data) -> ParseError? in
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
        passwordResetCommand(email: email).executeAsync(options: options,
                                                        callbackQueue: callbackQueue) { result in
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

    internal static func passwordResetCommand(email: String) -> API.Command<EmailBody, ParseError?> {
        let emailBody = EmailBody(email: email)
        return API.Command(method: .POST,
                           path: .passwordReset, body: emailBody) { (data) -> ParseError? in
            try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
        }
    }
}

// MARK: Verify Password
extension ParseUser {

    /**
     Verifies *asynchronously* whether the specified password associated with the user account is valid.
        - parameter password: The password to be verified.
        - parameter usingPost: Set to **true** to use **POST** for sending. Will use **GET**
        otherwise. Defaults to **false**.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of .main.
        - parameter completion: A block that will be called when the verification request completes or fails.
        - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
        desires a different policy, it should be inserted in `options`.
        - warning: `usingPost == true` requires the
        [issue](https://github.com/parse-community/parse-server/issues/7784) to be addressed on
        the Parse Server, othewise you should set `usingPost = false`.
    */
    public static func verifyPassword(password: String,
                                      usingPost: Bool = false,
                                      options: API.Options = [],
                                      callbackQueue: DispatchQueue = .main,
                                      completion: @escaping (Result<Self, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let username = BaseParseUser.current?.username ?? ""
        let method: API.Method = usingPost ? .POST : .GET
        verifyPasswordCommand(username: username,
                              password: password,
                              method: method)
            .executeAsync(options: options,
                          callbackQueue: callbackQueue,
                          completion: completion)
    }

    internal static func verifyPasswordCommand(username: String,
                                               password: String,
                                               method: API.Method) -> API.Command<SignupLoginBody, Self> {
        let loginBody: SignupLoginBody?
        let params: [String: String]?

        switch method {
        case .GET:
            loginBody = nil
            params = ["username": username, "password": password ]
        default:
            loginBody = SignupLoginBody(username: username, password: password)
            params = nil
        }

        return API.Command(method: method,
                           path: .verifyPassword,
                           params: params,
                           body: loginBody) { (data) -> Self in
            var sessionToken = BaseParseUser.current?.sessionToken ?? ""
            if let decodedSessionToken = try? ParseCoding.jsonDecoder()
                .decode(LoginSignupResponse.self, from: data).sessionToken {
                sessionToken = decodedSessionToken
            }
            let user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)
            Self.currentContainer = .init(currentUser: user,
                                          sessionToken: sessionToken)
            Self.saveCurrentContainerToKeychain()
            return user
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
            .executeAsync(options: options, callbackQueue: callbackQueue) { result in
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

    internal static func verificationEmailCommand(email: String) -> API.Command<EmailBody, ParseError?> {
        let emailBody = EmailBody(email: email)
        return API.Command(method: .POST,
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

     This will also enforce that the username is not already taken.

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

     This will also enforce that the username is not already taken.

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
        if Self.current != nil {
            return try self.linkCommand()
                .execute(options: options)
        } else {
            return try signupCommand().execute(options: options)
        }
    }

    /**
     Signs up the user *asynchronously*.

     This will also enforce that the username is not already taken.

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
        if Self.current != nil {
            do {
                try self.linkCommand()
                    .executeAsync(options: options,
                                  callbackQueue: callbackQueue) { result in
                        completion(result)
                    }
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        } else {
            do {
                try signupCommand()
                    .executeAsync(options: options,
                                  callbackQueue: callbackQueue) { result in
                        completion(result)
                }
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    /**
     Signs up the user *asynchronously*.

     This will also enforce that the username is not already taken.

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
                .executeAsync(options: options,
                              callbackQueue: callbackQueue) { result in
                    completion(result)
                }
        } else {
            do {
                try signupCommand(body: body)
                    .executeAsync(options: options,
                                  callbackQueue: callbackQueue) { result in
                        completion(result)
                }
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    internal static func signupCommand(body: SignupLoginBody) throws -> API.Command<SignupLoginBody, Self> {
        API.Command(method: .POST,
                    path: .users,
                    body: body) { (data) -> Self in

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
            guard let firstUpdatedAt = $0.updatedAt,
                  let secondUpdatedAt = $1.updatedAt else {
                throw ParseError(code: .unknownError,
                                 message: "Objects from the server should always have an \"updatedAt\"")
            }
            return firstUpdatedAt.compare(secondUpdatedAt) == .orderedDescending
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
     Fetches the `ParseUser` *synchronously* with the current data from the server.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
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
            .execute(options: options)
        try Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Fetches the `ParseUser` *asynchronously* and executes the given callback block.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
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
                    if case .success(let foundResult) = result {
                        do {
                            try Self.updateKeychainIfNeeded([foundResult])
                            completion(.success(foundResult))
                        } catch {
                            let defaultError = ParseError(code: .unknownError,
                                                          message: error.localizedDescription)
                            let parseError = error as? ParseError ?? defaultError
                            completion(.failure(parseError))
                        }
                    } else {
                        completion(result)
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
            throw ParseError(code: .missingObjectId,
                             message: "objectId must not be nil")
        }

        var params: [String: String]?
        if let includeParams = include {
            params = ["include": "\(Set(includeParams))"]
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
     Saves the `ParseUser` *synchronously* and throws an error if there is an issue.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - returns: Returns saved `ParseUser`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    @discardableResult
    public func save(options: API.Options = []) throws -> Self {
        try save(ignoringCustomObjectIdConfig: false, options: options)
    }

    /**
     Saves the `ParseUser` *synchronously* and throws an error if there is an issue.

     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - returns: Returns saved `ParseUser`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @discardableResult
    public func save(ignoringCustomObjectIdConfig: Bool,
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

        let result: Self = try saveCommand(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig)
            .execute(options: options,
                     childObjects: childObjects,
                     childFiles: childFiles)
        try Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Saves the `ParseUser` *asynchronously* and executes the given callback block.

     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func save(
        ignoringCustomObjectIdConfig: Bool = false,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.save
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let object = try await command(method: method,
                                               ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                                               options: options,
                                               callbackQueue: callbackQueue)
                completion(.success(object))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        command(method: method,
                ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                options: options,
                callbackQueue: callbackQueue,
                completion: completion)
        #endif
    }

    /**
     Creates the `ParseUser` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func create(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.create
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let object = try await command(method: method,
                                               options: options,
                                               callbackQueue: callbackQueue)
                completion(.success(object))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        command(method: method,
                options: options,
                callbackQueue: callbackQueue,
                completion: completion)
        #endif
    }

    /**
     Replaces the `ParseUser` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object replaced has the same objectId as current, it will automatically replace the current.
    */
    public func replace(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.replace
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let object = try await command(method: method,
                                               options: options,
                                               callbackQueue: callbackQueue)
                completion(.success(object))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        command(method: method,
                options: options,
                callbackQueue: callbackQueue,
                completion: completion)
        #endif
    }

    /**
     Updates the `ParseUser` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object updated has the same objectId as current, it will automatically update the current.
    */
    internal func update(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.update
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let object = try await command(method: method,
                                               options: options,
                                               callbackQueue: callbackQueue)
                completion(.success(object))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        command(method: method,
                options: options,
                callbackQueue: callbackQueue,
                completion: completion)
        #endif
    }

    func command(
        method: Method,
        ignoringCustomObjectIdConfig: Bool = false,
        options: API.Options,
        callbackQueue: DispatchQueue,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        self.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, error) in
            guard let parseError = error else {
                do {
                    let command: API.Command<Self, Self>!
                    switch method {
                    case .save:
                        command = try self.saveCommand(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig)
                    case .create:
                        command = self.createCommand()
                    case .replace:
                        command = try self.replaceCommand()
                    case .update:
                        command = try self.updateCommand()
                    }
                    command
                        .executeAsync(options: options,
                                      callbackQueue: callbackQueue,
                                      childObjects: savedChildObjects,
                                      childFiles: savedChildFiles) { result in
                            if case .success(let foundResult) = result {
                                try? Self.updateKeychainIfNeeded([foundResult])
                            }
                            completion(result)
                    }
                } catch {
                    let defaultError = ParseError(code: .unknownError,
                                                  message: error.localizedDescription)
                    let parseError = error as? ParseError ?? defaultError
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
                return
            }
            callbackQueue.async {
                completion(.failure(parseError))
            }
        }
    }

    func saveCommand(ignoringCustomObjectIdConfig: Bool = false) throws -> API.Command<Self, Self> {
        if Parse.configuration.isRequiringCustomObjectIds && objectId == nil && !ignoringCustomObjectIdConfig {
            throw ParseError(code: .missingObjectId, message: "objectId must not be nil")
        }
        if isSaved {
            return try replaceCommand() // MARK: Should be switched to "updateCommand" when server supports PATCH.
        }
        return createCommand()
    }

    // MARK: Saving ParseObjects - private
    func createCommand() -> API.Command<Self, Self> {
        var object = self
        if object.ACL == nil,
            let acl = try? ParseACL.defaultACL() {
            object.ACL = acl
        }
        let mapper = { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(CreateResponse.self, from: data).apply(to: object)
        }
        return API.Command<Self, Self>(method: .POST,
                                       path: endpoint(.POST),
                                       body: object,
                                       mapper: mapper)
    }

    func replaceCommand() throws -> API.Command<Self, Self> {
        guard self.objectId != nil else {
            throw ParseError(code: .missingObjectId,
                             message: "objectId must not be nil")
        }
        var mutableSelf = self
        if let currentUser = Self.current,
           currentUser.hasSameObjectId(as: mutableSelf) {
            #if !os(Linux) && !os(Android) && !os(Windows)
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
        let mapper = { (data: Data) -> Self in
            var updatedObject = self
            updatedObject.originalData = nil
            updatedObject = try ParseCoding.jsonDecoder().decode(ReplaceResponse.self,
                                                                 from: data).apply(to: updatedObject)
            // MARK: The lines below should be removed when server supports PATCH.
            guard let originalData = self.originalData,
                  let original = try? ParseCoding.jsonDecoder().decode(Self.self,
                                                                       from: originalData),
                  original.hasSameObjectId(as: updatedObject) else {
                      return updatedObject
                  }
            return try updatedObject.merge(with: original)
        }
        return API.Command<Self, Self>(method: .PUT,
                                 path: endpoint,
                                 body: mutableSelf,
                                 mapper: mapper)
    }

    func updateCommand() throws -> API.Command<Self, Self> {
        guard self.objectId != nil else {
            throw ParseError(code: .missingObjectId,
                             message: "objectId must not be nil")
        }
        var mutableSelf = self
        if let currentUser = Self.current,
           currentUser.hasSameObjectId(as: mutableSelf) {
            #if !os(Linux) && !os(Android) && !os(Windows)
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
        let mapper = { (data: Data) -> Self in
            var updatedObject = self
            updatedObject.originalData = nil
            updatedObject = try ParseCoding.jsonDecoder().decode(UpdateResponse.self,
                                                                 from: data).apply(to: updatedObject)
            guard let originalData = self.originalData,
                  let original = try? ParseCoding.jsonDecoder().decode(Self.self,
                                                                       from: originalData),
                  original.hasSameObjectId(as: updatedObject) else {
                      return updatedObject
                  }
            return try updatedObject.merge(with: original)
        }
        return API.Command<Self, Self>(method: .PATCH,
                                 path: endpoint,
                                 body: mutableSelf,
                                 mapper: mapper)
    }
}

// MARK: Deletable
extension ParseUser {
    /**
     Deletes the `ParseUser` *synchronously* with the current data from the server.

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
            try deleteCommand().executeAsync(options: options,
                                             callbackQueue: callbackQueue) { result in
                switch result {

                case .success:
                    try? Self.updateKeychainIfNeeded([self], deleting: true)
                    completion(.success(()))
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
     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a save was successful or a `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func saveAll(batchLimit limit: Int? = nil, // swiftlint:disable:this function_body_length
                 transaction: Bool = configuration.isUsingTransactions,
                 ignoringCustomObjectIdConfig: Bool = false,
                 options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {
        var childObjects = [String: PointerType]()
        var childFiles = [UUID: ParseFile]()
        var error: ParseError?
        var commands = [API.Command<Self.Element, Self.Element>]()
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))

        try forEach {
            let user = $0
            let group = DispatchGroup()
            group.enter()
            user.ensureDeepSave(options: options,
                                // swiftlint:disable:next line_length
                                isShouldReturnIfChildObjectsFound: transaction) { (savedChildObjects, savedChildFiles, parseError) -> Void in
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
            commands.append(try user.saveCommand(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig))
        }

        var returnBatch = [(Result<Self.Element, ParseError>)]()
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
        let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
        try batches.forEach {
            let currentBatch = try API.Command<Self.Element, Self.Element>
                .batch(commands: $0, transaction: transaction)
                .execute(options: options,
                         batching: true,
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
     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func saveAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        transaction: Bool = configuration.isUsingTransactions,
        ignoringCustomObjectIdConfig: Bool = false,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let method = Method.save
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let objects = try await batchCommand(method: method,
                                                     batchLimit: limit,
                                                     transaction: transaction,
                                                     ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                                                     options: options,
                                                     callbackQueue: callbackQueue)
                completion(.success(objects))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        batchCommand(method: method,
                     batchLimit: limit,
                     transaction: transaction,
                     ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                     options: options,
                     callbackQueue: callbackQueue,
                     completion: completion)
        #endif
    }

    /**
     Creates a collection of users all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func createAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        transaction: Bool = configuration.isUsingTransactions,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let method = Method.create
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let objects = try await batchCommand(method: method,
                                                     batchLimit: limit,
                                                     transaction: transaction,
                                                     options: options,
                                                     callbackQueue: callbackQueue)
                completion(.success(objects))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        batchCommand(method: method,
                     batchLimit: limit,
                     transaction: transaction,
                     options: options,
                     callbackQueue: callbackQueue,
                     completion: completion)
        #endif
    }

    /**
     Replaces a collection of users all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - important: If an object replaced has the same objectId as current, it will automatically replace the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func replaceAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        transaction: Bool = configuration.isUsingTransactions,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let method = Method.replace
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let objects = try await batchCommand(method: method,
                                                     batchLimit: limit,
                                                     transaction: transaction,
                                                     options: options,
                                                     callbackQueue: callbackQueue)
                completion(.success(objects))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        batchCommand(method: method,
                     batchLimit: limit,
                     transaction: transaction,
                     options: options,
                     callbackQueue: callbackQueue,
                     completion: completion)
        #endif
    }

    /**
     Updates a collection of users all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - important: If an object updated has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    internal func updateAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        transaction: Bool = configuration.isUsingTransactions,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let method = Method.update
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let objects = try await batchCommand(method: method,
                                                     batchLimit: limit,
                                                     transaction: transaction,
                                                     options: options,
                                                     callbackQueue: callbackQueue)
                completion(.success(objects))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        batchCommand(method: method,
                     batchLimit: limit,
                     transaction: transaction,
                     options: options,
                     callbackQueue: callbackQueue,
                     completion: completion)
        #endif
    }

    internal func batchCommand( // swiftlint:disable:this function_parameter_count
        method: Method,
        batchLimit limit: Int?,
        transaction: Bool,
        ignoringCustomObjectIdConfig: Bool = false,
        options: API.Options,
        callbackQueue: DispatchQueue,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let uuid = UUID()
        let queue = DispatchQueue(label: "com.parse.batch.\(uuid)",
                                  qos: .default,
                                  attributes: .concurrent,
                                  autoreleaseFrequency: .inherit,
                                  target: nil)
        let users = map { $0 }
        queue.sync {
            var childObjects = [String: PointerType]()
            var childFiles = [UUID: ParseFile]()
            var error: ParseError?
            var commands = [API.Command<Self.Element, Self.Element>]()

            for user in users {
                let group = DispatchGroup()
                group.enter()
                user.ensureDeepSave(options: options,
                                    // swiftlint:disable:next line_length
                                    isShouldReturnIfChildObjectsFound: transaction) { (savedChildObjects, savedChildFiles, parseError) -> Void in
                    // If an error occurs, everything should be skipped
                    if let parseError = parseError {
                        error = parseError
                    }
                    savedChildObjects.forEach {(key, value) in
                        guard error == nil else {
                            return
                        }
                        guard childObjects[key] == nil else {
                            error = ParseError(code: .unknownError, message: "circular dependency")
                            return
                        }
                        childObjects[key] = value
                    }
                    savedChildFiles.forEach {(key, value) in
                        guard error == nil else {
                            return
                        }
                        guard childFiles[key] == nil else {
                            error = ParseError(code: .unknownError, message: "circular dependency")
                            return
                        }
                        childFiles[key] = value
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
                do {
                    switch method {
                    case .save:
                        commands.append(
                            try user.saveCommand(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig)
                        )
                    case .create:
                        commands.append(user.createCommand())
                    case .replace:
                        commands.append(try user.replaceCommand())
                    case .update:
                        commands.append(try user.updateCommand())
                    }
                } catch {
                    let defaultError = ParseError(code: .unknownError,
                                                  message: error.localizedDescription)
                    let parseError = error as? ParseError ?? defaultError
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                    return
                }
            }

            do {
                var returnBatch = [(Result<Self.Element, ParseError>)]()
                let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
                try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
                let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
                var completed = 0
                for batch in batches {
                    API.Command<Self.Element, Self.Element>
                            .batch(commands: batch, transaction: transaction)
                            .executeAsync(options: options,
                                          batching: true,
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
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }
    /**
     Fetches a collection of users *synchronously* all at once and throws an error if necessary.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a fetch was successful or a `ParseError` if it failed.
     - throws: An error of `ParseError` type.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - warning: The order in which users are returned are not guarenteed. You should not expect results in
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
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - warning: The order in which users are returned are not guarenteed. You should not expect results in
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
                    try? Self.Element.updateKeychainIfNeeded(fetchedObjects)
                    completion(.success(fetchedObjectsToReturn))
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
                   transaction: Bool = configuration.isUsingTransactions,
                   options: API.Options = []) throws -> [(Result<Void, ParseError>)] {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        var returnBatch = [(Result<Void, ParseError>)]()
        let commands = try map { try $0.deleteCommand() }
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
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
        transaction: Bool = configuration.isUsingTransactions,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Void, ParseError>)], ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        do {
            var returnBatch = [(Result<Void, ParseError>)]()
            let commands = try map({ try $0.deleteCommand() })
            let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
            try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
            let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
            var completed = 0
            for batch in batches {
                API.Command<Self.Element, ParseError?>
                        .batch(commands: batch, transaction: transaction)
                        .executeAsync(options: options,
                                      callbackQueue: callbackQueue) { results in
                    switch results {

                    case .success(let saved):
                        returnBatch.append(contentsOf: saved)
                        if completed == (batches.count - 1) {
                            try? Self.Element.updateKeychainIfNeeded(self.compactMap {$0},
                                                                     deleting: true)
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
            let defaultError = ParseError(code: .unknownError,
                                          message: error.localizedDescription)
            let parseError = error as? ParseError ?? defaultError
            callbackQueue.async {
                completion(.failure(parseError))
            }
        }
    }
} // swiftlint:disable:this file_length
