import Foundation

// MARK: CurrentUserContainer
struct CurrentUserContainer<T: ParseUser>: Codable {
    var currentUser: T?
    var sessionToken: String?
}

// MARK: ParseUser
public protocol ParseUser: ParseObject {
    var username: String? { get set }
    var email: String? { get set }
    var password: String? { get set }
}

// MARK: Default Implementations
public extension ParseUser {
    static var className: String {
        return "_User"
    }
}

// MARK: Current User Support
extension ParseUser {
    static var currentUserContainer: CurrentUserContainer<Self>? {
        get { try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) }
        set { try? KeychainStore.shared.set(newValue, for: ParseStorage.Keys.currentUser) }
    }

    public static var current: Self? {
        get { Self.currentUserContainer?.currentUser }
        set { Self.currentUserContainer?.currentUser = newValue }
    }

    public var sessionToken: String? {
        Self.currentUserContainer?.sessionToken
    }
}

// MARK: Logging In
extension ParseUser {
    public static func login(username: String,
                             password: String) throws -> Self {
        return try loginCommand(username: username, password: password).execute(options: [])
    }

    public static func login(
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
            return user
        }
    }
}

// MARK: Logging Out
extension ParseUser {
    public static func logout() throws {
        _ = try logoutCommand().execute(options: [])
    }

    static func logout(callbackQueue: DispatchQueue = .main, completion: @escaping (Result<Bool, ParseError>) -> Void) {
        logoutCommand().executeAsync(options: [], callbackQueue: callbackQueue) { result in
            completion(result.map { true })
        }
    }

    private static func logoutCommand() -> API.Command<NoBody, Void> {
       return API.Command(method: .POST, path: .logout) { (_) -> Void in
            currentUserContainer = nil
       }
    }
}

// MARK: Signing Up
extension ParseUser {
    public static func signup(username: String,
                              password: String) throws -> Self {
        return try signupCommand(username: username, password: password).execute(options: [])
    }

    public func signup() throws -> Self {
        return try signupCommand().execute(options: [])
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
public struct SignupBody: Codable {
    let username: String
    let password: String
}
