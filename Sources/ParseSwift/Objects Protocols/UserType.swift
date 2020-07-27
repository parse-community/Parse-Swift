import Foundation

internal struct CurrentUserInfo {
    static var currentUser: Any?
    static var currentSessionToken: String?
}

public protocol UserType: ObjectType {
    var username: String? { get set }
    var email: String? { get set }
    var password: String? { get set }
}

public extension UserType {
    var sessionToken: String? {
        if let currentUser = CurrentUserInfo.currentUser as? Self,
            currentUser.objectId != nil && self.objectId != nil &&
            currentUser.objectId == self.objectId {
            return CurrentUserInfo.currentSessionToken
        }
        return nil
    }

    static var className: String {
        return "_User"
    }
}

public extension UserType {
    static var current: Self? {
        return CurrentUserInfo.currentUser as? Self
    }

    static func login(username: String,
                      password: String) throws -> Self {
        return try loginCommand(username: username, password: password).execute(options: [])
    }

    static func login(username: String,
                      password: String, completion: @escaping (Self?, ParseError?) -> Void) {
        return loginCommand(username: username, password: password).executeAsync(options: [], completion: completion)
    }

    static func signup(username: String,
                       password: String) throws -> Self {
        return try signupCommand(username: username, password: password).execute(options: [])
    }

    static func signup(username: String,
                       password: String, completion: @escaping (Self?, ParseError?) -> Void) {
        return signupCommand(username: username, password: password).executeAsync(options: [], completion: completion)
    }

    static func logout() throws {
        _ = try logoutCommand().execute(options: [])
    }

    func signup() throws -> Self {
        return try signupCommand().execute(options: [])
    }
}

private extension UserType {
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

    private static func logoutCommand() -> API.Command<NoBody, Void> {
       return API.Command(method: .POST, path: .logout) { (_) -> Void in
            CurrentUserInfo.currentUser = nil
            CurrentUserInfo.currentSessionToken = nil
       }
    }
}

public struct SignupBody: Codable {
    let username: String
    let password: String
}

private struct LoginSignupResponse: Codable {
    let createdAt: Date
    let objectId: String
    let sessionToken: String
    var updatedAt: Date?
}
