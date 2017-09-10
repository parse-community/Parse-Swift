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
    public typealias UserTypeCallback = (Result<Self>) -> Void

    static var current: Self? {
        return CurrentUserInfo.currentUser as? Self
    }

    static func login(username: String,
                      password: String,
                      callback: UserTypeCallback? = nil) -> Cancellable {
        return loginCommand(username: username, password: password).execute(options: [], callback)
    }

    static func signup(username: String,
                       password: String,
                       callback: UserTypeCallback? = nil) -> Cancellable {
        return signupCommand(username: username, password: password).execute(options: [], callback)
    }

    static func logout(callback: ((Result<()>) -> Void)?) {
        _ = logoutCommand().execute(options: [], callback)
    }

    func signup(callback: UserTypeCallback? = nil) -> Cancellable {
        return signupCommand().execute(options: [], callback)
    }
}

private extension UserType {
    private static func loginCommand(username: String,
                                     password: String) -> RESTCommand<NoBody, Self> {
        let params = [
            "username": username,
            "password": password
        ]
        return RESTCommand<NoBody, Self>(method: .get,
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
                                      password: String) -> RESTCommand<SignupBody, Self> {
        let body = SignupBody(username: username, password: password)
        return RESTCommand(method: .post, path: .signup, body: body) { (data) -> Self in
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

    private func signupCommand() -> RESTCommand<Self, Self> {
        var user = self
        return RESTCommand(method: .post, path: .signup, body: user) { (data) -> Self in
            let response = try getDecoder().decode(LoginSignupResponse.self, from: data)
            user.updatedAt = response.updatedAt ?? response.createdAt
            user.createdAt = response.createdAt
            // Set the current user
            CurrentUserInfo.currentUser = user
            CurrentUserInfo.currentSessionToken = response.sessionToken
            return user
        }
    }

    private static func logoutCommand() -> RESTCommand<NoBody, Void> {
       return RESTCommand(method: .post, path: .logout) { (_) -> Void in
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
