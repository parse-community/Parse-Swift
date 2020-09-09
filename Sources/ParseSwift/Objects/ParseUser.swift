import Foundation

/**
 The `ParseUser` class is a local representation of a user persisted to the Parse Data.
 This class is a subclass of a `ParseObject`, and retains the same functionality of a `ParseObject`,
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

// MARK: Default Implementations
public extension ParseUser {
    static var className: String {
        return "_User"
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

    /**
     Gets the currently logged in user from disk and returns an instance of it.
     
     - returns: Returns a `ParseUser` that is the currently logged in user. If there is none, returns `nil`.
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
     This also caches the user locally so that calls to `+currentUser` will use the latest logged in user.
    
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter error: The error object to set on error.
    
     - throws: an instance of the `ParseUser` on success.
     If login failed for either wrong password or wrong username, returns `nil`.
    */
    public static func login(username: String,
                             password: String) throws -> Self {
        return try loginCommand(username: username, password: password).execute(options: [])
    }

    /**
     Makes an *asynchronous* request to log in a user with specified credentials.
     Returns an instance of the successfully logged in `ParseUser`.
    
     This also caches the user locally so that calls to `+currentUser` will use the latest logged in user.
     - parameter username: The username of the user.
     - parameter password: The password of the user.
     - parameter completion: The block to execute.
     It should have the following argument signature: `^(ParseUser *user, ParseError *error)`.
    */    public static func login(
        username: String,
        password: String,
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        return loginCommand(username: username, password: password)
            .executeAsync(options: [], callbackQueue: callbackQueue, completion: completion)
    }

    private static func loginCommand(username: String,
                                     password: String) -> API.Command<NoBody, Self> {
        let params = [
            "username": username,
            "password": password
        ]

        return API.Command<NoBody, Self>(method: .GET,
                                         path: .login,
                                         params: params) { (data) -> Self in
            let user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)
            let response = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: data)

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
    *Synchronously* logs out the currently logged in user on disk.
    */
    public static func logout() throws {
        _ = try logoutCommand().execute(options: [])
    }

    /**
     *Asynchronously* logs out the currently logged in user.
     
     This will also remove the session from disk, log out of linked services
     and all future calls to `+currentUser` will return `nil`. This is preferrable to using `-logOut`,
     unless your code is already running from a background thread.
    
     - parameter completion: A block that will be called when logging out completes or fails.
    */
    public static func logout(callbackQueue: DispatchQueue = .main,
                              completion: @escaping (Result<Bool, ParseError>) -> Void) {
        logoutCommand().executeAsync(options: [], callbackQueue: callbackQueue) { result in
            completion(result.map { true })
        }
    }

    private static func logoutCommand() -> API.Command<NoBody, Void> {
       return API.Command(method: .POST, path: .logout) { (_) -> Void in
            currentUserContainer = nil
            try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentUser)
       }
    }
}

// MARK: Signing Up
extension ParseUser {
    public static func signup(username: String,
                              password: String) throws -> Self {
        return try signupCommand(username: username, password: password).execute(options: [])
    }

    /**
     Signs up the user *synchronously*.
    
     This will also enforce that the username isn't already taken.
    
     - warning: Make sure that password and username are set before calling this method.
    
     - parameter error: Error object to set on error.
    
     - returns: Returns whether the sign up was successful.
    */

    public func signup() throws -> Self {
        return try signupCommand().execute(options: [])
    }

    /**
     Signs up the user *asynchronously*.
     
     This will also enforce that the username isn't already taken.
    
     - warning: Make sure that password and username are set before calling this method.
    
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func signup(callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Self, ParseError>) -> Void) {
        return signupCommand().executeAsync(options: [], callbackQueue: callbackQueue, completion: completion)
    }

    public static func signup(
        username: String,
        password: String,
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        return signupCommand(username: username, password: password)
            .executeAsync(options: [], callbackQueue: callbackQueue, completion: completion)
    }

    private static func signupCommand(username: String,
                                      password: String) -> API.Command<SignupBody, Self> {

        let body = SignupBody(username: username, password: password)
        return API.Command(method: .POST, path: .signup, body: body) { (data) -> Self in
            let response = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: data)
            var user = try ParseCoding.jsonDecoder().decode(Self.self, from: data)
            user.username = username
            user.password = password
            user.updatedAt = response.updatedAt ?? response.createdAt

            Self.currentUserContainer = .init(
                currentUser: user,
                sessionToken: response.sessionToken
            )
            Self.saveCurrentContainerToKeychain()
            return user
        }
    }

    private func signupCommand() -> API.Command<Self, Self> {
        var user = self
        return API.Command(method: .POST, path: .signup, body: user) { (data) -> Self in
            let response = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: data)
            user.updatedAt = response.updatedAt ?? response.createdAt
            user.createdAt = response.createdAt

            Self.currentUserContainer = .init(
                currentUser: user,
                sessionToken: response.sessionToken
            )
            Self.saveCurrentContainerToKeychain()
            return user
        }
    }
}

// MARK: LoginSignupResponse
private struct LoginSignupResponse: Codable {
    let createdAt: Date
    let objectId: String
    let sessionToken: String
    var updatedAt: Date?
}

// MARK: SignupBody
private struct SignupBody: Codable {
    let username: String
    let password: String
}
