import Foundation

// MARK: CurrentUserInfo
internal struct CurrentUserInfo {
    static var currentUser: Any?
    static var currentSessionToken: String?
}

// MARK: ParseUser
public protocol ParseUser: ParseObject {
    var username: String? { get set }
    var email: String? { get set }
    var password: String? { get set }
}

// MARK: Convenience
public extension ParseUser {
    static var className: String {
        return "_User"
    }
    
    static var current: Self? {
        return CurrentUserInfo.currentUser as? Self
    }
    
    var sessionToken: String? {
        if let currentUser = CurrentUserInfo.currentUser as? Self,
            currentUser.objectId != nil && self.objectId != nil &&
            currentUser.objectId == self.objectId {
            return CurrentUserInfo.currentSessionToken
        }

        return nil
    }
}

// MARK: Logging In
extension ParseUser {
    public static func login(username: String,
                      password: String) throws -> Self {
        return try loginCommand(username: username, password: password).execute(options: [])
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
            let user = try getDecoder().decode(Self.self, from: data)
            let response = try getDecoder().decode(LoginSignupResponse.self, from: data)
            CurrentUserInfo.currentUser = user
            CurrentUserInfo.currentSessionToken = response.sessionToken
            return user
        }
    }
}

// MARK: Logging Out
extension ParseUser {
    public static func logout() throws {
        _ = try logoutCommand().execute(options: [])
    }
    
    private static func logoutCommand() -> API.Command<NoBody, Void> {
       return API.Command(method: .POST, path: .logout) { (_) -> Void in
            CurrentUserInfo.currentUser = nil
            CurrentUserInfo.currentSessionToken = nil
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

    private static func signupCommand(username: String,
                                      password: String) -> API.Command<SignupBody, Self> {

        let body = SignupBody(username: username, password: password)
        return API.Command(method: .POST, path: .signup, body: body) { (data) -> Self in
            let response = try getDecoder().decode(LoginSignupResponse.self, from: data)
            var user = try getDecoder().decode(Self.self, from: data)
            user.username = username
            user.password = password
            user.updatedAt = response.updatedAt ?? response.createdAt

            // Set the current user
            CurrentUserInfo.currentUser = user
            CurrentUserInfo.currentSessionToken = response.sessionToken
            return user
        }
    }

    private func signupCommand() -> API.Command<Self, Self> {
        var user = self
        return API.Command(method: .POST, path: .signup, body: user) { (data) -> Self in
            let response = try getDecoder().decode(LoginSignupResponse.self, from: data)
            user.updatedAt = response.updatedAt ?? response.createdAt
            user.createdAt = response.createdAt
            // Set the current user
            CurrentUserInfo.currentUser = user
            CurrentUserInfo.currentSessionToken = response.sessionToken
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
