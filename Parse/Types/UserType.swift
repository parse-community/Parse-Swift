import Foundation

private var currentUser: Any?
private var currentSessionToken: String?

public protocol UserType: ObjectType {
    var username: String? { get set }
    var email: String? { get set }
    var password: String? { get set }
}

public extension UserType {
    var sessionToken: String? {
        return currentSessionToken
    }
}

public extension UserType {
    static var current: Self? {
        return currentUser as? Self
    }

    static func login(username: String, password: String) -> RESTCommand<SignupBody, Self> {
        let params = [
            "username": username,
            "password": password
        ]
        return RESTCommand(method: .GET, path: "/login", params: params, mapper: { (data) -> Self in
            let r = try getDecoder().decode(Self.self, from: data)
            currentUser = r
            return r
        })
    }

    static func signup(username: String, password: String) -> RESTCommand<SignupBody, Self> {
        let body = SignupBody(username: username, password: password)
        return RESTCommand(method: .POST, path: "/users", body: body, mapper: { (data) -> Self in
            let r = try JSONDecoder().decode(SignupResponse.self, from: data)
            var user = try getDecoder().decode(Self.self, from: data)
            user.username = username
            user.password = password
            user.updatedAt = r.createdAt
            currentUser = user
            currentSessionToken = r.sessionToken
            return user
        })
    }

    static func logout() -> RESTCommand<NoBody, Void> {
        return RESTCommand(method: .POST, path: "/users/logout", body: nil, mapper: { (data) -> Void in
            currentUser = nil
            currentSessionToken = nil
        })
    }
}

public struct SignupBody: Codable {
    let username: String
    let password: String
}

private struct SignupResponse: Codable {
    let createdAt: Date
    let objectId: String
    let sessionToken: String
}
